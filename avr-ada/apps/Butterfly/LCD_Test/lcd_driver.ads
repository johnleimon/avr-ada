--
--  Target(s)...: ATmega169
--
with System;
with AVR;
with AVR.Strings;      use AVR.Strings;


package LCD_Driver is


   Register_Count   : constant :=     20;

   subtype Register_Range is AVR.Nat8 range 1 .. Register_Count;
   subtype Register_Array is AVR.Nat8_Array (Register_Range);


   Lcdreg_Address : constant System.Address := 16#EC#;
   LCD_Registers : Register_Array;
   -- direct access to the real segment registers
   for Lcd_Registers'Address use Lcdreg_Address;

   LCD_Data : Register_Array;
   -- LCD display buffer (for double buffering).


   Update_Required : Boolean := False;
   -- Used to indicate when the LCD interrupt handler should update the LCD
   pragma Volatile (Update_Required);


   type Scrollmode is range 0 .. 3;
   for Scrollmode'Size use 8;
   None : constant Scrollmode := 0;
   Once : constant Scrollmode := 1;
   Cycle : constant Scrollmode := 2;
   Wave  : constant Scrollmode := 3;

   G_Scroll_Mode : Scrollmode := None;
   pragma Volatile (G_Scroll_Mode);
   Scroll_Offset : AVR.Nat8;
   pragma Volatile (Scroll_Offset);
   --  Only six letters can be shown on the LCD.  With the
   --  Scroll_Offset and gScrollMode variables, one can select which
   --  part of the buffer to show.  Scroll_Offset is an offset to the
   --  textbuffer, where display starts.

   Timer_Seed         : constant   := 8;

   LCD_Timer : AVR.Nat8 := Timer_Seed;
   pragma Volatile (LCD_Timer);
   Start_Scroll_Timer : AVR.Nat8 := 0;
   -- Start-up delay before scrolling a string over the LCD

   Flash_Seed  : constant   := 10; -- period of character flashing
   Flash_Timer : AVR.Nat8 := 0;
   --  The Flash_Timer is used to determine the on/off timing of
   --  flashing characters

   --
   --  elements for display
   --
   subtype LCD_Character is Character range '*' .. '_';
   --  characters that can be sent to the display.  This does not
   --  include lowercase characters!

   Textbuffer_Size  : constant := 25;
   subtype Textbuffer_Range is AVR.Nat8 range 1 .. Textbuffer_Size;
   Text_Buffer : AVR_String (Textbuffer_Range);
   -- Buffer that contains the text to be displayed
   -- Note: Bit 7 indicates that this character is flashing

   Colons : Boolean;
   -- Turns on/off both colons on the LCD, e.g. for HH:MM:SS display

   type Special_Characters is (N1, N2, N3, N4, N5, N7, N8, N9, N10,
                               S1, S2, S3, S4, S5, S7, S8, S9, S10);

   type Special_Char_Array is array (Special_Characters) of Boolean;
   pragma Pack (Special_Char_Array);
   for Special_Char_Array'Size use 24;

   Special_Character_Status : Special_Char_Array := (others => False);

   subtype LCD_Index is AVR.Nat8 range 2 .. 7;
   --  positions in the LCD, the left-most is 2, the right-most
   --  position is 7.

   procedure Init;
   --  initialize the registers and timing

   procedure All_Segments (Show : Boolean);
   --    show or hide all LCD segments on the LCD


   --
   -- Contrast
   --

   type Contrast_Level is range 0 .. 16#0F#;
   for Contrast_Level'Size use 8;
   --  15 (16#0F#) is the highest contrast level.

   Initial_Contrast : constant Contrast_Level := 16#0F#; -- full contrast

   procedure Set_Contrast_Level (Level : Contrast_Level);
   pragma Inline (Set_Contrast_Level);

end LCD_Driver;
