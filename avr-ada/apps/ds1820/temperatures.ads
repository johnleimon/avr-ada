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

--  This package provides some fixed point temperature types as they
--  are used in the 1-wire sensors DS18S20 and DS18B20.
with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;

package Temperatures is
   pragma Pure;

   --  the 9 bit std resolution of the DS18S20, 8 binary bits integer
   --  part (I) and 1 binary bit fractional part (F).  All leading
   --  bits are either zero for positive values or 1 for negative
   --  values (sign, S).
   --  index: 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
   --  type:   S   S   S   S   S   S   S   I   I   I   I   I   I   I   I   F
   --  power:  S   S   S   S   S   S   S   7   6   5   4   3   2   1   0  -1
   type Temperature_9bit is delta 0.5 range -55.0 .. 125.0;
   for Temperature_9bit'Size use 16;


   --  the 12 bit resolution of the DS18B20, 8 bits integer part, 4 bits
   --  fractional part.
   --  index: 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
   --  type:   S   S   S   S   I   I   I   I   I   I   I   I   F   F   F   F
   --  power:  S   S   S   S   7   6   5   4   3   2   1   0  -1  -2  -3  -4
   type Temperature_12bit is delta 0.0625 range -55.0 .. 125.0;
   for Temperature_12bit'Size use 16;


   --  convert a 16bit raw reading to a temperature
   function To_Temperature_9bit (Raw : Unsigned_16) return Temperature_9bit;
   function To_Temperature_12bit (Raw : Unsigned_16) return Temperature_12bit;


   --  the Image function returns a string containing the right
   --  aligned textual representation of the temperature.  There is
   --  always one decimal digit after the point, whose only values are
   --  '0' or '5'.
   --  Examples: "125.0", " -3.5", "  1.0", "-55.0"
   function Image (Value : Temperature_9bit) return AStr5;

   --  return the textual representation with one decimal digit, rounded.
   function Image (Value : Temperature_12bit) return AStr5;

   --  return the textual representation with all four decimal digits.
   function Image_Full (Value : Temperature_12bit) return AStr8;

end Temperatures;
