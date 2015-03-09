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

with AVR.Strings;                  use AVR.Strings;

package SHT.Images is
   pragma Pure;

   --  return the textual representation with one decimal digit, rounded.
   function Image (Value : Temperature_SHT) return AStr5;

   --  return the textual representation with all four decimal digits.
   function Image_Full (Value : Temperature_SHT) return AStr8;
   
   --  return the textual represenation right adjusted (0 .. 99)
   function Image (Value : Humidity_Percentage) return AStr3;

end SHT.Images;
