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

with Ada.Unchecked_Conversion;

package body SHT.Calc is


   function To_SHT is new Ada.Unchecked_Conversion (Source => ADC_Type,
                                                    Target => Temperature_SHT);

   -- calculates temperature T [°C] from ADC value T_ADC [Ticks] (14 bit)
   function Raw_to_Temperature (T_Raw : ADC_Type) return Temperature_SHT
   is
      T : ADC_Type := T_Raw;
   begin
      T := T - 4000;
      return To_SHT (T);
   end Raw_To_Temperature;


   -- calculates temperature [°C] and humidity [%RH]
   -- input : humi [Ticks] (12 bit)
   -- temp [Ticks] (14 bit)
   -- output: humi [%RH]
   -- temp [°C]
--     procedure Calc_Sth11 (RH_ADC     : Nat16;
--                           T_ADC      : Nat16;
--                           Humidity     : out Float;
--                           Temperature  : out Float)
--     is
--        C1 : constant := -4.0; -- for 12 Bit
--        C2 : constant := 0.0405; -- for 12 Bit
--        C3 : constant := -0.0000028; -- for 12 Bit
--        T1 : constant := 0.01; -- for 14 Bit @ 5V
--        T2 : constant := 0.00008; -- for 14 Bit @ 5V

--        Rh : constant Float := Float (RH_ADC); -- Humidity [Ticks] 12 Bit
--        --T  : constant Float := Float (T_ADC);  -- Temperature [Ticks] 14 Bit
--        Rh_Lin  : Float;                       -- rh_lin: Humidity linear
--        Rh_True : Float renames Humidity;      -- Temperature compensated humidity
--        T_C     : Float renames Temperature;   -- Temperature [°C]
--     begin
--        --  calc. Temperature from ticks to [°C]
--        T_C := Float (T_ADC) * 0.01 - 40.0;

--        --  calc. Humidity from ticks to [%RH]
--        Rh_Lin := C3 * rh*rh + C2*rh + C1;

--        --  calc. Temperature compensated humidity [%RH]
--        Rh_True := (t_C-25.0) * (T1+T2*rh) + rh_lin;

--        --  cut if the value is outside of the physical possible range
--        if Rh_True > 100.0 then
--           Rh_True := 100.0;
--        end if;
--        if Rh_True < 0.1 then
--           Rh_True := 0.1;
--        end if;
--     end;


   --  see Sensirion application note "Non-linearity compensation"
   function Raw_to_Humidity (RH_Raw : ADC_Type) return Humidity_Percentage
   is
      --        A_Lo_8_V3 : constant :=  -512;
      --        B_Lo_8_V3 : constant :=   143;
      --        A_Hi_8_V3 : constant :=  2893;
      --        B_Hi_8_V3 : constant :=   111;
      A_Lo_12_V4 : constant :=  3_680;
      B_Lo_12_V4 : constant :=    138;
      A_Hi_12_V4 : constant := 20_896;
      B_Hi_12_V4 : constant :=    122;
      RH         : Humidity_Percentage;
   begin
      if RH_Raw <= 1_712 then
         RH := Humidity_Percentage ((B_Lo_12_V4 * RH_Raw - A_Lo_12_V4) / 4096);
      else
         RH := Humidity_Percentage ((A_Hi_12_V4 + B_Hi_12_V4 * RH_Raw) / 4096);
      end if;
      return RH;
   end Raw_To_Humidity;

end SHT.Calc;
