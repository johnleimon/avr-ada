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

package SHT.LL is
   pragma Preelaborate;

   procedure Clock_Line_High;
   procedure Clock_Line_Low;
   procedure Data_Line_High;
   procedure Data_Line_Low;
   function  Read_Data_Line return Boolean;
   procedure Init;

private

   pragma Inline_Always (Clock_Line_High);
   pragma Inline_Always (Clock_Line_Low);
   pragma Inline_Always (Data_Line_High);
   pragma Inline_Always (Data_Line_Low);
   pragma Inline (Read_Data_Line);
   pragma Inline (Init);

end SHT.LL;
