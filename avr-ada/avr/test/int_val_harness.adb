with AUnit.Test_Runner;
with Int_Val_Suite;

procedure Int_Val_Harness is

   procedure Run is new AUnit.Test_Runner (Int_Val_Suite);

begin
   Run;
end Int_Val_Harness;
