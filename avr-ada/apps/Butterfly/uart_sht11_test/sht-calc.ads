package SHT.Calc is
   pragma Preelaborate;


   type Humidity_Percentage is range 0 .. 100;
   for Humidity_Percentage'Size use 8;

   procedure Calc_Humidity (RH_Raw :     Nat16;
                            RH     : out Humidity_Percentage);


   -- calculates temperature T [°C] from ADC value T_ADC [Ticks] (14 bit)
--     procedure Calc_Temperature (T_ADC : in  Nat16;
--                                 T     : out Temperature_12bit);


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

   -- calculates dew point
--   function Calc_Dewpoint (h : Float; t : float) return Float;
   -- input: humidity [%RH], temperature [°C]
   -- output: dew point [°C]


end SHT.Calc;
