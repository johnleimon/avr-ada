with Ada.Unchecked_Conversion;
with Net.Buffer;                   use Net.Buffer;
with Net.Ethernet;                 use Net.Ethernet;

package Net.IP.ICMP is

   -- type ICMP_Header is private;

   -- type ICMP_Package_Type is private;

   --
   --  ethernet communication
   --

   --  analyze receved packet and generate response if necessary
   procedure Handle_Incoming_Packet;

   --  send a request to Dest_IP
   procedure Ping (Dest_IP : IP_Addr_Type);


private
   --  RfC 792


   type ICMP_Message_Type is new Unsigned_8;

   ICMP_Echo_Request : constant ICMP_Message_Type := 8;
   ICMP_Echo_Reply   : constant ICMP_Message_Type := 0;


   type Code_Type is new Unsigned_8;


   type ICMP_Header is record
      Typ  : ICMP_Message_Type;   -- type of ICMP message
      Code : Code_Type;
      Sum  : Checksum_Type;       -- checksum
      Id   : U16_NBO;             -- identifier
      Seq  : U16_NBO;             -- sequence number
   end record;
   for ICMP_Header'Size use 64;
   for ICMP_Header'Bit_Order use System.Low_Order_First;
   for ICMP_Header use record
      Typ  at 0 range  0 ..   7;
      Code at 0 range  8 ..  15;
      Sum  at 0 range 16 ..  31;
      Id   at 0 range 32 ..  47;
      Seq  at 0 range 48 ..  63;
   end record;


   type ICMP_Package_Type is record
      ETH  : Ethernet_Header;
      IP   : IP_Header;
      ICMP : ICMP_Header;
      Data : System.Address;
   end record;


   type ICMP_Ptr_Type is access all ICMP_Package_Type;

   function Convert is new Ada.Unchecked_Conversion (Source => Buffer_Ptr_Type,
                                                     Target => ICMP_Ptr_Type);

   Pkg : constant ICMP_Ptr_Type := Convert (MTU_Ptr);


end Net.IP.ICMP;

