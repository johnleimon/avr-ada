separate (Debug)
procedure Init is
begin
   U.Init (25, Double_Speed => False);
   Put_Line ("debug channel initialized");
end Init;


--  25  -->  38400Bd @ 16 MHz
--  25  -->  28800Bd @ 12 MHz
--  25  -->  19200Bd @  8 MHz
--  25  -->   2400Bd @  1 MHz
