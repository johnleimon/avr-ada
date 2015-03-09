private with System;

package Net.Ethernet is

   type Ether_Type is private;

   Ether_IPv4 : constant Ether_Type;
   Ether_PUP  : constant Ether_Type;
   Ether_ARP  : constant Ether_Type;
   Ether_IPv6 : constant Ether_Type;

   type Ethernet_Header is record
      Dst : MAC_Addr_Type;
      Src : MAC_Addr_type;
      Typ : Ether_Type;
   end record;



   procedure Setup_Header (ETH     : out Ethernet_Header;
                           Dest_IP : in  IP_Addr_Type);


   function Get_Current_Type return Ether_Type;
   -- procedure Set_Type (T : Ether_Type);

   procedure Debug_Put (ETH : Ethernet_Header);

private

   type Ether_Type is new U16_NBO;

   Ether_IPv4 : constant Ether_Type := (Hi => 16#08#, Lo => 16#00#);
   Ether_PUP  : constant Ether_Type := (Hi => 16#00#, Lo => 16#02#);
   Ether_ARP  : constant Ether_Type := (Hi => 16#08#, Lo => 16#06#);
   Ether_IPv6 : constant Ether_Type := (Hi => 16#86#, Lo => 16#DD#);


   for Ethernet_Header'Size use 112;
   for Ethernet_Header'Bit_Order use System.Low_Order_First;
   for Ethernet_Header use record
      Dst at 0 range 0  ..  47;
      Src at 0 range 48 ..  95;
      Typ at 0 range 96 ..  111;
   end record;

   pragma Inline (Get_Current_Type);

end Net.Ethernet;

