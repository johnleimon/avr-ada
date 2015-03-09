with AVR.Strings;
with Debug;
with Net.ARP;
with Net.IP.ICMP;

package body Commands is


   use AVR.Strings;
   H1 : AVR_String := "h[elp]    - print this text";
   H2 : AVR_String := "a[rp]     - print ARP table";
   H3 : AVR_String := "p[ing] aaa.bbb.ccc.ddd";
#if not Target = "host" then
   pragma Linker_Section (H1, ".progmem");
   pragma Linker_Section (H2, ".progmem");
   pragma Linker_Section (H3, ".progmem");
#end if;

   procedure Print_Help is
      use Debug;
   begin
#if not Target = "host" then
      Put (H1'Length, H1'Address);      New_Line;
      Put (H2'Length, H2'Address);      New_Line;
      Put (H3'Length, H3'Address);      New_Line;
#end if;
      Put (H1);      New_Line;
      Put (H2);      New_Line;
      Put (H3);      New_Line;
      New_Line;
   end Print_Help;


   procedure Ping (Dest_IP : Net.IP_Addr_Type)
   is
   begin
      -- Net.ARP.Request (Dest_IP);
      Net.IP.ICMP.Ping (Dest_IP);
   end Ping;

end Commands;
