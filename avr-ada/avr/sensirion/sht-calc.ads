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


package SHT.Calc is
   pragma Pure;


   function Raw_To_Humidity (RH_Raw : ADC_Type) return Humidity_Percentage;


   -- calculates temperature T [°C] from ADC value T_ADC [Ticks] (14 bit)
   function Raw_To_Temperature (T_Raw : ADC_Type) return Temperature_SHT;


   ------------------------------------------------------------------

   -- calculates temperature [°C] and humidity [%RH]
--     procedure Calc_Sth11 (RH_ADC      :     Nat16;
--                           T_ADC       :     Nat16;
--                           Humidity    : out Float;
--                           Temperature : out Float);
   -- input : humi [Ticks] (12 bit)
   -- temp [Ticks] (14 bit)
   -- output: humi [%RH]
   -- temp [°C]

end SHT.Calc;
