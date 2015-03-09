
with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;

package LCD is
   --  pragma Preelaborate (LCD);


   package Display is
      Width : constant := 16;  -- max number of characters in a line
      Height : constant := 2;  -- number of lines
   end Display;

   type Line_Position is new Unsigned_8 range 1 .. Display.Height;
   type Char_Position is new Unsigned_8 range 1 .. Display.Width;

   --  initialize display
   procedure Init;

   --  output at the current cursor location
   procedure Put (C : Character);
   procedure Put (S : AVR_String);
   procedure Put_Std (S : String);
   procedure Put (Val : Integer_8);
   procedure Put (Val : Integer_16);
   procedure Put (Val : Unsigned_8);
   procedure Put (Val : Unsigned_16);

   --  output the command code Cmd to the display
   procedure Command (Cmd : Unsigned_8);

   --  clear display and move cursor to home position
   procedure Clear_Screen;

   --  move cursor to home position
   procedure Home;

   --  move cursor into line Y and before character position X.  Lines
   --  are numbered 1 to 2 (or 1 to 4 on big displays).  The left most
   --  character position is X = 1.  The right most position is
   --  defined by Display.Width;
   procedure GotoXY (X : Char_Position; Y : Line_Position);


   package Commands is
      Clear                   : constant := 16#01#;
      Home                    : constant := 16#02#;

      --  interface data width and number of lines
      Mode_4bit_1line         : constant := 16#20#;
      Mode_4bit_2line         : constant := 16#28#;
      Mode_8bit_1line         : constant := 16#30#;
      Mode_8bit_2line         : constant := 16#38#;

      --  display on/off, cursor on/off, blinking char at cursor position
      Display_Off             : constant := 16#08#;
      Display_On              : constant := 16#0C#;
      Display_On_Blink        : constant := 16#0D#;
      Display_On_Cursor       : constant := 16#0E#;
      Display_On_Cursor_Blink : constant := 16#0F#;

      --  entry mode
      Entry_Inc               : constant := 16#06#;
      Entry_Dec               : constant := 16#04#;
      Entry_Shift_Inc         : constant := 16#07#;
      Entry_Shift_Dec         : constant := 16#05#;

      --  cursor/shift display
      Move_Cursor_Left        : constant := 16#10#;
      Move_Cursor_Right       : constant := 16#14#;
      Move_Display_Left       : constant := 16#18#;
      Move_Display_Right      : constant := 16#1C#;
   end Commands;

end LCD;
