with Net.Host;                     use Net.Host;
with NIC;

with Debug;
with Text;

package body Net.ARP is


   Max_Time_To_Live : constant := 60; --  = 10 minutes

   type ARP_Table_Entry_Type is record
      MAC : MAC_Addr_Type;
      IP  : IP_Addr_Type;
      TTL : Unsigned_8 range 0 .. Max_Time_To_Live;
   end record;

   Nil : constant ARP_Table_Entry_Type := ((0, 0, 0, 0, 0, 0), (0, 0, 0, 0), 0);

   subtype ARP_Entry_Index is Base_ARP_Entry_Index range 1 .. Max_ARP_Entries;
   type ARP_Table_Type is array (ARP_Entry_Index) of ARP_Table_Entry_Type;

   ARP_Table : ARP_Table_Type;

   -----------------------------------------------------------------------------


   procedure Init
   is
   begin
      for I in ARP_Table'Range loop
         declare
            E : ARP_Table_Entry_Type renames ARP_Table(I);
         begin
            E := Nil;
         end;
      end loop;
   end Init;


   procedure Setup_ARP_Std_Data
   is
   begin
      Pkg.ETH.Typ         := Ether_ARP;

      Pkg.ARP.HW          := Ethernet_10Mb;
      Pkg.ARP.Protocol    := ARP_Proto_IPv4;
      Pkg.ARP.HW_Len      := 6;
      Pkg.ARP.Proto_Len   := 4;
      Pkg.ARP.Src_IP_Addr := Host.My_IP;
      Pkg.ARP.Src_HW_Addr := Host.My_MAC;
   end Setup_ARP_Std_Data;


   --  send a reply packet
   procedure Handle_Incoming_Packet is
   begin
      --  first check for a request to me
      if Pkg.ARP.HW         = Ethernet_10MB  and then
        Pkg.ARP.Protocol    = ARP_Proto_IPv4 and then
        Pkg.ARP.HW_Len      = 6              and then
        Pkg.ARP.Proto_Len   = 4              and then
        Pkg.ARP.Tgt_IP_Addr = Host.My_IP
      then
         --  add IP and MAC of sending host
         Update_ARP_Table (New_MAC => Pkg.ARP.Src_HW_Addr,
                           New_IP  => Pkg.ARP.Src_IP_Addr);


         if Pkg.ARP.Op = ARP_Request then

            --  create ethernet response packet
            Pkg.ETH.Dst         := Pkg.ETH.Src;
            Pkg.ETH.Src         := Host.My_MAC;

            Setup_ARP_Std_Data;

            Pkg.ARP.Op          := ARP_Reply;
            Pkg.ARP.Tgt_IP_Addr := Pkg.ARP.Src_IP_Addr;
            Pkg.ARP.Tgt_HW_Addr := Pkg.ARP.Src_HW_Addr;

            -- send it
            NIC.Send_Packet (42, Net.Buffer.MTU_Buffer);

         elsif Pkg.ARP.Op = ARP_Reply then
            --  a reply package back to me, no need to analyze further
            null;
         end if;

      end if;
   end Handle_Incoming_Packet;



   procedure Request (Dest_IP : IP_Addr_Type)
   is
      Own_IP_Masked : IP_Addr_Type;
      Dst_IP_Masked : IP_Addr_Type;
      Real_Dest_IP  : IP_Addr_Type;
   begin
      -- determine network
      for I in Dest_IP'Range loop
         Own_IP_Masked (I) := My_IP (I) and Netmask (I);
         Dst_IP_Masked (I) := Dest_IP (I) and Netmask (I);
      end loop;

      if Own_IP_Masked = Dst_IP_Masked then
         -- stay in the network
         Real_Dest_IP := Dest_IP;
      else
         -- we have to route
         Real_Dest_IP := Gateway;
      end if;

      --  setup ethernet header
      Pkg.ETH.Dst         := Broadcast_MAC_Addr;
      Pkg.ETH.Src         := Host.My_MAC;

      Setup_ARP_Std_Data;

      Pkg.ARP.Op          := ARP_Request;

      Pkg.ARP.Tgt_IP_Addr := Dest_IP;
      Pkg.ARP.Tgt_HW_Addr := No_MAC_Addr;

      -- Net.Buffer.Put (Net.Buffer.MTU_Buffer (1..42));

      -- send it
      NIC.Send_Packet (42, Net.Buffer.MTU_Buffer);

   end Request;



   --  add a new entry or update time to live
   procedure Update_ARP_Table (New_MAC : MAC_Addr_Type;
                               New_IP  : IP_Addr_Type)
   is
   begin
      --  see if there is already an entry.  If yes update the time to live
      for I in ARP_Table'Range loop
         if ARP_Table(I).MAC = New_MAC then
            ARP_Table(I).TTL := Max_Time_To_Live;
            return;
         end if;
      end loop;


      --  no exiting entry found, add one
      for I in ARP_Table'Range loop
         if ARP_Table(I).IP = No_IP_Addr then
            ARP_Table(I).MAC := New_MAC;
            ARP_Table(I).IP  := New_IP;
            ARP_Table(I).TTL := Max_Time_To_Live;
            return;
         end if;
      end loop;

      --  no more space left in the table
      declare
         use Debug;
         use Text;
      begin
         Put_P (No_More_Space_P);
         Put_Line ("ARP_Table");
      end;

   end Update_ARP_Table;


   function Index_Of_IP (IP : IP_Addr_Type) return Base_ARP_Entry_Index
   is
   begin
      for I in ARP_Table'Range loop
         if ARP_Table(I).IP = IP then
            return I;
         end if;
      end loop;
      return Not_Found;
   end Index_Of_IP;


   function MAC_Of_Index (I : Base_ARP_Entry_Index) return MAC_Addr_Type
   is
   begin
      if I > 0 then
         return ARP_Table(I).MAC;
      else
         return Broadcast_MAC_Addr;
      end if;
   end MAC_Of_Index;


   function MAC_Of_IP (IP : IP_Addr_Type) return MAC_Addr_Type
   is
   begin
      return MAC_Of_Index (Index_Of_IP (IP));
   end MAC_Of_IP;


   procedure Timed_Flush
   is
   begin
      for I in ARP_Table'Range loop
         declare
            ARP_Entry : ARP_Table_Entry_Type renames ARP_Table (I);
         begin
            if ARP_Entry.IP(1) /= 0 then
               ARP_Entry.TTL := ARP_Entry.TTL + 1;
               if ARP_Entry.TTL = Max_Time_To_Live then
                  ARP_Entry.IP := (0, 0, 0, 0);
               end if;
            end if;
         end;
      end loop;
   end Timed_Flush;


   procedure Debug_Put_ARP_Table
   is
      use Debug; use Text;
   begin
      Put_P (ARP_Table_Heading_P); New_Line;
      Put ("self ");
      Put (Image (My_IP));
      Put_P (Spaces_2_P);
      Put (Image (My_MAC));
      New_Line;
      for I in ARP_Table'Range loop
         if ARP_Table(I).IP /= No_IP_Addr then
            Put_P (Spaces_2_P);
            Put_P (Spaces_2_P);
            Put (' ');
            Put (Image (ARP_Table(I).IP));
            Put_P (Spaces_2_P);
            Put (Image (ARP_Table(I).MAC));
            Put_P (Spaces_2_P);
            New_Line;
         end if;
      end loop;
      New_Line;
   end;

end Net.ARP;

--  0000: 00 22 F9 01 0E FD 00 1A 92 42 84 7C 08 00 45 00  ..".......B.|..E
--  0010: 00 2C 00 05 40 00 80 06 15 57 C0 A8 B2 13 C0 A8  ..,..@....W.....
--  0020: B2 0B 00 17 06 03 00 00 00 00 69 19 60 B7 60 12  ...........i.`.`
--  0030: 00 32 E8 29 00 00 02 04 00 32

