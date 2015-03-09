with AUnit.Test_Suites;            use AUnit.Test_Suites;
with AVR.Int_Img.Tests;
with AVR.Int_Val.Tests;
with AVR.Real_Time.Tests;
with AVR.Strings.C.Tests;

function AVR_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Real_Time.Tests.Test_Case);
   Add_Test (Result, new AVR.Int_Img.Tests.Test_Case);
   Add_Test (Result, new AVR.Int_Val.Tests.Test_Case);
   Add_Test (Result, new AVR.Strings.C.Tests.Test_Case);
   return Result;
end AVR_Suite;
