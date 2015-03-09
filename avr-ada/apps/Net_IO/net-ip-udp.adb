with Ada.Unchecked_Conversion;
with Net.Buffer;                   use Net.Buffer;
with Net.Ethernet;                 use Net.Ethernet;

with Debug;
with Text;

package body Net.IP.UDP is


   type UDP_Table_Entry_Type is record
      Port : Port_Type;
      App  : UDP_Application;
   end record;

   Nil : constant UDP_Table_Entry_Type := ((0, 0), null);

   Max_UDP_Entries : constant := 3;
   type Base_UDP_Entry_Index is new Unsigned_8 range 0 .. Max_UDP_Entries;
   subtype UDP_Entry_Index is Base_UDP_Entry_Index range 1 .. Max_UDP_Entries;
   Not_Found : constant Base_UDP_Entry_Index := 0;

   type UDP_Table_Type is array (UDP_Entry_Index) of UDP_Table_Entry_Type;

   UDP_Table : UDP_Table_Type;

   ----------------------------------------------------------------------------

   function Index_Of_Port (Port : Port_Type) return Base_UDP_Entry_Index
   is
   begin
      for I in UDP_Table'Range loop
         if UDP_Table(I).Port = Port then
            return I;
         end if;
      end loop;
      return Not_Found;
   end Index_Of_Port;


   procedure Handle_Incoming_Packet
   is
      P : Port_Type renames Pkg.UDP.Dst_Port;
      I : constant Base_UDP_Entry_Index := Index_Of_Port (P);

      use Debug;  use Text;
   begin
      if I = Not_Found then
         Put_P (No_UDP_App_P);
         Put (NtoH_16 (P));
         New_Line;
         return;
      end if;

      UDP_Table(I).App.all;
   end Handle_Incoming_Packet;


   procedure Register (P : Port_Type; App : UDP_Application)
   is
      I : Base_UDP_Entry_Index;
   begin
      I := Index_Of_Port (P);
      if I /= Not_Found then
         UDP_Table(I).App := App;
         return;
      end if;
      for I in UDP_Table'Range loop
         if UDP_Table(I).Port = No_Port then
            UDP_Table(I).Port := P;
            UDP_Table(I).App  := App;
            return;
         end if;
      end loop;
      Debug.Put_Line ("UDP table full!");
   end Register;


   procedure Remove (P : Port_Type)
   is
      I : constant Base_UDP_Entry_Index := Index_Of_Port (P);
   begin
      if I /= Not_Found then
         UDP_Table(I) := Nil;
      end if;
   end Remove;


end Net.IP.UDP;

