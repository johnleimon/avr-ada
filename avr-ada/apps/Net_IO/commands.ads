with Net;
with Net.ARP;
package Commands is

   procedure Print_ARP_Table renames Net.ARP.Debug_Put_ARP_Table;
   procedure Ping (Dest_IP : Net.IP_Addr_Type);
   procedure Print_Help;

end Commands;
