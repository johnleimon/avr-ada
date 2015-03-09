with Ada.Unchecked_Conversion;
with Net.Buffer;                   use Net.Buffer;
with Net.Ethernet;                 use Net.Ethernet;

package Net.IP.UDP is

   -- type UDP_Header is private;

   -- type UDP_Package_Type is private;

   procedure Handle_Incoming_Packet;

   --
   type UDP_Application is access procedure;

   procedure Register (P : Port_Type; App : UDP_Application);
   procedure Remove (P : Port_Type);

private

   type UDP_Header is record
      Src_Port : Port_Type;
      Dst_Port : Port_Type;
      Length   : U16_NBO;
      Sum      : Checksum_Type;
   end record;
   for UDP_Header'Size use 64;
   for UDP_Header'Bit_Order use System.Low_Order_First;
   for UDP_Header use record
      Src_Port    at 0 range   0 ..  15;
      Dst_Port    at 0 range  16 ..  31;
      Length      at 0 range  32 ..  47;
      Sum         at 0 range  48 ..  63;
   end record;


   type UDP_Package_Type is record
      ETH  : Ethernet_Header;
      IP   : IP_Header;
      UDP  : UDP_Header;
   end record;


   type UDP_Ptr_Type is access all UDP_Package_Type;

   function Convert is new Ada.Unchecked_Conversion (Source => Buffer_Ptr_Type,
                                                     Target => UDP_Ptr_Type);

   Pkg : constant UDP_Ptr_Type := Convert (MTU_Ptr);


end Net.IP.UDP;

