with AVR.MCU;                      use AVR;
with Pulses;
with Modes;

procedure Main is
begin
   --  run at half the speed of the internal oscillator
   MCU.CLKPR_Bits := (MCU.CLKPCE_Bit => High, others => Low);
   MCU.CLKPR_Bits := (MCU.CLKPS0_Bit => High, others => Low);
   loop
      Modes.Manage_Mode;
   end loop;
end Main;
