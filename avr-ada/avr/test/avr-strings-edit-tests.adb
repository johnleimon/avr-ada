with Gnat.IO;
with AUnit.Test_Cases.Registration;
use AUnit.Test_Cases.Registration;

with AUnit.Assertions; use AUnit.Assertions;



package body AVR.Strings.Edit.Tests is

   procedure Test_Get_Str (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Word : Edit_String;
   begin
      Input_Line := "     Toto@@@Tata sdfsdf sdf sd";
      --             123456789012345678901234567890
      --             000000000111111111122222222223
      Input_Ptr  := 1;
      Input_Last := 30;

      Skip (' ');
      Word := Get_Str ('@');
      Assert (Edit.First(Word) = 6, "first of Toto");
      Assert (Last(Word) = 9, "last of Toto");
      Skip ('@');
      Word := Get_Str;
      Assert (First(Word) = 13, "first of Tata");
      Assert (Last(Word) = 16, "last of Tata");
      Word := Get_Str;
      Assert (First(Word) = 18, "first of sdfsdf");
      Assert (Last(Word) = 23, "last of sdfsdf");
      Word := Get_Str;
      Assert (First(Word) = 25, "first of sdf");
      Assert (Last(Word) = 27, "last of sdf");
      Word := Get_Str;
      Assert (First(Word) = 29, "first of sd");
      Assert (Last(Word) = 30, "last of sd");

      Input_Ptr  := 1;
      Skip;
      Assert (Input_Ptr = 6, "skip to Toto");
      Get_Str ('@');
      Assert (Input_Ptr = 10, "get Toto");
   end Test_Get_Str;


   procedure Test_Put_Char (T : in out AUnit.Test_Cases.Test_Case'Class)
   is

      Start : Edit_Index_T;
   begin
      Output_Last := 1;
      Put ('s');
      Assert (Output_Last = 2, "put char last");
      Assert (Output_Line(1) = 's', "put char value");

      Put ('d', Field => 5, Justify => Left, Fill => '@');
      Assert (Output_Last = 7, "put char last with field"&Output_Last'Img);
      Assert (Output_Line(2..6) = "d@@@@", "put char values" );

      Put (' ');
      Assert (Output_Last = 8, "put char last");
      Assert (Output_Line(7) = ' ', "put char value");

      Put ('d', Field => 5, Justify => Right, Fill => '@');
      Assert (Output_Last = 13, "put char last with field");
      Assert (Output_Line(8..12) = "@@@@d", "put char values");


   end Test_Put_Char;


   procedure Test_Put_String (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Start : Edit_Index_T;
   begin
      Output_Last := 1;
      Put ("12345");
      Assert (Output_Last = 6, "put string last");
      Assert (Output_Line(1..5) = "12345", "put string value");

      Put ("12345", Field => 10);
      Assert (Output_Last = 16, "put string field last");
      Assert (Output_Line(6..15) = "12345     ", "put string field value");

      Put ("12345", Field => 10, Justify => Right, Fill => '@');
      Assert (Output_Last = 26, "put string field right last");
      Assert (Output_Line(16..25) = "@@@@@12345", "put string field right value");

   end Test_Put_String;


   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("string edit functions");
   end Name;


   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Get_Str'Access, "test Get_Str");
      Register_Routine (T, Test_Put_Char'Access, "test Put_Char");
      Register_Routine (T, Test_Put_String'Access, "test Put_String");
   end Register_Tests;

end AVR.Strings.Edit.Tests;
