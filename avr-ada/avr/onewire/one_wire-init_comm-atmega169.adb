with AVR.MCU;

separate (One_Wire)
procedure Init_Comm is
begin
   AVR.Interrupts.Disable_Interrupts;

   --  save old prescaler value
   Standard_Prescaler := MCU.CLKPR;

   --  The CLKPCE bit must be written to logic one to enable change
   --  of the CLKPS bits. The CLKPCE bit is only updated when the
   --  other bits in CLKPR are simultaneously written to zero.
   --  (atmega169 datasheet page 31)
   MCU.CLKPR := 16#80#;
   --  Within four cycles, write the desired value to CLKPS while
   --  writing a zero to CLKPCE.  Set all CLKPS bits to zero,
   --  resulting in a clock devision factor of 0, i.e. keep the
   --  8MHz standard frequency.
   MCU.CLKPR := 16#00#;

end Init_Comm;
