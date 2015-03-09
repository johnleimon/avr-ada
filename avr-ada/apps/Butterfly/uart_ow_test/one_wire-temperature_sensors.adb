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

with Ada.Unchecked_Conversion;
with Interfaces;                   use Interfaces;

with One_Wire.ROM;
with CRC8;

with AVR.UART;

package body One_Wire.Temperature_Sensors is

   Debug_LL_Read : constant Boolean := True;

   --  If Check_Read is true, the the while scratch pad is read from
   --  the sensors and a CRC check is performed.  In case of error the
   --  procedure is repeated two times before giving up.  If the third
   --  try still fails the error indicating temperature of 66.0 degrees
   --  is returned.
   --
   --  If Check_Read is false only the first two bytes with the
   --  temperature values are read and returned immediately.
   Check_Read : constant Boolean := True;

   procedure Debug_Put_LSB_MSB (LSB, MSB : Unsigned_8);
   procedure Debug_Put_T (T : Temperature_9bit);
   procedure Debug_Put_T (T : Temperature_12bit);

   function To_T9 is
      new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                    Target => Temperature_9bit);

   function To_T9 is
      new Ada.Unchecked_Conversion (Source => Integer_16,
                                    Target => Temperature_9bit);

   function To_T12 is
      new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                    Target => Temperature_12bit);

   procedure Debug_Put_LSB_MSB (LSB, MSB : Unsigned_8)
   is
      use AVR;
      use AVR.UART;
   begin
      Put ("LSB:");
      Put (Nat8 (LSB), 16);
      Put (", MSB:");
      Put (Nat8 (MSB), 16);
   end Debug_Put_LSB_MSB;

   procedure Debug_Put_T (T : Temperature_9bit)
   is
      use AVR.UART;
   begin
      Put (',');
      Put (" T9 = ");
      Put (Image (T));
      Put ("end (t9)");
      New_Line;
   end Debug_Put_T;

   procedure Debug_Put_T (T : Temperature_12bit)
   is
      use AVR.UART;
   begin
      Put (',');
      Put (" T12 = ");
      Put (Image_Full (T));
      Put (" end (t12)");
      New_Line;
   end Debug_Put_T;


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
         Send_Command (ROM.Commands.Skip_ROM);
      else
         Send_Command (ROM.Commands.Match_ROM);
         ROM.Send_Identifier;
      end if;
      Send_Command (Commands.Convert_T);

      --  activly hold line high
      Set_Data_Line_High;

      AVR.UART.Put_Line ("(ow-init_t_conversion): T conversion initiated");
   end Init_T_Conversion;


   function Common_Read_Temperature return Unsigned_16
   is
      MSB : Unsigned_8;  -- most significant byte (bits 8..15)
      LSB : Unsigned_8;  -- least significant byte (bits 0..7)
      Found : Boolean;
   begin
      Found := One_Wire.Reset;
      if not Found then return 16#0378#; end if;
      One_Wire.Send_Command (ROM.Commands.Match_ROM);
      One_Wire.ROM.Send_Identifier;
      One_Wire.Send_Command (Commands.Read_Scratchpad);

      LSB := One_Wire.Get;
      MSB := One_Wire.Get;

      if Debug_LL_Read then Debug_Put_LSB_MSB (LSB, MSB); end if;

      if Check_Read then
         declare
            use AVR;
            use AVR.UART;
            Crc : Unsigned_8;
            T   : Unsigned_8;
         begin
            Crc := Crc8 (LSB, 0);
            Crc := Crc8 (MSB, Crc);
            for I in AVR.Nat8 range 2 .. 8 loop
               T := Get;
               Crc := Crc8 (T, Crc);
               Put (" I:");   Put (I);
               Put (" R:");   Put (AVR.Nat8 (T), 16);
               Put (" Crc:"); Put (AVR.Nat8 (Crc), 16);
            end loop;
            New_Line;
         end;
      end if;

      return Unsigned_16 (MSB) * 256 + Unsigned_16 (LSB);
   end Common_Read_Temperature;


   --  Read the temperature from the sensor specified in
   --  ROM.Identifier.  Depending on the family code in
   --  ROM.Identifier, either a DS18S20 or a DS18B20 read is
   --  performed.
   function Read_Temperature return Temperature_9bit
   is
      T_U16 : Unsigned_16;
      T9    : Temperature_9bit;
   begin
-- #if Target = "host" then
--       return 11.5;
-- #else
      T_U16 := Common_Read_Temperature;
      if ROM.Identifier (1) = Family_Code (DS18S20) then
         T9 := To_T9 (T_U16);
      else
         --  the DS18B20 is in 12bit mode per default, remove least 3
         --  bits.  Dividing a signed number preserves the sign bit.
         T9 := To_T9 (Integer_16 (T_U16) / 8);
      end if;

      if Debug_LL_Read then Debug_Put_T (T9); end if;

      return T9;
-- #end if;
   end Read_Temperature;


   function Read_Temperature return Temperature_12bit
   is
      T_U16 : Unsigned_16;
      T12   : Temperature_12bit;
   begin
      T_U16 := Common_Read_Temperature;
      if ROM.Identifier (1) = Family_Code (DS18S20) then
         T12 := To_T12 (T_U16 * 8);
      else
         T12 := To_T12 (T_U16);
      end if;

      if Debug_LL_Read then Debug_Put_T (T12); end if;

      return T12;
   end Read_Temperature;

end One_Wire.Temperature_Sensors;
