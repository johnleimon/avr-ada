--
--  The RC switch can be in one of three modes.
--
--  Typically mode 0 is all off, mode 1 is on.
--
--  Some transmitters have a three position switch and the third
--  position is mode 2. Mode 2 is often connected to a second device
--  or applies a different blink pattern to an attached LED.

with AVR;                          use AVR;
with Pins;

package body Modes is

   procedure LED_Blue_Off;
   procedure LED_White_Off;
   procedure LED_White_Flash_Off;


   Prev_Mode : Mode_T;

   On_Exit_Activity : Mode_Activity;

   procedure LED_Blue_On is
      use Pins;
   begin
      On_Exit_Activity := LED_Blue_Off'Access;
      Blue_Pin := High;
   end LED_Blue_On;

   procedure LED_White_On is
      use Pins;
   begin
      On_Exit_Activity := LED_White_Off'Access;
      White_Pin := High;
   end LED_White_On;

   procedure LED_White_Flash is
      use Pins;
   begin
      On_Exit_Activity := LED_White_Flash_Off'Access;
      White_Pin := High;
   end LED_White_Flash;

   procedure LED_Blue_Off is
      use Pins;
   begin
      Blue_Pin := Low;
   end LED_Blue_Off;

   procedure LED_White_Off is
      use Pins;
   begin
      White_Pin := Low;
   end LED_White_Off;

   procedure LED_White_Flash_Off is
      use Pins;
   begin
      -- Flash_Cycle := 0;
      White_Pin := Low;
   end LED_White_Flash_Off;


   procedure Manage_Mode is
   begin
      if Mode = Prev_Mode then
         -- no change, do nothing
         null;
      else
         -- leave previous mode
         if On_Exit_Activity /= null then
            On_Exit_Activity.all;
            On_Exit_Activity := null;
         end if;
         -- enter new mode
         case Mode is
         when 0 =>
            if Mode_0_Activity /= null then Mode_0_Activity.all; end if;
         when 1 =>
            if Mode_1_Activity /= null then Mode_1_Activity.all; end if;
         when 2 =>
            if Mode_2_Activity /= null then Mode_2_Activity.all; end if;
         end case;

         Prev_Mode := Mode;
      end if;
   end Manage_Mode;


   procedure Init is
   begin
      Mode := 0;
      Prev_Mode := 0;
      LED_Blue_Off;
      LED_White_Off;
      LED_White_Flash_Off;
   end Init;

begin
   Init;
end Modes;
