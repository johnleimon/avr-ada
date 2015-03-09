with AUnit.Test_Cases.Registration;use AUnit.Test_Cases.Registration;
with AUnit.Assertions;             use AUnit.Assertions;
with Interfaces;                   use Interfaces;


package body AVR.Int_Val.Tests is

   procedure Test_U8_Val2 (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      AImg : AStr2;
      Val : Unsigned_8;

      procedure Check (V : Unsigned_8) is
         Img : constant String := V'Img;
      begin
         Aimg(1) := Img(2);
         Aimg(2) := Img(3);
         Val := U8_Value_Str2 (AImg);
         Assert (Val = V, "u8_val2("&Img&")");
      end Check;
   begin
      Check (13);
      Check (99);
      Check (42);
      Check (64);
      AImg := " 4";
      Val := U8_Value_Str2 (AImg);
      Assert (Val = 4, "u8_val2(4)");
      AImg := "  ";
      Val := U8_Value_Str2 (AImg);
      Assert (Val = 0, "u8_val2(0)");
   end Test_U8_Val2;


   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("String to Integer functions");
   end Name;


   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_U8_Val2'Access, "test U8_Val2");
   end Register_Tests;

end AVR.Int_Val.Tests;
