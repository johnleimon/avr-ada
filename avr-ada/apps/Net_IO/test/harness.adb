with AUnit.Test_Runner;
with Net_Read_Suite;

procedure Harness is

   procedure Run is new AUnit.Test_Runner (Net_Read_Suite);

begin
   Run;
end Harness;
