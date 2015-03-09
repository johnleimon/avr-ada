
with LCD_Functions;     use Lcd_Functions;
-- with Interfaces;        use Interfaces;
with LCD_Driver;        use Lcd_Driver;
-- with Avr;
with Avr.Interrupts;
use AVR;

procedure Main is
   -- State_Text : constant Avr.AVR_String := "ADA";
   Num : Nat8 := 0;
begin
   -- Program initalization
   LCD_Driver.Init;                 -- initialize the LCD
   -- Enable_Interrupt;
   Interrupts.Sei;

   Text_Buffer(1 .. 13) := "AV,ADA,AVRADA";
   Text_Buffer(14) := ASCII.NUL;
   Text_Buffer(15) := ASCII.NUL;
   Text_Buffer(16) := ASCII.NUL;

--   Special_Character_Status(S1) := True;
--   Special_Character_Status(S10) := True;

   Put (Right_Digit => 7, Num => 213);

   Put (3, 16#A5#, 16);

   LCD_Driver.G_Scroll_Mode := None;
   LCD_Driver.Scroll_Offset := 0;
   LCD_Driver.Colons := False;
   LCd_Driver.Update_Required := True;

   loop
      while LCD_Driver.Update_Required loop null; end loop;
      if Lcd_Timer = Timer_Seed then
         Num := Num + 1;
         Put (7, Num);
         Put (3, Num, 16);
         LCD_Driver.Update_Required := True;

      end if;

      null;
   end loop;
end Main;
