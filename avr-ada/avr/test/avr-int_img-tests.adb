with AUnit.Test_Cases.Registration;
use AUnit.Test_Cases.Registration;

with AUnit.Assertions; use AUnit.Assertions;

with Interfaces;      use Interfaces;


package body AVR.Int_Img.Tests is

   procedure Test_Nibble_Hex_Img (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      C : Character;
   begin
      Nibble_Hex_Img (0, C);
      Assert (C = '0', "test 0");
      Nibble_Hex_Img (1, C);
      Assert (C = '1', "test 1");
      Nibble_Hex_Img (9, C);
      Assert (C = '9', "test 9");
      Nibble_Hex_Img (10, C);
      Assert (C = 'A', "test 10");
      Nibble_Hex_Img (15, C);
      Assert (C = 'F', "test 15");
   end Test_Nibble_Hex_Img;

   procedure Test_U8_Img_Right (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr3;
   begin
      U8_Img_Right (0, Img);
      Assert (Img = "  0", "test 0");
      U8_Img_Right (8, Img);
      Assert (Img = "  8", "test 8");
      U8_Img_Right (22, Img);
      Assert (Img = " 22", "test 22");
      U8_Img_Right (255, Img);
      Assert (Img = "255", "test 255");
      U8_Img_Right (199, Img);
      Assert (Img = "199", "test 199");
   end Test_U8_Img_Right;

   procedure Test_U8_Img (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr3;
      L   : Unsigned_8;
   begin
      U8_Img (0, Img, L);
      Assert (L = 1, "test 0,"&L'Img);
      Assert (Img(1..L) = "0", "test 0,");
      U8_Img (8, Img, L);
      Assert (Img(1..L) = "8", "test 8");
      U8_Img (22, Img, L);
      Assert (Img(1..L) = "22", "test 22");
      U8_Img (255, Img, L);
      Assert (Img(1..L) = "255", "test 255");
      U8_Img (199, Img, L);
      Assert (Img(1..L) = "199", "test 199");
      U8_Img (100, Img, L);
      Assert (Img(1..L) = "100", "test 100");
   end Test_U8_Img;

   procedure Test_U16_Img (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr5;
      L   : Unsigned_8;
   begin
      U16_Img (0, Img, L);
      Assert (Img(1..L) = "0", "test 0");
      U16_Img (10, Img, L);
      Assert (Img(1..L) = "10", "test 10");
      U16_Img (100, Img, L);
      Assert (Img(1..L) = "100", "test 100");
      U16_Img (1000, Img, L);
      Assert (Img(1..L) = "1000", "test 1000");
      U16_Img (10000, Img, L);
      Assert (Img(1..L) = "10000", "test 10000");
      U16_Img (59999, Img, L);
      Assert (Img(1..L) = "59999", "test 59999");
      U16_Img (65535, Img, L);
      Assert (Img(1..L) = "65535", "test 65535");
   end Test_U16_Img;

   procedure Test_U16_Img_Right (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr5;
   begin
      U16_Img_Right (0, Img);
      Assert (Img = "    0", "test 0");
      U16_Img_Right (1, Img);
      Assert (Img = "    1", "test 1");
      U16_Img_Right (10, Img);
      Assert (Img = "   10", "test 10");
      U16_Img_Right (100, Img);
      Assert (Img = "  100", "test 100");
      U16_Img_Right (255, Img);
      Assert (Img = "  255", "test 255");
      U16_Img_Right (256, Img);
      Assert (Img = "  256", "test 256");
      U16_Img_Right (999, Img);
      Assert (Img = "  999", "test 999");
      U16_Img_Right (1000, Img);
      Assert (Img = " 1000", "test 1000");
      U16_Img_Right (10000, Img);
      Assert (Img = "10000", "test 10000");
      U16_Img_Right (59999, Img);
      Assert (Img = "59999", "test 59999");
      U16_Img_Right (65535, Img);
      Assert (Img = "65535", "test 65535");
   end Test_U16_Img_Right;


   procedure Test_U32_Img (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      procedure Check (Val : Unsigned_32)
      is
         Img : AStr10;
         L   : Unsigned_8;
         Val_Img : constant String := Val'Img;
      begin
         U32_Img (Val, Img, L);
         for C in 1 .. L loop
            Assert (Img(C) = Val_Img (1+Integer(C)), "test"&Val_Img);
         end loop;
      end Check;

   begin
      for I in Unsigned_32'(0) .. 1000 loop
         Check (I);
      end loop;
      Check (12_345);
      Check (678_901);
      Check (1_234_567);
      Check (22_234_567);
      Check (333_234_567);
      Check (2_345_678_901);
      Check (Unsigned_32'Last);
      Check (Unsigned_32'Last-1);
   end Test_U32_Img;

   procedure Test_U8_Img_99_Right (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr2;
   begin
      for D in Unsigned_8'(0) .. 99 loop
         U8_Img_99_Right (D, Img);
         declare
            D_Img : String := D'Img;
         begin
            if D < 10 then
               D_Img (1) := '0';
            else
               D_Img (1) := D_Img (2);
               D_Img (2) := D_Img (3);
            end if;
            Assert (Img(1) = D_Img (1), "test1,"&D_Img(1..2));
            Assert (Img(2) = D_Img (2), "test2,"&D_Img(1..2));
         end;
      end loop;
   end Test_U8_Img_99_Right;

   procedure Test_U8_Hex_Img (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Img : AStr2;
   begin
      U8_Hex_Img (10, Img);
      Assert (Img = "0A", "test 10");
      U8_Hex_Img (64, Img);
      Assert (Img = "40", "test 64");
      U8_Hex_Img (85, Img);
      Assert (Img = "55", "test 85");
      U8_Hex_Img (170, Img);
      Assert (Img = "AA", "test 170");
      U8_Hex_Img (255, Img);
      Assert (Img = "FF", "test 255");
   end Test_U8_Hex_Img;

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Integer Image functions");
   end Name;


   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Nibble_Hex_Img'Access, "test Nibble_Hex_Img");
      Register_Routine (T, Test_U8_Img'Access, "test U8_Img");
      Register_Routine (T, Test_U8_Img_Right'Access, "test U8_Img_Right");
      Register_Routine (T, Test_U16_Img'Access, "test U16_Img");
      Register_Routine (T, Test_U16_Img_Right'Access, "test U16_Img_Right");
      Register_Routine (T, Test_U32_Img'Access, "test U32_Img");
      Register_Routine (T, Test_U8_Img_99_Right'Access,
                        "test U8_Img_99_Right");
      Register_Routine (T, Test_U8_Hex_Img'Access, "test U8_Hex_Img");
   end Register_Tests;

end AVR.Int_Img.Tests;
