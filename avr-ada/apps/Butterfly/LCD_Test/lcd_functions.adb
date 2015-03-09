--
--  Target(s)...: ATmega169

-- with Avr; -- io
-- with <avr/pgmspace.h>
with Lcd_Driver;   use Lcd_Driver;
--with "BCD.h"
-- with Interfaces;     use Interfaces;
with Avr;            use Avr;
--with Ada.Unchecked_Conversion;

package body LCD_Functions is


--     function To_Unsigned_8 is new Ada.Unchecked_Conversion
--       (Source => Character, Target => Unsigned_8);

--*************************************************************************
--
--    Function name : LCD_puts_f
--
--    Parameters :    pFlashStr: Pointer to the string in flash
--                scrollmode: Not in use
--
--   Writes a string stored in flash to the LCD
--
--*************************************************************************/

--  procedure LCD_puts_f(const char *pFlashStr, char scrollmode)
--      -- char i;
--          uint8_t i;
--  begin
--     while (gLCD_Update_Required) loop null; end loop;
--     -- Wait for access to buffer

--      -- mt: for (i = 0; pFlashStr[i] && i < TEXTBUFFER_SIZE; i++)
--          for (i = 0; pgm_read_byte(&pFlashStr[i]) && i < TEXTBUFFER_SIZE; i++)
--      {
--          -- mt: gTextBuffer[i] = pFlashStr[i];
--                  gTextBuffer[i] = pgm_read_byte(&pFlashStr[i]);
--      }

--      gTextBuffer[i] = '\0';

--      if (i > 6) then
--          G_Scroll_Mode := Once;        -- Scroll if text is longer than display size
--          G_Scroll := 0;
--          G_LCD_Start_Scroll_Timer := 3;    --Start-up delay before scrolling the text
--      else
--          G_Scroll_Mode := 0;
--          G_Scroll := 0;
--      end if;

--      gLCD_Update_Required := 1;
--  end Put;


   --************************************************************************
   --
   --   Parameters :    pStr: Pointer to the string
   --               scrollmode: Not in use
   --
   --   Writes a string to the LCD
   --
   --************************************************************************/
   procedure Put (Text : Str; Scroll : Scrollmode := None) is
      use Pstr20;
      pragma Unreferenced (Scroll);
      L : constant Nat8 := Length(Text);
   begin
      -- Wait for access to buffer
      while Update_Required loop null; end loop;

      for J in 1..L loop
         LCD_Driver.Text_Buffer(J) := Element(Text, J);
      end loop;

      Text_Buffer(L+1) := ASCII.NUL;

      if L > 5 then
         G_Scroll_Mode := Once;   -- Scroll if text is longer than display size
         Scroll_Offset := 0;
         Start_Scroll_Timer := 3; -- Start-up delay before scrolling the text
      else
         G_Scroll_Mode := None;
         Scroll_Offset := 0;
      end if;

      LCD_Driver.Update_Required := True;
   end Put;


   --*************************************************************************
   --
   --    Parameters :    digit: Which digit to write on the LCD
   --                char : Character to write
   --
   --     Writes a character to the LCD
   --
   --*************************************************************************/
   procedure Put (Digit : LCD_Index; Char : Character) is
   begin
      Text_Buffer(Digit) := Char;
   end Put;


   procedure Put (Right_Digit : LCD_Index;
                  Num         : Nat8;
                  Base        : Nat8 := 10)
   is
      N : Nat8 := Num;-- starts with Num, eventually becomes ones
      H : Nat8 := 0;  -- hundreds
      T : Nat8 := 0;  -- tens / sixteens
      L : LCD_Driver.Textbuffer_Range := Right_Digit - 1;
   begin
      if Base /= 16 then
         while N >= 100 loop
            H := H + 1;
            N := N - 100;
         end loop;

         while N >= 10 loop
            T := T + 1;
            N := N - 10;
         end loop;


         LCD_Driver.Text_Buffer(L) := Character'Val (N+48);
         L := L-1;

         if H > 0 then
            LCD_Driver.Text_Buffer(L) := Character'Val (T+48);
            L := L-1;
            LCD_Driver.Text_Buffer(L) := Character'Val (H+48);
         else
            if T > 0 then
               LCD_Driver.Text_Buffer(L) := Character'Val (T+48);
            else
               LCD_Driver.Text_Buffer(L) := ' ';
            end if;
            L := L-1;
            LCD_Driver.Text_Buffer(L) := ' ';
         end if;

      else
         -- hexadecimal, always show both nibbles
         T := Shift_Right (N, 4);
         N := N and 16#0F#;
         if N < 10 then
            LCD_Driver.Text_Buffer(L) := Character'Val (N+48);
         else
            LCD_Driver.Text_Buffer(L) := Character'Val (N+55);
         end if;

         L := L-1;

         if T < 10 then
            LCD_Driver.Text_Buffer(L) := Character'Val (T+48);
         else
            LCD_Driver.Text_Buffer(L) := Character'Val (T+55);
         end if;

      end if;
   end Put;


   --*************************************************************************
   --
   --               Clear the LCD
   --
   --*************************************************************************/
   procedure Clear is
   begin
      Text_Buffer := (others => ' ');
   end Clear;


   --************************************************************************
   --
   --     Parameters :    show: Enables the colons if TRUE, disable if FALSE
   --
   --     Purpose :               Enable/disable colons on the LCD
   --
   --************************************************************************/
   procedure Colon(Show : boolean) is
   begin
      LCD_Driver.Colons := Show;
   end Colon;


   --  This function resets the blinking cycle of a flashing digit
   procedure Flash_Reset is
   begin
      LCD_Driver.Flash_Timer := 0;
      null;
   end Flash_Reset;



   procedure Set_Contrast (Contrast : Contrast_level)
     renames Lcd_Driver.Set_Contrast_Level;

   --**************************************************************************
   --
   --     Function name : SetContrast
   --
   --     Returns :       char ST_state (to the state-machine)
   --
   --     Parameters :    char input (from joystick)
   --
   --     Purpose :               Adjust the LCD contrast
   --
   --************************************************************************

  -- char CONTRAST = LCD_INITIAL_CONTRAST;


   --  char SetContrast(char input)
   --  {
   --      static char enter = 1;
   --      char CH, CL;

   --      if (enter)
   --      {
   --          LCD_Clear();
   --          enter = 0;
   --      }

   --      CH = CHAR2BCD2(CONTRAST);
   --      CL = (CH & 0x0F) + '0';
   --      CH = (CH >> 4) + '0';

   --      LCD_putc(0, 'C');
   --      LCD_putc(1, 'T');
   --      LCD_putc(2, 'R');
   --      LCD_putc(3, ' ');
   --      LCD_putc(4, CH);
   --      LCD_putc(5, CL);

   --      LCD_UpdateRequired(TRUE, 0);

   --      if (input == KEY_PLUS)
   --          CONTRAST++;
   --      else if (input == KEY_MINUS)
   --          CONTRAST--;

   --      if (CONTRAST == 255)
   --          CONTRAST = 0;
   --      if (CONTRAST > 15)
   --          CONTRAST = 15;

   --      LCD_CONTRAST_LEVEL(CONTRAST);


   --      if (input == KEY_ENTER)
   --      {
   --          enter = 1;
   --          return ST_OPTIONS_DISPLAY_CONTRAST;
   --      }

   --      return ST_OPTIONS_DISPLAY_CONTRAST_FUNC;
   --  }

end Lcd_Functions;
