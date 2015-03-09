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

--  implement CRC-8 checksum calculation as used in Dallas 1-wire devices

with Interfaces;                   use Interfaces;

function CRC8 (Data : Unsigned_8; -- data to calculate the CRC
               Seed : Unsigned_8) -- initial value of CRC
               return Unsigned_8
is
   Result : Unsigned_8 := Seed;
   S_Data : Unsigned_8 := Data;
begin
   for Bit in Unsigned_8'(1) .. 8 loop
      if ((Result xor S_Data) and 16#01#) = 0 then
         Result := Shift_Right (Result, 1);
      else
         Result := Result xor 16#18#;
         Result := Shift_Right (Result, 1);
         Result := Result or 16#80#;
      end if;
      S_Data := Shift_Right (S_Data, 1);
   end loop;
   return Result;
end CRC8;
