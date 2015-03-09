with AUnit.Test_Suites; use AUnit.Test_Suites;
with AVR.Real_Time.Tests;

function Time_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Real_Time.Tests.Test_Case);
   return Result;
end Time_Suite;
