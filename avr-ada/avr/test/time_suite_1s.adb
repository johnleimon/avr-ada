with AUnit.Test_Suites;            use AUnit.Test_Suites;
with AVR.Real_Time.Tests_1s;

function Time_Suite_1s return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Real_Time.Tests_1s.Test_Case);
   return Result;
end Time_Suite_1s;
