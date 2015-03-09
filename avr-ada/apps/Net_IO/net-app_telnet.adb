with Net.IP.TCP;
with Debug;
with Text;

package body Net.App_Telnet is

   --Ack_Wait : Boolean;


   procedure Init
   is
   begin
      Net.IP.TCP.Register_App (Net.IP.Telnet_Port, Telnetd'Access);
      Debug.Put ("Telnet server started");
      Debug.New_Line;
   end Init;


   procedure Telnetd
   is
      use Debug;
      use Text;
   begin
      Put_P (In_Telnetd_P);
      New_Line;
      Net.IP.TCP.Send ("Telnet Server");
   end Telnetd;


   procedure Send_Data
   is
   begin
      null;
   end Send_Data;


end Net.App_Telnet;
