
--  with Ada.Text_IO;
with Ada.Streams;                  use Ada.Streams;
with Interfaces;                   use Interfaces;

-- with Commands;                     use Commands;
-- with Bot_2_Sim;

package body LCD is


   --  initialize display
   procedure Init is
   begin
      --  open output channel
      null;
      Clear_Screen;
   end Init;


   --  output at the current cursor location
   procedure Put (C : Character) is
      S : constant String := "" & C;
   begin
      Put_Std (S);
   end Put;


   procedure Put (Val : Integer_8) is
      S : constant String := Val'Img;
   begin
      Put_Std (S (2 .. S'Last));
   end Put;


   procedure Put (Val : Integer_16) is
      S : constant String := Val'Img;
   begin
      Put_Std (S (2 .. S'Last));
   end Put;


   procedure Put (Val : Unsigned_8) is
      S : constant String := Val'Img;
   begin
      Put_Std (S (2 .. S'Last));
   end Put;


   procedure Put (Val : Unsigned_16) is
      S : constant String := Val'Img;
   begin
      Put_Std (S (2 .. S'Last));
   end Put;


   --  output at the current cursor location
   procedure Put (S : AVR_String) is
      Data : Stream_Element_Array (1 .. S'Length);
      for Data'Address use S(S'First)'Address;
   begin
      null; --Bot_2_Sim.Tell (CMD_AKT_LCD, SUB_LCD_DATA, 0, 0, Data);
   end Put;


   procedure Put_Std (S : String) is
      Data : Stream_Element_Array (1 .. S'Length);
      for Data'Address use S(S'First)'Address;
   begin
      null; -- Bot_2_Sim.Tell (CMD_AKT_LCD, SUB_LCD_DATA, 0, 0, Data);
   end Put_Std;


   --  output the command code Cmd to the display
   procedure Command (Cmd : Unsigned_8) is
   begin
      -- ignore commands for now
      null;
   end Command;


   --  clear display and move cursor to home position
   procedure Clear_Screen is
   begin
      null; -- Bot_2_Sim.Tell (CMD_AKT_LCD, SUB_LCD_CLEAR, 0, 0);
   end Clear_screen;


   --  move cursor to home position
   procedure Home is
   begin
      GotoXY (1, 1);
   end Home;


   --  move cursor into line Y and before character position X.  Lines
   --  are numbered 1 to 2 (or 1 to 4 on big displays).  The left most
   --  character position is Y = 1.  The right most position is
   --  defined by Lcd.Display.Width;
   procedure GotoXY (X : Char_Position; Y : Line_Position)
   is
   begin
      null; --Bot_2_Sim.Tell (CMD_AKT_LCD, SUB_LCD_CURSOR,
              --        Integer_16 (X - 1), Integer_16 (Y - 1));
   end GotoXY;

end LCD;
