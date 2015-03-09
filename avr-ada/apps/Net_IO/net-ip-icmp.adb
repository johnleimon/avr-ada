with Net.Buffer;                   use Net.Buffer;
with Net.Ethernet;                 use Net.Ethernet;
with NIC;

with Debug;

package body Net.IP.ICMP is


   procedure Create_Raw_ICMP_Packet (Dest_IP : IP_Addr_Type)
   is
   begin
      Net.Ethernet.Setup_Header (Pkg.ETH, Dest_IP);
      Pkg.ETH.Typ := Ether_IPv4;

      Pkg.IP.Protocol := IP_Proto_ICMP;
      Net.IP.Setup_Header (Pkg.IP, Dest_IP);

      Pkg.ICMP.Code := 0;
      Pkg.ICMP.Sum  := Zero;
   end Create_Raw_ICMP_Packet;


   procedure Ping (Dest_IP : IP_Addr_Type)
   is
   begin
      Create_Raw_ICMP_Packet (Dest_IP);

      Pkg.ICMP.Id   := (1, 0);
      Pkg.ICMP.Seq  := (1, 0);
      Pkg.ICMP.Typ  := ICMP_Echo_Request;

      NIC.Send_Packet (42, MTU_Buffer);
   end Ping;


   procedure Handle_Incoming_Packet is
      --Pkg_Len : Net.Buffer.Base_Buffer_Range renames Net.Buffer.Used_Len;
      IP_Len : constant Unsigned_16 := NtoH_16 (Pkg.IP.Total_Len);
   begin
      if Pkg.ICMP.Typ = ICMP_Echo_Request then
         -- Debug.Put_Line ("ICMP is Request");

         -- don't touch sequence number, identifier, total length, and data
         Create_Raw_ICMP_Packet (Pkg.IP.Src);
         Pkg.ICMP.Typ  := ICMP_Echo_Reply;

         Pkg.ICMP.Sum := Zero;
         Pkg.ICMP.Sum := Generic_Checksum (Pkg.ICMP'Address, IP_Len - 20);
         -- received packet len - IP header len

         -- Net.Buffer.Put (MTU_Buffer (1..Len));
         NIC.Send_Packet (Base_Buffer_Range (IP_Len + 14), MTU_Buffer);
         -- received IP length + size of ethernet header

      elsif Pkg.ICMP.Typ = ICMP_Echo_Reply then
         -- Debug.Put_Line ("ICMP is Reply");
         -- ??? check if OK
         null;
--           Debug.Put ("PONG from ");
--           Debug.Put (Image (Pkg.IP.Src));
--           Debug.New_Line;
      else
         null;
--           Debug.Put ("ICMP is ");
--           Debug.Put (Unsigned_8 (Pkg.ICMP.Typ), 16);
--           Debug.New_Line;
      end if;
   end Handle_Incoming_Packet;


end Net.IP.ICMP;

