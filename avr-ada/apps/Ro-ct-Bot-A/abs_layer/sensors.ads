--      Architekturunabhaengiger Teil der Sensorsteuerung

with Interfaces;                   use Interfaces;

package Sensors is

   --  all analog sensors are based on the 10 bit resolution of the AD
   --  converters
   subtype Analog_Sensor is Integer_16 range 0 .. 2 ** 10 - 1;

   Dist_L   : Analog_Sensor := 1023;  -- Distanz linker IR-Sensor
   Dist_R   : Analog_Sensor := 1023;  -- Distanz rechter IR-Sensor

   LDR_L    : Analog_Sensor := 0;     -- Lichtsensor links
   LDR_R    : Analog_Sensor := 0;     -- Lichtsensor rechts

   Border_L : Analog_Sensor := 0;     -- Abgrundsensor links
   Border_R : Analog_Sensor := 0;     -- Abgrundsensor rechts

   Line_L   : Analog_Sensor := 0;     -- Lininensensor links
   Line_R   : Analog_Sensor := 0;     -- Lininensensor rechts

   Enc_L    : Integer_16    := 0;     -- Encoder linker Motor
   Enc_R    : Integer_16    := 0;     -- Encoder rechter Motor


   type Open_T is (Open, Closed);
   for Open_T'Size use 8;

   Trans    : Open_T     := Open;     -- Sensor Ueberwachung Transportfach

   Door     : Open_T     := Open;     -- Sensor Ueberwachung Klappe

   type Error_T is (Err, No_Err);
   for Error_T'Size use 8;

   Error    : Error_T    := No_Err;   -- Ueberwachung Motor oder Batteriefehler

   --  Rc5      : Integer_16 := 0;     -- Fernbedienungssensor

   Mouse_DX : Integer_8  := 0;        -- Maussensor Delta X
   Mouse_DY : Integer_8  := 0;        -- Maussensor Delta X


   -- Initialisiere alle Sensoren
   procedure Init;

   -- Alle Sensoren aktualisieren
   procedure Bot_Sens;


private
   pragma Volatile (Dist_L);
   pragma Volatile (Dist_R);
   pragma Volatile (LDR_L);
   pragma Volatile (LDR_R);
   pragma Volatile (Enc_L);
   pragma Volatile (Enc_R);
   pragma Volatile (Border_L);
   pragma Volatile (Border_R);
   pragma Volatile (Line_L);
   pragma Volatile (Line_R);
   pragma Volatile (Trans);
   pragma Volatile (Door);
   pragma Volatile (Error);
   --  pragma Volatile (Rc5);
   pragma Volatile (Mouse_DX);
   pragma Volatile (Mouse_DY);
end Sensors;
