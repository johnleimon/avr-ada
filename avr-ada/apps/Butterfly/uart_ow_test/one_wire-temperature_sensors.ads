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

--  This package provides a more high level interface to the
--  temperature sensors DS18S20 and DS18B20.

--  The transaction sequence for accessing the DS18S20 is as follows:
--
--  Step 1. Initialization (reset)
--  Step 2. ROM Command (followed by any required data exchange)
--  Step 3. DS18S20 Function Command (followed by any required data
--          exchange)
--
--  It is very important to follow this sequence every time the
--  DS18S20 is accessed, as the DS18S20 will not respond if any steps
--  in the sequence are missing or out of order.


with Interfaces;                   use Interfaces;

with Temperatures;                 use Temperatures;


package One_Wire.Temperature_Sensors is
   pragma Preelaborate (One_Wire.Temperature_Sensors);

   type Sensor_Type is (DS18S20, DS18B20);
   for Sensor_Type'Size use 8;


   Family_Code : constant array (Sensor_Type) of Unsigned_8 :=
     (DS18S20 => 16#10#,
      DS18B20 => 16#28#);

   package Commands is
      --
      -- DS1820 commands
      --

      --  initiate temparature conversion
      Convert_T           : constant Command_Code := 16#44#;

      --  recalls T_H and T_L from EEPROM to the scratchpad.
      Recall_EEprom       : constant Command_Code := 16#B8#;

      --  signal power supply mode to the master.
      Read_Power_Supply   : constant Command_Code := 16#B4#;

      --  read the entire scratchpad including CRC byte.
      Read_Scratchpad     : constant Command_Code := 16#BE#;

      --  copy data from the scratchpad to the EEPROM.
      Copy_Scratchpad     : constant Command_Code := 16#48#;

      --  write data into scratchpad bytes 2 (T_H) and 3 (T_L)
      Write_Scratchpad    : constant Command_Code := 16#4E#;
   end Commands;


   --  Initialize a temperature conversion.  If the first byte of
   --  ROM.Identifier is 0, the conversion is issued to all sensors.
   --  If ROM.Identifier is set, temperature conversion is started
   --  only for the specific sensor.
   procedure Init_T_Conversion;


   --  Read the temperature from the sensor specified in
   --  ROM.Identifier.  Depending on the family code in
   --  ROM.Identifier, either a DS18S20 or a DS18B20 read is
   --  performed.
   function Read_Temperature return Temperature_9bit;
   function Read_Temperature return Temperature_12bit;

end One_Wire.Temperature_Sensors;
