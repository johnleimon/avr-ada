
package Net.Process is

   procedure Init;

   Data_Present : Boolean;
   for Data_Present'Size use 8;
   pragma Volatile (Data_Present);
   pragma Export (C, Data_Present, "ada_data_present");

   Do_Timer_Actions : Boolean;
   pragma Volatile (Do_Timer_Actions);

   procedure Get_Data;


end Net.Process;
