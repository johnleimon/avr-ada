with System;
with Interfaces;                   use Interfaces;
with Ada.Unchecked_Conversion;
with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.Watchdog;
with AVR.Strings.Edit;             use AVR.Strings.Edit;
with AVR.UART_Base_Polled;
with AVR.Programspace;             use AVR.Programspace;

with PM_Str;
with IO;
with OW;

package body Commands is


   procedure Flush is new AVR.Strings.Edit.Flush_Output
     (Put_Raw => AVR.UART_Base_Polled.Put_Raw);


   function Is_Equal (Left : PM_String; Right : Edit_String) return Boolean
   is
      use System;
      Ch : Character;
      PM_Ptr : Programspace.Program_Address;
      Left_Len : constant Unsigned_8 := Unsigned_8(Length(Left));
      function "+" is new Ada.Unchecked_Conversion (Source => Unsigned_8,
                                                    Target => Character);
   begin
      if Left_Len /= Unsigned_8(Length(Right)) then return False; end if;

      PM_Ptr := Programspace.Program_Address(Left);
      for I in First(Right) .. Last(Right) loop
         PM_Ptr := PM_Ptr + 1;
         Ch := +Programspace.Get(PM_Ptr);
         if Ch /= Input_Line(I) then return False; end if;
      end loop;

      return True;
   end Is_Equal;


   procedure Put_Char (C : Character) is
   begin
      AVR.Strings.Edit.Put (C);
   end Put_Char;
   procedure Put is new PM_Str.Generic_Put (Put_Char);


   procedure Show_Doc (Doc : PM_String)
   is
   begin
      if Doc = 0 then return; end if;
      Put (Doc);
      Edit.New_Line; Flush;
   end Show_Doc;


   procedure Parse_Input_And_Trigger_Action (Cmd_List       : Cmd_List_T;
                                             Default_Action : Cmd_Action)
   is
      use AVR.Strings.Edit;
      Cmd : Edit_String;
   begin
      Skip;
      Cmd := Get_Str;

      for I in Cmd_List'Range loop
         if Is_Equal (Cmd_List(I).Id, Cmd) then
            Show_Doc (Cmd_List(I).Doc);
            Cmd_List(I).Action.all;
            return;
         end if;
      end loop;
   end Parse_Input_And_Trigger_Action;


   procedure Show_Commands is
   begin
      for I in Cmd_List'Range loop
         Put (Cmd_List(I).Id);
         Edit.New_Line; Flush;
      end loop;
   end Show_Commands;


   procedure Reset is
      procedure Jump_To_Zero;
      pragma Import (Ada, Jump_To_Zero);
      for Jump_To_Zero'Address use 0;
   begin
      Jump_To_Zero;
   end Reset;


   procedure Wd_Reset is
   begin
      Watchdog.Enable(Watchdog.WDT_64K);
      loop null; end loop;
   end Wd_Reset;


   procedure OW_Parse renames OW.Parse;
   procedure IO_Parse renames IO.Parse;

end Commands;
