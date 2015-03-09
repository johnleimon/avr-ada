with AUnit.Test_Suites; use AUnit.Test_Suites;
with AVR.Strings.Edit.Tests;
with AVR.Strings.Edit.Integers.Tests;

function Edit_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new AVR.Strings.Edit.Tests.Test_Case);
   Add_Test (Result, new AVR.Strings.Edit.Integers.Tests.Test_Case);
   return Result;
end Edit_Suite;
