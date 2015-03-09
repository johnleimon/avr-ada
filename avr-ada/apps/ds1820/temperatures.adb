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
with AVR;                          use AVR;
with AVR.Int_Img;

package body Temperatures is


   function To_U16 is
      new Ada.Unchecked_Conversion (Source => Temperature_12bit,
                                    Target => Nat16);

   function To_U16 is
      new Ada.Unchecked_Conversion (Source => Temperature_9bit,
                                    Target => Nat16);

   function To_T12 is
      new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                    Target => Temperature_12bit);

   function To_T9 is
      new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                    Target => Temperature_9bit);

   function To_Temperature_12bit (Raw : Unsigned_16) return Temperature_12bit
   is
   begin
      return To_T12 (Raw);
   end;

   function To_Temperature_9bit (Raw : Unsigned_16) return Temperature_9bit
   is
   begin
      return To_T9 (Raw);
   end;

   --  set the decimal point to the last element in Image and generate
   --  a textual representation of the decimal value.  Prepend a minus
   --  sign if necessary.  We know that the data values are in the
   --  range of -55 .. 125.
   function Image (Value : Temperature_9bit) return AStr5
   is
      Img         : AStr5;
      Is_Negative : constant Boolean := Value < 0.0;
      D           : Nat8;
   begin
      --  integer part
      if Is_Negative then
         D := Nat8 (Shift_Right (To_U16 (- Value), 1));
      else
         D := Nat8 (Shift_Right (To_U16 (Value), 1));
      end if;

      AVR.Int_Img.U8_Img_Right (D, Img (1 .. 3));

      if Is_Negative then
         if D >= 10 then
            Img (1) := '-';
         else
            Img (2) := '-';
         end if;
      end if;

      Img (4) := '.';

      --  fractional part
      if (To_U16 (Value) and 16#0001#) /= 0 then
         Img (5) := '5';
      else
         Img (5) := '0';
      end if;

      return Img;
   end Image;


   --  return the textual representation with one decimal digit, rounded.
   function Image (Value : Temperature_12bit) return AStr5
   is
      Img         : AStr5;
      Is_Negative : constant Boolean := Value < 0.0;
      D           : Nat8;
   begin
      --  first the integer part
      if Is_Negative then
         D := Nat8 (Shift_Right (To_U16 (- Value), 4));
      else
         D := Nat8 (Shift_Right (To_U16 (Value), 4));
      end if;

      AVR.Int_Img.U8_Img_Right (D, Img (1 .. 3));

      if Is_Negative then
         if D >= 10 then
            Img (1) := '-';
         else
            Img (2) := '-';
         end if;
      end if;

      Img (4) := '.';

      -- now calculate the rounded decimal digit after the decimal point
      if Is_Negative then
         D := (Nat8 (To_U16 (- Value) and 16#000F#));
      else
         D := (Nat8 (To_U16 (Value) and 16#000F#));
      end if;

      Img (5) := Character'Val (48 + ((D * 10) + 8) / 16);

      return Img;
   end Image;


   --  return the textual representation with three decimal digit, truncated.
   function Image_Full (Value : Temperature_12bit) return AStr8
   is
      Img : Astr8;
      D : Nat8;
      Di : Nat8;
   begin
      --  reuse the code of the rounded case ignores the calculation
      --  of the 1st decimal digit.
      Img (1 .. 5) := Image (Value);

      D := Nat8 (To_U16 (abs (Value)) and 16#000F#);

      Di := 0;
      for I in Nat8'(1) .. 4 loop
         D  := (D - Di * 16) * 10;
         Di := D / 16;  --  truncating integer division
         Img (4 + I) := Character'Val (48 + Di);
      end loop;

      return Img;
   end Image_Full;


end Temperatures;
