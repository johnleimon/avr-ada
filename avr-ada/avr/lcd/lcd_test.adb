with Avr;            use AVR;
with Avr.IO;
with Avr.Mcu;        use Avr.Mcu;

with Lcd;

procedure Lcd_Test is

   procedure Wait_Until_Key_Pressed is
      pragma Inline (Wait_Until_Key_Pressed);
   begin
      IO.Loop_Until_Bit_Is_Clear (PortD, 2);
      IO.Loop_Until_Bit_Is_Set   (PortD, 2);
   end Wait_Until_Key_Pressed;

begin
   IO.Set_IO (DDRD, 16#00#);        -- make all of PortD input
   IO.Set_IO_Bit (PORTD, 2, True);  -- pull up

   Lcd.Init;

   loop
      Lcd.Clear_Screen;
      Lcd.Put('H');
      Lcd.Put('a');
      Lcd.Put('l');
      Lcd.Put('l');
      Lcd.Put('o');
      --  write simple text
      -- Lcd.Put ("Hello World");

      Wait_Until_Key_Pressed;

      Lcd.Clear_Screen;
      Lcd.Put('R');
      Lcd.Put('o');
      Lcd.Put('l');
      Lcd.Put('f');

      Wait_Until_Key_Pressed;
   end loop;
end Lcd_Test;
