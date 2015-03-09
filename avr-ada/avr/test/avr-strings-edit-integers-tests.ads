with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with AUnit.Test_Cases;
use AUnit.Test_Cases;

package AVR.Strings.Edit.Integers.Tests is

   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test_Case);
   --  Register routines to be run

   function Name (T : Test_Case) return String_Access;
   --  Returns name identifying the test case

end AVR.Strings.Edit.Integers.Tests;
