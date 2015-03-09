with AUnit.Test_Cases.Registration;
use AUnit.Test_Cases.Registration;

with AUnit.Assertions; use AUnit.Assertions;

with AVR.Strings.Edit.Generic_Integers;


package body AVR.Strings.Edit.Integers.Tests is


   procedure Test_Get (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Val_U32 : Unsigned_32;
      Val_I16 : Integer_16;
   begin
      Input_Line := "  23 -23 Ff aAbB 85 101 -25543";
      --             123456789012345678901234567890
      --             000000000111111111122222222223
      Input_Ptr  := 1;
      Input_Last := 30;
      Skip;
      Get (Val_U32, 10);
      Assert (Input_Ptr = 5, "get 23, input_ptr ="&Input_Ptr'Img);
      Assert (Val_U32 = 23, "get 23:" & Val_U32'Img);
      Skip;
      Get (Val_I16);
      Assert (Input_Ptr = 9, "get -23, input_ptr ="&Input_Ptr'Img);
      Assert (Val_I16 = -23, "get -23:" & Val_U32'Img);

   end Test_Get;


   procedure Test_Put_U32 (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      use AVR.Strings.Edit.Generic_Integers;
      Img : AStr11;
      L   : Unsigned_8;
   begin
      Put_U32 (16, 16, Img, L);
      Assert (L = 3, "put_u32: last ="&L'img);
      Assert (Img(2..3) = "10", "put_32: img(16, 16)");
   end Test_Put_U32;


   procedure Test_Put_U (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
   begin
      Output_Last := 1;
      Put (Unsigned_8 (35), 16);
      Assert (Output_Line (1..2) = "23", "put unsigned 33:" & Output_Line(1) & Output_Line(2));
      Put (Unsigned_8 (123), 10, Field => 10, Justify => Right);
      Assert (Output_Line (3..12) = "       123", "put unsigned 123");
   end Test_Put_U;


   procedure Test_Put_I (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
   begin
      Output_Last := 1;
      Put (Integer_8 (31));
      Assert (Output_Line (1..2) = "31", "put signed 31:" & Output_Line(1) & Output_Line(2));
      Put (Integer_16 (-26262));
      Assert (Output_Line (3..8) = "-26262", "put signed -26262:");
   end Test_Put_I;


   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("integer edit functions");
   end Name;


   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Get'Access, "test Get");
      Register_Routine (T, Test_Put_U32'Access, "test Put_U32");
      Register_Routine (T, Test_Put_U'Access, "test Put_U");
      Register_Routine (T, Test_Put_I'Access, "test Put_I");
   end Register_Tests;

end AVR.Strings.Edit.Integers.Tests;
