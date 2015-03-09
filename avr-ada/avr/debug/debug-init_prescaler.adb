with AVR.MCU;

separate (Debug)
procedure Init is
   --  Baudrate : constant := 12; --  9600bps @ 1MHz, u2x = 1 => 19200bps
   --  Baudrate : constant := 51; --  9600bps @ 8MHz, u2x = 1 => 19200bps
   use AVR.MCU;
   Prescaler : Unsigned_8;
begin
   --  determine clock frequency by reading the MCU.  Assumes
   --  setting correspinding in one of the init (.init8) sections.
   Prescaler := MCU.CLKPR;
   
   if Prescaler = (MCU.CLKPS1_Mask or MCU.CLKPS0_Mask) then
      -- Clock_Frequency = 1_000_000
      U.Init (12, Double_Speed => True);
   elsif Prescaler = 0 then
      -- Clock_Frequency = 8_000_000
      U.Init (51, Double_Speed => True);
   else
      U.Init (12, Double_Speed => False);
   end if;
   Put ("debug channel initialized at ");
   Put ("19200 Bd");
   New_Line;
end Init;
