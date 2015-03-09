package AVR.Interrupts is
   pragma Preelaborate (AVR.Interrupts);

   -- Enable interrupts
   procedure Sei is null;
   procedure Enable
     renames Sei;
   procedure Enable_Interrupts
     renames Sei;


   -- disable interrupts
   procedure Cli is null;
   procedure Disable
     renames Cli;
   procedure Disable_Interrupts
     renames Cli;

   --  save the status register and and disable interrupts
   function Save_And_Disable return Nat8;

   --  restore the status register, enables interrupts, if they were
   --  enabled at the time the status was saved.
   procedure Restore (Old_Status : Nat8) is null;

   --  return from interrupt
   --  (needed for the implementation of "naked" interrupts)
   -- procedure Return_From_Interrupt;

   --  restart the µC as if powered on
   procedure Reset is null;

private

end AVR.Interrupts;
