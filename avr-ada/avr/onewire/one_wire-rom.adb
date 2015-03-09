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

--  This package provides the interface to the ROM commands of Dallas
--  1-Wire devices.


with Interfaces;                   use Interfaces;
with Crc8;

package body One_Wire.ROM is

   procedure Send_Identifier is
      D : Unsigned_8; --  dummy
   begin
      for I in Serial_Code_Index loop
         D := Touch (Identifier (I));
      end loop;
   end Send_Identifier;


   --  Check the CRC, returns True on success, False on failure
   function Verify_CRC return Boolean
   is
      C : Unsigned_8;
   begin
      C := 0;
      for I in Serial_Code_Index'(1) .. 7 loop
         C := Crc8 (Identifier (I), C);
      end loop;
      return C = Identifier (8);
   end Verify_CRC;


end One_Wire.ROM;
