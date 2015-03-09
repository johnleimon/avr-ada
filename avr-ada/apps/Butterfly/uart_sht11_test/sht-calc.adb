with Interfaces;                   use Interfaces;
-- with Ada.Unchecked_Conversion;
-- with Temperatures;                 use Temperatures;


package body SHT.Calc is


   -- calculates temperature T [°C] from ADC value T_ADC [Ticks] (14 bit)
--     procedure Calc_Temperature (T_ADC : in  Nat16;
--                                 T     : out Temperature_12bit);


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
   procedure Calc_Humidity (RH_Raw :     Nat16;
                            RH     : out Humidity_Percentage)
   is
      --        A_Lo_8_V3 : constant :=  -512;
      --        B_Lo_8_V3 : constant :=   143;
      --        A_Hi_8_V3 : constant :=  2893;
      --        B_Hi_8_V3 : constant :=   111;
      A_Lo_12_V4 : constant Nat16 := 0 - 3_680; -- using overflow semantics
      B_Lo_12_V4 : constant :=    138;
      A_Hi_12_V4 : constant := 20_896;
      B_Hi_12_V4 : constant :=    122;

   begin
      if RH_Raw <= 1_712 then
         RH := Humidity_Percentage ((B_Lo_12_V4 * RH_Raw + A_Lo_12_V4) / 4096);
      else
         RH := Humidity_Percentage ((A_Hi_12_V4 + B_Hi_12_V4 * RH_Raw) / 4096);
      end if;
   end Calc_Humidity;


--     function To_Temp is
--        new Ada.Unchecked_Conversion (Source => Nat16,
--                                      Target => Temperature_12bit);

--     procedure Calc_Temperature (T_ADC : in  Nat16;
--                                 T     : out Temperature_12bit)
--     is
--     begin
--        T := To_Temp (T_ADC);
--        T := T / 100.0;
--        T := T - 40.0;
--     end Calc_Temperature;


   -- calculates dew point
   -- input: humidity [%RH], temperature [°C]
   -- output: dew point [°C]
--     function Calc_Dewpoint (H : Float; T : Float) return Float
--     is
--        Dew_Point : Float;
--        K : Float := 0.0;
--     begin
--  --      K := (Log10 (H) - 2.0) / 0.4343 + (17.62 * T) / (243.12 + T);
--        Dew_Point := 243.12 * K / (17.62 - K);
--        return Dew_Point;
--     end Calc_Dewpoint;

end SHT.Calc;
