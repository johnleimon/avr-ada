with AUnit.Test_Runner;
with AVR_Suite;

procedure AVR_Harness is

   procedure Run is new AUnit.Test_Runner (AVR_Suite);

begin
   Run;
end AVR_Harness;
