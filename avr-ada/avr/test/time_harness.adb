with AUnit.Test_Runner;
with Time_Suite;

procedure Time_Harness is

   procedure Run is new AUnit.Test_Runner (Time_Suite);

begin
   Run;
end Time_Harness;
