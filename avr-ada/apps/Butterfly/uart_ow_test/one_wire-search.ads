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

--  provide routines for communication with selected devices on the
--  1-Wire bus.

package One_Wire.Search is
   pragma Preelaborate (One_Wire.Search);


   function First return Boolean;
   --  Find the 'first' devices on the 1-Wire bus
   --  Return TRUE : device found, ROM number in ROM.Identifier
   --  FALSE : no device present

   function Next return Boolean;
   --  Find the 'next' devices on the 1-Wire bus
   --  Return TRUE : device found, ROM number in ROM.Identifier.
   --  FALSE : device not found, end of search

   procedure Target_Setup (Family_Code : Unsigned_8);
   --  Setup the search to find the device type 'family_code' on the
   --  next call to Next if it is present.

   function Verify return Boolean;
   --  Verify the device with the ROM number in ROM.Identifier is
   --  present.
   --  Return TRUE : device verified present
   --  FALSE : device not present

   procedure Family_Skip_Setup;
   --  Setup the search to skip the current device type on the next
   --  call to Next.

end One_Wire.Search;
