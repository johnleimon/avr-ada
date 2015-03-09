with Net.ARP;
with Net.Host;
with Net.Buffer;
with Debug;

package body Net.Ethernet is


   E : Ethernet_Header;
   for E'Address use Net.Buffer.MTU_Buffer'Address;


   procedure Setup_Header (ETH     : out Ethernet_Header;
                           Dest_IP : in  IP_Addr_Type)
   is
   begin
      ETH.Dst := Net.ARP.MAC_Of_IP (Dest_IP);
      ETH.Src := Net.Host.My_MAC;
   end Setup_Header;


   function Get_Current_Type return Ether_Type
   is
   begin
      return E.Typ;
   end Get_Current_Type;





   procedure Debug_Put (ETH : Ethernet_Header)
   is
      use Debug;
   begin
      Put ("ETH.Src: ");
      Put (Image (Eth.Src));
      New_Line;
      Put ("ETH.Dst: ");
      Put (Image (Eth.Dst));
      New_Line;
      Put ("ETH.Proto: ");
      if ETH.Typ = Ether_IPv4 then
         Put ("IPv4");
      elsif ETH.Typ = Ether_ARP then
         Put ("ARP");
      else
         Put ("???");
      end if;
      New_Line;
   end Debug_Put;

end Net.Ethernet;

