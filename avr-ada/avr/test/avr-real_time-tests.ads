with AUnit.Test_Cases;
use AUnit.Test_Cases;

package AVR.Real_Time.Tests is

   type Test_Case is new AUnit.Test_Cases.Test_Case with record
      t : time;
   end record;


   procedure Register_Tests (T : in out Test_Case);
   --  Register routines to be run

   function Name (T : Test_Case) return String_Access;
   --  Returns name identifying the test case

end AVR.Real_Time.Tests;
