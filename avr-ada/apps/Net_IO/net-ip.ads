with System;
with System.Storage_Elements;
with Ada.Unchecked_Conversion;
with Net.Buffer;                   use Net.Buffer;
with Net.Ethernet;                 use Net.Ethernet;

package Net.IP is

   type Port_Type is private;

   Any_Port    : constant Port_Type;
   No_Port     : constant Port_Type;

   -- TCP ports
   FTP_Port    : constant Port_Type;
   Telnet_Port : constant Port_Type;
   SMTP_Port   : constant Port_Type;
   HTTP_Port   : constant Port_Type;
   Alt_HTTP_Port : constant Port_Type;
   NTP_Port    : constant Port_Type;
   -- UDP ports
   DNS_Port    : constant Port_Type;
   TFTP_Port   : constant Port_Type;
   SNMP_Port   : constant Port_Type;

   -- function Port (P : Unsigned_16) return Port_Type;

   procedure Set_IP_Id (Id : Unsigned_16);
   --  set the initial IP id.


   type IP_Header is private;

--     type IP_Package_Type is private;

--     procedure Setup_Header (Hdr : out IP_Header; Dest_IP : IP_Addr_Type);
   procedure Handle_Incoming_Packet;


private

   type Port_Type is new U16_NBO;
   Any_Port    : constant Port_Type := (0, 0);
   No_Port     : constant Port_Type := (0, 0);
   -- TCP ports
   FTP_Port    : constant Port_Type := (0, 21);
   Telnet_Port : constant Port_Type := (0, 23);
   SMTP_Port   : constant Port_Type := (0, 25);
   HTTP_Port   : constant Port_Type := (0, 80);
   Alt_HTTP_Port : constant Port_Type := HtoN_16 (8080);
   NTP_Port    : constant Port_Type := (0, 123);
   -- UDP ports
   DNS_Port    : constant Port_Type := (0, 53);
   TFTP_Port   : constant Port_Type := (0, 69);
   SNMP_Port   : constant Port_Type := (0, 161);


   type IP_Protocol_Type is new Unsigned_8;
   IP_Proto_IPv4 : constant IP_Protocol_Type :=   0;
   IP_Proto_ICMP : constant IP_Protocol_Type :=   1;
   IP_Proto_TCP  : constant IP_Protocol_Type :=   6;
   IP_Proto_UDP  : constant IP_Protocol_Type :=  17;
   IP_Proto_RAW  : constant IP_Protocol_Type := 255;


   type Version_Type is mod 16;
   type Header_Size_Type is mod 16;

   type Offset_Type is new U16_NBO;

   Reserved_Fragment : constant Offset_Type := (16#80#, 0);
   Dont_Fragment     : constant Offset_Type := (16#40#, 0);
   More_Fragments    : constant Offset_Type := (16#20#, 0);
   Off_Mask          : constant Offset_Type := (16#1F#, 16#FF#);


   type Checksum_Type is new U16_NBO;
   Zero : constant Checksum_Type := (0, 0);

   type IP_Header is record
      Version      : Version_Type;
      Header_Size  : Header_Size_Type;
      TOS          : Unsigned_8;
      Total_Len    : U16_NBO;
      Pkg_Id       : U16_NBO;
      Off          : Offset_Type;
      TTL          : Unsigned_8;
      Protocol     : IP_Protocol_Type;
      Sum          : Checksum_Type;
      Src          : IP_Addr_Type;
      Dst          : IP_Addr_Type;
   end record;
   for IP_Header'Bit_Order use System.Low_Order_First;
   for IP_Header use record
      Version     at 0 range   4 ..   7;
      Header_Size at 0 range   0 ..   3;
      TOS         at 0 range   8 ..  15;
      Total_Len   at 0 range  16 ..  31;
      Pkg_Id      at 0 range  32 ..  47;
      Off         at 0 range  48 ..  63;
      TTL         at 0 range  64 ..  71;
      Protocol    at 0 range  72 ..  79;
      Sum         at 0 range  80 ..  95;
      Src         at 0 range  96 .. 127;
      Dst         at 0 range 128 .. 159;
   end record;
   for IP_Header'Size use 160;


   type IP_Package_Type is record
      ETH : Ethernet_Header;
      IP  : IP_Header;
   end record;


   type IP_Ptr_Type is access all IP_Package_Type;

   function Convert is new Ada.Unchecked_Conversion (Source => Buffer_Ptr_Type,
                                                     Target => IP_Ptr_Type);

   Pkg : constant IP_Ptr_Type := Convert (MTU_Ptr);


   subtype Address is System.Address;
   subtype Storage_Offset is System.Storage_Elements.Storage_Offset;

   --  working code
   function Generic_Checksum (Start : Address;
                              Len   : Unsigned_16;
                              Init  : Unsigned_32 := 0) return Checksum_Type;

   --  new code, algorithm close to uIP, returns Checksum in host byte
   --  order, not network byte order!
   function Checksum (Start : Address;
                      Len   : Storage_Offset;
                      Init  : Unsigned_16 := 0) return Unsigned_16;


   procedure Setup_Header (Hdr : out IP_Header; Dest_IP : IP_Addr_Type);

   --  calculate checksum of the IP header and set the correspondig
   --  field accordingly
   procedure Set_Checksum (Hdr : in out IP_Header);


end Net.IP;

