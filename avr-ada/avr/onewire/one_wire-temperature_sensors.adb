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

with One_Wire.ROM;
with One_Wire.Commands;
with CRC8;

with Debug;

package body One_Wire.Temperature_Sensors is


   --  If Check_Read is true, then while scratch pad is read from
   --  the sensors a CRC check is performed.  In case of error the
   --  procedure is repeated two times before giving up.  If the third
   --  try still fails the error indicating temperature of 66.0 degrees
   --  is returned.
   --
   --  If Check_Read is false only the first two bytes with the
   --  temperature values are read and returned immediately.
   Check_Read : constant Boolean := False;
   Debug_Read : constant Boolean := False;

   procedure Debug_Put_LSB_MSB (LSB, MSB : Unsigned_8)
   is
      use Debug;
   begin
      Put ("LSB = ");
      Put (LSB, 16);
      Put (", MSB = ");
      Put (MSB, 16);
   end Debug_Put_LSB_MSB;


   --  Initialize a temperature conversion.  If the first byte of
   --  ROM.Identifier is 0, the conversion is issued to all sensors.
   --  If ROM.Identifier is set, temperature conversion is started
   --  only for the specific sensor.
   procedure Init_T_Conversion is
      Found : Boolean;
   begin
      Found := Reset;
      if not Found then return; end if;
      if ROM.Identifier (1) = 0 then
         Send_Command (One_Wire.Commands.Skip_ROM);
      else
         Send_Command (One_Wire.Commands.Match_ROM);
         ROM.Send_Identifier;
      end if;
      Send_Command (Commands.Convert_T);

      --  activly hold line high
      Set_Data_Line_High;

   end Init_T_Conversion;


   function Read_Raw_Value return Unsigned_16
   is
      MSB : Unsigned_8;  -- most significant byte (bits 8..15)
      LSB : Unsigned_8;  -- least significant byte (bits 0..7)
      Found : Boolean;
   begin
   --<<Start>>
      Found := One_Wire.Reset;
      if not Found then return 16#0378#; end if;  -- = 55.5, 12bit
      One_Wire.Send_Command (Commands.Match_ROM);
      One_Wire.ROM.Send_Identifier;
      One_Wire.Send_Command (Commands.Read_Scratchpad);

      LSB := One_Wire.Get;
      MSB := One_Wire.Get;

      if Debug_Read then Debug_Put_LSB_MSB (LSB, MSB); end if;

      if Check_Read then
         declare
            -- use AVR;
            use Debug;
            Crc : Unsigned_8;
            T   : Unsigned_8;
         begin
            Crc := CRC8 (LSB, 0);
            Crc := CRC8 (MSB, Crc);
            for I in Unsigned_8 range 2 .. 8 loop
               T := Get;
               Crc := CRC8 (T, Crc);
               if Debug_Read then
                  Put (" I:");   Put (I);
                  Put (" R:");   Put (T, 16);
                  Put (" Crc:"); Put (Crc, 16);
               end if;
            end loop;
            if Debug_Read then New_Line; end if;
            -- if Crc /= 0 then goto Start; end if;
            if Crc /= 0 then return 16#063E#; end if; -- = 99.9, 12bit
         end;
      end if;

      return Unsigned_16 (MSB) * 256 + Unsigned_16 (LSB);
   end Read_Raw_Value;


end One_Wire.Temperature_Sensors;
