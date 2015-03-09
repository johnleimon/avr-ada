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
with Interfaces;                   use type Interfaces.Unsigned_16;

--  routines for accessing the ports
with AVR;                          use AVR;
--  address and bit name constants for the MCU
with AVR.MCU;

--
with SHT;                          use SHT;
with SHT.Calc;

--  temperature types using Ada's fixed point capabilities
-- with Temperatures;                 use Temperatures;

with AVR.UART;                     use AVR.UART;
--with CRC8;


procedure Main is

   --  workaround until a real Ada delay statement can be used
   procedure Wait_Long is
      A: Nat8;
   begin
      for I in 1 .. 4000 loop
         for J in 1 .. 200 loop
            A := MCU.PORTB;
         end loop;
      end loop;
      null;
   end Wait_Long;


   Humi_Raw   : Nat16;
   -- RH         : SHT.Humidity_Percentage;
   Temp_Raw   : Nat16;
   Temp_L     : Nat16;
   Err        : Error_Code;
   Checksum   : Nat8;
   Status     : Nat8;
   RH         : SHT.Calc.Humidity_Percentage;

   procedure Put (E : Sht.Error_Code)
   is
   begin
      case E is
         when OK =>
            Put ("OK");
         when No_Ack_Error =>
            Put ("No_Ack_Error");
         when Timeout_Error =>
            Put ("Timeout_Error");
         when Error =>
            Put ("Error");
      end case;
   end Put;

begin
   MCU.CLKPR := MCU.CLKPCE_Mask;    -- set Clock Prescaler Change Enable
   MCU.CLKPR := 0;                  -- 8MHz
   --    set prescaler = 8, Inter RC 8Mhz / 8 = 1Mhz
   -- Set (CLKPR, CLKPS1 or CLKPS0); -- 1MHz

   Wait_Long;

   UART.Init (12);   -- 51, True ==> 19200
                     -- 12, False ==> 38400

   Put_Line ("starting SHT11 to serial output test program");

   SHT.Init;

   loop
      New_Line;
      Put_Line ("--> Test SHT11 to UART");

      --
      --  read status
      --
      SHT.Connection_Reset;
      SHT.Read_Statusreg (Status, Checksum, Err);
      Put ("(read_statusreg) E: ");
      Put (Err);
      if Err = OK then
         Put (", check sum:");
         Put (Nat8 (Checksum), 16);
         Put (", status: ");
         Put (Nat8 (Status), 16);
      end if;
      New_Line;

      SHT.Measure (Humi_Raw, Checksum, Humidity, Err);
      SHT.Calc.Calc_Humidity (Humi_Raw, RH);

      Put ("(measure H) E: ");
      Put (Err);
      if Err = OK then
         Put (", H(raw): ");
         Put (Humi_Raw, 16);
         Put (", RH(%): ");
         Put (Nat8 (RH), 10);
         Put ("%, check sum: ");
         Put (Checksum, 16);
      end if;
      New_Line;

      Wait_Long;

      SHT.Measure (Temp_Raw, Checksum, Temperature, Err);

      Temp_L := (Temp_Raw / 100) - 40;
      Temp_L := (Temp_Raw) - 4000;

      Put ("(measure T) E: ");
      Put (Err);
      if Err = OK then
         Put (", T(raw): ");
         Put (Temp_Raw, 16);
         Put (", T(C): ");
         Put (Temp_L, 10);
         Put (", check sum: ");
         Put (Checksum, 16);
      end if;
      New_Line;

      Wait_Long;
      Wait_Long;
      Wait_Long;

   end loop;

end Main;

