---------------------------------------------------------------------------
-- The AVR-Ada Library is free software;  you can redistribute it and/or --
-- modify it under terms of the  GNU General Public License as published --
-- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
-- option) any later version.  The AVR-Ada Library is distributed in the --
-- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
-- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
-- PURPOSE. See the GNU General Public License for more details.         --
---------------------------------------------------------------------------

--  Title:    Turn on LED when switch is pressed
--  Author:   Peter Fleury <pfleury@gmx.ch> http://jump.to/fleury
--  Date:     December 2002
--  Translation to Ada by Rolf Ebert
--  Date:     April 2005

--  Description:
--  This example demonstrates basic port input/output technique.  If
--  one of the switches on port D is pressed, the corresponding LED on
--  port B is turned on.


with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.MCU;

procedure Hello_LED is

   LED  : Nat8;
   Keys : Nat8;

begin

   MCU.DDRB_Bits := (others => DD_Output);  -- use all pins on port B for output
   MCU.DDRD_Bits := (others => DD_Input);   -- use all pins on port D for input

   MCU.PORTD := 16#FF#;         -- activate internal pull-up
   MCU.PORTB := 16#FF#;         -- set output high -> turn all LEDs off

   loop                     -- loop forever
      Keys := not MCU.PIND; -- read input port with switches (active-low)

      if (Keys and 1) /= 0 then
         LED := 1;
      elsif (Keys and 2) /= 0 then   -- priority encoder: if multiple switches
         LED := 2;                   -- are pressed, only the lowest switch is
      elsif (Keys and 4) /= 0 then   -- recognized.
         LED := 4;
      elsif (Keys and 8) /= 0 then
         LED := 8;
      elsif (Keys and 16#10#) /= 0 then
         LED := 16#10#;
      elsif (Keys and 16#20#) /= 0 then
         LED := 16#20#;
      elsif (Keys and 16#40#) /= 0 then
         LED := 16#40#;
      elsif (Keys and 16#80#) /= 0 then
         LED := 16#80#;
      else
         LED := 0;
      end if;

      if Keys /= 0 then
         MCU.PORTB := not LED;  -- Set corresponding LED if switch pressed
      end if;
   end loop;

end Hello_LED;
