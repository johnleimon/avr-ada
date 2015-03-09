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
--  routines for accessing the ports
-- with AVR.IO;                       use AVR.IO;
--  address and bit name constants for the MCU
with AVR.MCU;
--  routines to send and receive data across the serial line
with AVR.UART;                     use AVR.UART;

--  Dallas 1-Wire definitions and routines for a bus master
with One_Wire;
with One_Wire.Search;
with One_Wire.Temperature_Sensors; use One_Wire.Temperature_Sensors;
with One_Wire.ROM;
with Crc8;

--  temperature types using Ada's fixed point capabilities
with Temperatures;                 use Temperatures;

procedure Main is


   Power    : Boolean renames AVR.MCU.PortE_Bits (5);
   Power_DD : Boolean renames AVR.MCU.DDRE_Bits (5);


   --  workaround until a real Ada delay statement can be used
   procedure Wait_Long is
      A : Nat8;
   begin
      for I in 1 .. 1100 loop
         for J in 1 .. 1000 loop
            A := AVR.MCU.PORTE;
         end loop;
      end loop;
   end Wait_Long;

   procedure Power_On is
   begin
      --  set PE5 to high to provide Vcc to the 1-Wire devices
      MCU.DDRE_Bits (MCU.PORTE5_Bit) := DD_Output;
      MCU.PortE_Bits (MCU.PORTE5_Bit) := True;

      Power_DD := DD_Output;
      Power    := True;
   end Power_On;
   pragma Inline (Power_On);


   procedure Power_Off is
   begin
      --  set PE6 to input to switch off power to the 1-Wire devices
      MCU.DDRE_Bits (MCU.PORTE5_Bit) := DD_Input;
      MCU.PortE_Bits (MCU.PORTE5_Bit) := False;
      null;
      Power_DD := DD_Input;
      Power    := False;
   end Power_Off;
   pragma Inline (Power_Off);


   --  did we find a 1-Wire device on the bus?
   Found : Boolean;

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

   MCU.CLKPR := MCU.CLKPCE_Mask;     -- set Clock Prescaler Change Enable
   MCU.CLKPR := 0;                   -- 8MHz
   --    set prescaler = 8, Inter RC 8Mhz / 8 = 1Mhz
   -- Set (CLKPR, CLKPS1 or CLKPS0); -- 1MHz

   --
   Wait_Long;

   One_Wire.Init_Comm;

   AVR.UART.Init (51);          -- Baud rate = 9600bps, 1MHZ, u2x=1

   Put_Line ("starting RE's 1-Wire to serial output test program");


   loop
      New_Line (2);
      Put_Line ("--> Test 1-wire to serial output");

      Power_On;

      OW_Sensor_Index := 1;
      Last_Sensor     := 0;

      --  first find all devices
      Found := One_Wire.Search.First;
      if Found then
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
         Uart.Put_Line ("no device");
--           if Found = Short then
--              Uart.Put_Line ("short?");
--           end if;

      end if;

      Power_Off;


      --  print list of found IDs
      --  <sensor index> :  <ROM code in hex>
      for Idx in 1 .. Last_Sensor loop
         Crc := 0;
         Put ("ID ");
         Put (Nat8 (Idx));
         Put (":  ");
         for J in One_Wire.ROM.Serial_Code_Index loop
            Crc := Crc8 (Data => OW_Devices (Idx)(J),
                         Seed => Crc);
            Put (Nat8 (OW_Devices (Idx)(J)), Base => 16);
            Put (' ');
         end loop;
         Put ("CRC: ");
         Put (Nat8 (Crc), Base => 16);
         New_Line;
      end loop;


      Power_On;

      --  start conversion for all sensors
      One_Wire.ROM.Identifier (1) := 0;
      --  see comment in One_Wire.Temperature_Sensors.  If the first
      --  byte of the ROM code is zero, send the command to start
      --  temperature sampling to all temperature sensors.
      One_Wire.Temperature_Sensors.Init_T_Conversion;

      --  leave enough time for the temperature conversion. (750ms for
      --  12 bit!  see the DS18B20 data sheet.)
      Wait_Long;
      Wait_Long;


      --  request temp reading
      for Idx in 1 .. Last_Sensor loop
         --  set the rom code
         One_Wire.ROM.Identifier := OW_Devices (Idx);
         --  and read the temperature
         OW_Temps (Idx) := Read_Temperature;
      end loop;

      Power_Off;

      --  print list of temperature readings
      for Idx in 1 .. Last_Sensor loop
         Put ("ID ");
         Put (Nat8 (Idx));
         Put (": T = ");
         Put (Image (OW_Temps (Idx)));
         Put ('C');
         New_Line;
      end loop;

      Wait_Long;
      Wait_Long;
      Wait_Long;
      Wait_Long;

   end loop;

end Main;

