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

--
--  Sample program that reads the temperatures from all attached
--  1-Wire temperature sensors and prints the values to the serial
--  interface.
--

--  std Ada type definitions, mostly needed for Unsigned_8
with Interfaces;                   use Interfaces;

with AVR;                          use AVR;
with AVR.Wait;
--  address and bit name constants for the MCU
with AVR.MCU;
--  routines to send and receive data across the serial line
with AVR.UART;

--  Dallas 1-Wire definitions and routines for a bus master
with One_Wire;                     use One_Wire;
with One_Wire.Search;
with One_Wire.ROM;
with One_Wire.Temperature_Sensors; use One_Wire.Temperature_Sensors;
with Crc8;

--  temperature types using Ada's fixed point capabilities
with Temperatures;                 use Temperatures;

procedure Test_DS1820 is

   Found : Boolean;

   procedure Wait_1ms is new
     AVR.Wait.Generic_Wait_Usecs (Crystal_Hertz => 8_000_000,
                                  Micro_Seconds => 1000);

   --  workaround until a real Ada delay statement can be used
   procedure Wait_Long is
   begin
      -- delay 0.8;
      for J in 1 .. 800 loop
         Wait_1ms;
      end loop;
   end Wait_Long;


   procedure LED_On is
   begin
      MCU.PORTB_Bits (0) := Low;
      MCU.PORTB_Bits (1) := High;
   end LED_On;

   procedure LED_Off is
   begin
      MCU.PORTB_Bits (0) := High;
      MCU.PORTB_Bits (1) := Low;
   end LED_Off;


   --  this demo can handle up to 5 devices
   Max_OW_Devices : constant := 5;
   subtype OW_Device_Range       is Unsigned_8      range 0 .. Max_OW_Devices;
   subtype OW_Valid_Device_Range is OW_Device_Range range 1 .. Max_OW_Devices;

   type OW_Device_A is array (OW_Valid_Device_Range)
     of One_Wire.ROM.Unique_Serial_Code;
   type OW_Temp_A is array (OW_Valid_Device_Range) of Temperature_12bit;


   OW_Devices : OW_Device_A;  -- array of sensor rom codes
   OW_Temps   : OW_Temp_A;    -- array of corresponding temperatures

   OW_Sensor_Index : OW_Device_Range;
   Last_Sensor     : OW_Device_Range;

   Crc             : Unsigned_8;

begin
   MCU.CLKPR := MCU.CLKPCE_Mask;
   MCU.CLKPR := 0;

   --  show results on LEDs at port B
--   MCU.DDRB_Bits (0) :=  DD_Output;
--   MCU.DDRB_Bits (1) :=  DD_Output;
   --  provide high voltage at D4 as power supply in non-parasite mode
   MCU.DDRE_Bits (5) :=  DD_Output;
   MCU.PORTE_Bits (5) := High;

   --
   --
   -- don't init the UART, done automatically by the debug package
   AVR.UART.Init (51, True);          -- Baud rate = 9600bps, 8MHZ, u2x=0

   One_Wire.Init_Comm;

   UART.Put_Line ("starting RE's 1-Wire to serial output test program");

   loop
      UART.New_Line;
      UART.New_Line;
      UART.Put_Line ("--> Test 1-wire to serial output");

      LED_On;

      OW_Sensor_Index := 1;
      Last_Sensor     := 0;

      --  first find all devices
      Found := One_Wire.Search.First;
      if Found then
         LED_Off;
         loop
            --  copy the rom code to our array
            OW_Devices (OW_Sensor_Index) := One_Wire.ROM.Identifier;
            --  increment the sensor index
            Last_Sensor := OW_Sensor_Index;
            OW_Sensor_Index := OW_Sensor_Index + 1;

            --  search the next device
            Found := One_Wire.Search.Next;
            exit when not Found;
         end loop;

      else
         UART.Put_Line ("no device");
      end if;

      -- Power_Off;

      --  print list of found IDs
      --  <sensor index> :  <ROM code in hex>
      for Idx in 1 .. Last_Sensor loop
         UART.Put ("ID ");
         UART.Put (Nat8 (Idx));
         UART.Put (":  ");

         Crc := 0;
         for J in One_Wire.ROM.Serial_Code_Index loop
            Crc := Crc8 (Data => OW_Devices (Idx)(J),
                         Seed => Crc);
            Uart.Put (Nat8 (OW_Devices (Idx)(J)), Base => 16);
            Uart.Put (' ');
         end loop;
         UART.Put ("CRC: ");
         UART.Put (Nat8 (Crc), Base => 16);
         UART.New_Line;
      end loop;

      Wait_Long;

      -- Power_On;

      --  start conversion for all sensors
      One_Wire.ROM.Identifier (1) := 0;
      --  see comment in One_Wire.Temperature_Sensors.  If the first
      --  byte of the ROM code is zero, send the command to start
      --  temperature sampling to all temperature sensors.
      One_Wire.Temperature_Sensors.Init_T_Conversion;

      --  leave enough time for the temperature conversion. (750ms for
      --  12 bit!  see the DS18B20 data sheet.)
      Wait_Long;


      --  request temp reading
      for Idx in 1 .. Last_Sensor loop
         --  set the rom code
         One_Wire.ROM.Identifier := OW_Devices (Idx);
         --  and read the temperature
         if One_Wire.ROM.Identifier (1) = Family_Code (DS18S20) then
            -- in case of the simple sensors add 3 bits to the right of
            -- the raw value
            OW_Temps (Idx) := To_Temperature_12bit (Read_Raw_Value * 8);
         else
            OW_Temps (Idx) := To_Temperature_12bit (Read_Raw_Value);
         end if;
      end loop;

      --  Power_Off;

      --  print list of temperature readings
      for Idx in 1 .. Last_Sensor loop
         UART.Put ("ID ");
         UART.Put (Nat8 (Idx));
         UART.Put (": T = ");
         UART.Put (Image (OW_Temps (Idx)));
         UART.Put ('C');
         UART.New_Line;
      end loop;

      LED_Off;
      UART.Put_Line ("Test - off");
      Wait_Long;

   end loop;

end Test_DS1820;
