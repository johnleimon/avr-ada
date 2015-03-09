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

package SHT is
   pragma Pure;


   type Mode_Type is (Temperature, Humidity);

   type Error_Code is (OK, No_Ack_Error, Timeout_Error, Error);
   for Error_Code'Size use 8;

   type Command_Code is new Unsigned_8;

   type Status_Code is new Unsigned_8;

   type ADC_Type is new Unsigned_16;


   --  temperature format of the SHT
   type Temperature_SHT is delta 0.01 range -40.0 .. 120.0;
   for Temperature_SHT'Size use 16;


   type Humidity_Percentage is range 0 .. 100;
   for Humidity_Percentage'Size use 8;


   package Commands is
      --                                                 adr cmd r/w
      Write_Status_Register : constant Command_Code := 2#000_0011_0#;
      Read_Status_Register  : constant Command_Code := 2#000_0011_1#;
      Measure_Temperature   : constant Command_Code := 2#000_0001_1#;
      Measure_Humidity      : constant Command_Code := 2#000_0010_1#;
      Soft_Reset            : constant Command_Code := 2#000_1111_0#;
   end Commands;


end SHT;
