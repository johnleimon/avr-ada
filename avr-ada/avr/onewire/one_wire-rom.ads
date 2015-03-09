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

package One_Wire.ROM is
   pragma Preelaborate (One_Wire.ROM);


   subtype Serial_Code_Index is Unsigned_8 range 1 .. 8;
   --  if we don't provide this type, GNAT choses Integer as base type
   --  for the index which is 16 bit wide on AVR.  But we need space
   --  efficient code on the microcontroller...


   type Unique_Serial_Code is array (Serial_Code_Index) of Unsigned_8;
   --  the 64 bit device identifier


   --  a static global instance used for communication
   Identifier : Unique_Serial_Code;

   --  alias names for the first and last byte in the indentifier
   Family_Code : Unsigned_8 renames Identifier (1);
   CRC         : Unsigned_8 renames Identifier (8);


   --  Check the CRC, returns True on success, False on failure
   function Verify_CRC return Boolean;


   --  write the value of the identifier to the bus.
   procedure Send_Identifier;


end One_Wire.ROM;
