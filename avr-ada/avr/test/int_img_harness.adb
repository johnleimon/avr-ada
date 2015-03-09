with AUnit.Test_Runner;
with Int_Img_Suite;

procedure Int_Img_Harness is

   procedure Run is new AUnit.Test_Runner (Int_Img_Suite);

begin
   Run;
end Int_Img_Harness;
