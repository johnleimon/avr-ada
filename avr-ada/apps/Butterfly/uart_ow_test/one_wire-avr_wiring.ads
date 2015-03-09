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

with AVR;                          use AVR;
with AVR.MCU;

package One_Wire.AVR_Wiring is
   pragma Preelaborate;
   -- pragma Pure;

   OW_Port : Bits_In_Byte renames MCU.PORTE_Bits;
--     pragma Volatile (OW_Port);
--     for OW_Port'Address use MCU.PORTE_Addr;
--     --  the latch registers (output) of the port

--     OW_DD   : Bits_In_Byte; -- renames MCU.DDRE_Bits;
--     pragma Volatile (OW_DD);
--     for OW_DD'Address use MCU.DDRE_Addr;
--     --  the data direction port

--     OW_In   : Bits_In_Byte; -- renames MCU.PINE_Bits;
--     pragma Volatile (OW_In);
--     for OW_In'Address use MCU.PINE_Addr;
   --  the input port

   OW_Line : constant AVR.Bit_Number := 4;
   --  the I/O pin on the port where the bus is connected

   -------------------------------------------------------
   OW_DD  : Boolean renames MCU.DDRE_Bits (OW_Line);
   OW_Out : Boolean renames MCU.PortE_Bits (OW_Line);
   OW_In  : Boolean renames MCU.PinE_Bits (OW_Line);

end One_Wire.AVR_Wiring;
