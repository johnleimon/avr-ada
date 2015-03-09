with NIC;
with Net.Buffer;
#if not Target = "host" then
with AVR.MCU;
#end if;
with Debug;
with Net.Ethernet;
with Net.IP;
with Net.ARP;

package body Net.Process is


   procedure Check_Packet;


   procedure Init
   is
   begin
      NIC.Init;
   end Init;


   procedure C_Eth_Get_Data;
   pragma Import (C, C_Eth_Get_Data, "eth_get_data");

   procedure Get_Data
   is
      use Net.Buffer;
      Len : Net.Buffer.Base_Buffer_Range renames Net.Buffer.Used_Len;
   begin
      -- Debug.Put ("(Get_Data) data_present : ");
      -- Debug.Put (Data_Present);
      -- Debug.New_Line;

      if Data_Present then

         --  sbis 54-32,2
         --  rjmp .L204
         while NIC.Data_Available loop
            Len := NIC.Receive_Packet (Buffer_Size, MTU_Buffer);
            if Len > 4 then
               MTU_Buffer (Len-3) := 0;
               Len := Len - 4;
               Check_Packet;
            end if;
         end loop;
      end if;
      Data_Present := False;
      NIC.Enable_ETH_Interrupt;
   end Get_Data;


   procedure Check_Packet
   is
      use Net.Ethernet;
      Len : Net.Buffer.Base_Buffer_Range renames Net.Buffer.Used_Len;

   begin
      -- Debug.Put_Line ("(Net.Process.Check_Packet)");
      -- Net.Buffer.Put (Net.Buffer.MTU_Buffer (1 .. Len));
      -- Net.Ethernet.Debug_Put (Net.Ethernet.Pkg.ETH);

      --  if it is an IP or an ARP package, analyze it and update ARP table
      Debug.Put ("ETH type: ");
      if Get_Current_Type = Ether_ARP then
         Debug.Put_Line ("ARP");
         Net.ARP.Handle_Incoming_Packet;
      elsif Get_Current_Type = Ether_IPv4 then
         Debug.Put_Line ("IPv4");
         Net.IP.Handle_Incoming_Packet;
      else
         Debug.Put_Line ("?");
         --  ???  we currently handle no other types of ethernet packets
         null;
      end if;

   end Check_Packet;


#if not Target = "host" then
   procedure Handle_ETH_Interrupt;
   pragma Machine_Attribute (Entity         => Handle_ETH_Interrupt,
                             Attribute_Name => "signal");
   pragma Export (C, Handle_ETH_interrupt, AVR.MCU.Sig_INT2_String);


   procedure Handle_ETH_Interrupt
   is
   begin
      Data_Present := True;
      NIC.Disable_ETH_Interrupt;
   end Handle_ETH_Interrupt;
#end if;

end Net.Process;
