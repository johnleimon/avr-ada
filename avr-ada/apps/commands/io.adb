with System;
with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.Strings;
with AVR.Strings.Edit;             use AVR.Strings.Edit;
with AVR.Strings.Edit.Integers;
with AVR.UART_Base_Polled;
with Commands;                     use Commands;
--  with AVR.Int_Img;
--  with System.Int_Img;

package body IO is


   procedure Flush is new AVR.Strings.Edit.Flush_Output
     (Put_Raw => AVR.UART_Base_Polled.Put_Raw);


   procedure Parse is
   begin
      Commands.Parse_Input_And_Trigger_Action (IO_Cmds, IO_Default);
   end Parse;


   procedure IO_Get
   is
      Addr : Unsigned_16;
   begin
      Skip;
      Integers.Get (Addr, 16);
      Integers.Put (Addr, 16, Field => 4, Justify => Right, Fill => '0');
      Put(": ");
      declare
         Cell_Orig : Unsigned_8;
         for Cell_Orig'Address use System.Address(Addr);
         Cell : constant Unsigned_8 := Cell_Orig;
      begin
         Integers.Put (Cell, 16, Field => 2, Justify => Right, Fill => '0');
         --  Put (' ');
         --  Integers.Put (Cell, 2, Field => 8, Justify => Right, Fill => '0');
         --  Put (' ');
         --  Put ('<');
         --  for I in reverse Bit_Number loop
         --     Mask := Interfaces.Shift_Left (Unsigned_8'(1), Natural(I));
         --     if (Cell and Mask) /= 0 then
         --        Put('1');
         --     else
         --        Put('0');
         --     end if;
         --  end loop;
         --  Put('>');
      end;
      New_Line; Flush;
   end IO_Get;


   procedure Dump
   is
      Addr : Unsigned_16;
   begin
      Skip;
      Integers.Get (Addr, 16);
      Integers.Put (Addr, 16, Field => 4, Justify => Right, Fill => '0');
      Put (':');
      for I in 1 .. 16 loop
         declare
            Cell_Orig : Unsigned_8;
            for Cell_Orig'Address use System.Address(Addr);
            Cell : constant Unsigned_8 := Cell_Orig;
         begin
            Put(' ');
            Integers.Put(Cell, 16, Field => 2, Justify => Right, Fill => '0');
            --  Put ('<'); U8_Hex_Img (Cell, Img); Put(Img); Put('>');
            --  Put (' ');
            --  Integers.Put (Cell, 2, Field => 8, Justify => Right, Fill => '0');
            --  Put (' ');
            --  Put ('<');
            --  for I in reverse Bit_Number loop
            --     Mask := Interfaces.Shift_Left (Unsigned_8'(1), Natural(I));
            --     if (Cell and Mask) /= 0 then
            --        Put('1');
            --     else
            --        Put('0');
            --     end if;
            --  end loop;
            --  Put('>');
         end;
         Addr := Addr + 1;
      end loop;
      Edit.New_Line; Flush;
   end Dump;


   procedure IO_Set
   is
      Addr : Unsigned_16;
      Val  : Unsigned_8;
   begin
      Skip;
      Integers.Get (Addr, 16);
      Skip;
      Integers.Get (Val, 16);

      declare
         Cell : Unsigned_8;
         for Cell'Address use System.Address(Addr);
      begin
         Cell := Val;
         null;
      end;
   end IO_Set;


   procedure Show_IO_Commands
   is
      procedure Put_Char (C : Character) is
      begin
         AVR.Strings.Edit.Put (C);
      end Put_Char;
      procedure Put is new PM_Str.Generic_Put (Put_Char);
   begin
      for I in IO_Cmds'Range loop
         Put (IO_Cmds(I).Id);
         Edit.New_Line; Flush;
      end loop;
   end Show_IO_Commands;

end IO;
