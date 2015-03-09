---------------------------------------------------------------------------
-- The AVR-Ada Library is free software;  you can redistribute it and/or --
-- modify it under terms of the  GNU General Public License as published --
-- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
-- option) any later version.  The AVR-Ada Library is distributed in the --
-- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
-- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
-- PURPOSE. See the GNU General Public License for more details.         --
--                                                                       --
-- As a special exception, if other files instantiate generics from this --
-- unit,  or  you  link  this  unit  with  other  files  to  produce  an --
-- executable   this  unit  does  not  by  itself  cause  the  resulting --
-- executable to  be  covered by the  GNU General  Public License.  This --
-- exception does  not  however  invalidate  any  other reasons why  the --
-- executable file might be covered by the GNU Public License.           --
---------------------------------------------------------------------------

with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.Strings;                  use AVR.Strings;

package LCD is
   pragma Preelaborate;


   package Display is
      Width : constant := 16;  -- max number of characters in a line
      Height : constant := 2;  -- number of lines
   end Display;

   type Line_Position is new Unsigned_8 range 1 .. Display.Height;
   type Char_Position is new Unsigned_8 range 1 .. Display.Width;

   type Command_Type is new Unsigned_8;


   procedure Init;
   --  initialize display

   procedure Put (C : Character);
   procedure Put (S : AVR_String);
   --  output at the current cursor location

   procedure Command (Cmd : Command_Type);
   --  output the command code Cmd to the display

   procedure Clear_Screen;
   --  clear display and move cursor to home position

   procedure Home;
   --  move cursor to home position

   procedure GotoXY (X : Char_Position; Y : Line_Position);
   --  move cursor into line Y and before character position X.  Lines
   --  are numbered 1 to 2 (or 1 to 4 on big displays).  The left most
   --  character position is Y = 1.  The right most position is
   --  defined by Display.Width;


   package Commands is
      Clear                   : constant Command_Type := 16#01#;
      Home                    : constant Command_Type := 16#02#;

      --  interface data width and number of lines
      Mode_4bit_1line         : constant Command_Type := 16#20#;
      Mode_4bit_2line         : constant Command_Type := 16#28#;
      Mode_8bit_1line         : constant Command_Type := 16#30#;
      Mode_8bit_2line         : constant Command_Type := 16#38#;

      --  display on/off, cursor on/off, blinking char at cursor position
      Display_Off             : constant Command_Type := 16#08#;
      Display_On              : constant Command_Type := 16#0C#;
      Display_On_Blink        : constant Command_Type := 16#0D#;
      Display_On_Cursor       : constant Command_Type := 16#0E#;
      Display_On_Cursor_Blink : constant Command_Type := 16#0F#;

      --  entry mode
      Entry_Inc               : constant Command_Type := 16#06#;
      Entry_Dec               : constant Command_Type := 16#04#;
      Entry_Shift_Inc         : constant Command_Type := 16#07#;
      Entry_Shift_Dec         : constant Command_Type := 16#05#;

      --  cursor/shift display
      Move_Cursor_Left        : constant Command_Type := 16#10#;
      Move_Cursor_Right       : constant Command_Type := 16#14#;
      Move_Display_Left       : constant Command_Type := 16#18#;
      Move_Display_Right      : constant Command_Type := 16#1C#;
   end Commands;

private
   pragma Inline (Command);

end LCD;
