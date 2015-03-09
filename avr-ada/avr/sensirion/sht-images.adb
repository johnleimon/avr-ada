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

with Ada.Unchecked_Conversion;
with AVR.Strings;                  use AVR.Strings;
with AVR.Int_Img;

package body SHT.Images is


   function To_I16 is new Ada.Unchecked_Conversion (Source => Temperature_SHT,
                                                    Target => Integer_16);

   --  return the textual representation with one decimal digit, rounded.
   function Image (Value : Temperature_SHT) return AStr5
   is
      use AVR.Int_Img;
      Img : Astr5;
      V : constant Integer_16 := To_I16 (Value+0.05);
   begin
      if V < 0 then
         U16_Img_Right (Unsigned_16 (-V), Img);
         Img (1) := '-';
      else
         U16_Img_Right (Unsigned_16 (V), Img);
      end if;
      Img (5) := Img (4);
      Img (4) := '.';
      return Img;
   end Image;


   --  return the textual representation with all four decimal digits.
   function Image_Full (Value : Temperature_SHT) return AStr8
   is
      Img8 : Astr8;
      Img5 : Astr5;
      V : constant Integer_16 := To_I16 (Value);
   begin
      if V < 0 then
         AVR.Int_Img.U16_Img_Right (Unsigned_16 (-V), Img5);
      else
         AVR.Int_Img.U16_Img_Right (Unsigned_16 (V), Img5);
      end if;
      Img8 (8) := '0';
      Img8 (7) := Img5 (5);
      Img8 (6) := Img5 (4);
      Img8 (5) := '.';
      Img8 (4) := Img5 (2);
      Img8 (3) := Img5 (1);
      Img8 (2) := ' ';
      Img8 (1) := ' ';
      return Img8;
   end Image_Full;


   --  return the textual represenation right adjusted (0 .. 99)
   function Image (Value : Humidity_Percentage) return AStr3
   is
      Img3 : AStr3;
   begin
      AVR.Int_Img.U8_Img_Right (Unsigned_8 (Value), Img3);
      return Img3;
   end Image;



end SHT.Images;
