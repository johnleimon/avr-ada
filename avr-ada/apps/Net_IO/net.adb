with AVR.Int_Img;

package body Net is

   function IP_Addr (A, B, C, D : Unsigned_8) return IP_Addr_Type
   is
   begin
      return IP_Addr_Type'(1 => A, 2 => B, 3 => C, 4 => D);
   end IP_Addr;


   function Image (IP : IP_Addr_Type) return AStr15
   is
      use AVR.Int_Img;
      Img : AStr15;
   begin
      Img (4) := '.';
      Img (8) := '.';
      Img (12) := '.';
      U8_Img_Right (IP (1), Img (1..3));
      U8_Img_Right (IP (2), Img (5..7));
      U8_Img_Right (IP (3), Img (9..11));
      U8_Img_Right (IP (4), Img (13..15));
      return Img;
   end Image;


   function Are_Equal (Left, Right, Mask : IP_Addr_Type) return Boolean
   is
   begin
      for I in Left'Range loop
         if (Left(I) and Mask(I)) /= (Right(I) and Mask(I)) then
            return False;
         end if;
      end loop;
      return True;
   end Are_Equal;


   function MAC_Addr (A, B, C, D, E, F : Unsigned_8) return MAC_Addr_Type
   is
   begin
      return MAC_Addr_Type'(1 => A, 2 => B, 3 => C, 4 => D, 5 => E, 6 => F);
   end MAC_Addr;


   function Image (MAC : MAC_Addr_Type) return AStr17
   is
      Img : AStr17;
      L   : Unsigned_8;
      H   : Unsigned_8;
   begin
      Img  (3) := '-';
      Img  (6) := '-';
      Img  (9) := '-';
      Img (12) := '-';
      Img (15) := '-';
      for B in MAC'Range loop
         L := 3 * (B-1) + 1;
         H := L + 1;
         AVR.Int_Img.U8_Hex_Img (MAC (B), Img (L..H));
      end loop;
      return Img;
   end Image;


   function HtoN_16 (Value : Unsigned_16) return U16_NBO
   is
   begin
      return U16_NBO (To_16HBO (Value));
   end HtoN_16;


   function NtoH_16 (Value : U16_NBO) return Unsigned_16
   is
   begin
      return To_U16 (U16_HBO (Value));
   end NtoH_16;


   function HtoN_32 (Value : Unsigned_32) return U32_NBO
   is
   begin
      return U32_NBO (To_32HBO (Value));
   end HtoN_32;


   function NtoH_32 (Value : U32_NBO) return Unsigned_32
   is
   begin
      return To_U32 (U32_HBO (Value));
   end NtoH_32;


end Net;
