with AUnit.Test_Runner;
with Time_Suite_1s;

procedure Time_Harness_1s is

   procedure Run is new AUnit.Test_Runner (Time_Suite_1s);

begin
   Run;
end Time_Harness_1s;
