with AUnit.Test_Runner;
with Edit_Suite;

procedure Edit_Harness is

   procedure Run is new AUnit.Test_Runner (Edit_Suite);

begin
   Run;
end Edit_Harness;
