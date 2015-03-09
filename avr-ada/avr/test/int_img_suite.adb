with AUnit.Test_Suites; use AUnit.Test_Suites;
with AVR.Int_Img.Tests;

function Int_Img_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Int_Img.Tests.Test_Case);
   return Result;
end Int_Img_Suite;
