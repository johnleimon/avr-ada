--  Target(s)...: ATmega169

-- with Interfaces;     use Interfaces;   -- unsigned_8
with LCD_Driver;     use LCD_Driver;   -- scrollmode visible
with Pstr20;
with AVR;            use AVR;

package LCD_Functions is
   --  pragma Preelaborate (LCD_Functions);

   subtype Str is Pstr20.Pstring;

   procedure Clear;
   -- clear the display

   procedure Put (Text : Str; Scroll : Scrollmode := None);
   -- procedure Update_Required(Update : Boolean; Scroll : Scrollmode);
   procedure Put (Digit : LCD_Index; Char : Character);
   -- put a single character at the specified location

   procedure Put (Right_Digit : LCD_Index;
                  Num         : nat8;
                  Base        : nat8 := 10);
   --  Put the number Num in the display right-aligned at the location
   --  Digit.  That means the ones are at Digit, the tens at Digit-1
   --  and the hundreds at Digit-2.  Show in Base 10 per default.  The
   --  only other permitted value is 16 for hex-numbers.  Hexadecimal
   --  number will alway have a leading 0.

   procedure Colon (Show : Boolean);
   --  switch the colons on the LCD

   procedure Flash_Reset;
   --  reset the blinking cycle of a flashing digit

   procedure Set_Contrast (Contrast : Contrast_Level);
   --  set the contrast level

end LCD_Functions;
