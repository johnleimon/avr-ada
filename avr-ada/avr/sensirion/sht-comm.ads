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

with Interfaces;                   use Interfaces;

package SHT.Comm is
   pragma Preelaborate;


   --  initialize all necessary pins
   procedure Init;


   --  writes a byte on the Sensibus and checks the acknowledge
   procedure Write_Byte (Value : in  Command_Code;
                         E     : out Error_Code);


   --  reads a byte form the Sensibus and gives an acknowledge in case
   --  of "Send_Ack=True"
   function Read_Byte (Send_Ack : Boolean) return Unsigned_8;


   --  generate a transmission start
   --        _____         ________
   --  DATA:      |_______|
   --            ___     ___
   --  SCK : ___|   |___|   |______
   --
   procedure Transmission_Start;


   --  communication reset: DATA-line=1 and at least 9 SCK cycles
   --  followed by Transmission_Start
   --       ____________________________________________________         _____
   -- DATA:                                                     |_______|
   --          _    _    _    _    _    _    _    _    _       ___     ___
   -- SCK : __| |__| |__| |__| |__| |__| |__| |__| |__| |_____|   |___|   |___
   procedure Connection_Reset;


   -- resets the sensor by a softreset
   procedure Soft_Reset (E : out Error_Code);


   -- reads the status register with checksum (8-bit)
   procedure Read_Statusreg (Status   : out Unsigned_8;
                             Checksum : out Unsigned_8;
                             E        : out Error_Code);


   -- Writes the status register with checksum (8-bit)
   procedure Write_Statusreg (Status : in Status_Code;
                              E      : out Error_Code);


   -- initiate a measurement (humidity/temperature)
   procedure Init_Measure (Mode : in Mode_Type; E : out Error_Code);
   
   
   --  read the last measured value
   procedure Collect (Raw_Value : out ADC_Type;
                      Checksum  : out Unsigned_8;
                      E         : out Error_Code);

   -- makes a measurement (humidity/temperature) with checksum
   procedure Measure (Raw_Value : out ADC_Type;
                      Checksum  : out Unsigned_8;
                      Mode      : in  Mode_Type;
                      E         : out Error_Code);

end SHT.Comm;
