with AUnit.Test_Suites;            use AUnit.Test_Suites;
with AVR.Int_Val.Tests;

function Int_Val_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Int_Val.Tests.Test_Case);
   return Result;
end Int_Val_Suite;
