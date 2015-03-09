with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.MCU;
with AVR.Timer0;
with AVR.Ext_Int;
with AVR.EEPROM;

with Modes;
with Limits;
with Pins;

package body Pulses is

   --  boundary values will be stored in EEPROM.  We now define them
   --  as constants.
   Low_Limit    : constant Unsigned_8 := Eeprom.Get (Limits.Low'Address);
   High_Limit   : constant Unsigned_8 := Eeprom.Get (Limits.High'Address);
   Mode_1_Limit : constant Unsigned_8 := Eeprom.Get (Limits.Mode_1'Address);
   Mode_2_Limit : constant Unsigned_8 := Eeprom.Get (Limits.Mode_2'Address);


   procedure Pin_Change_Interrupt;
   pragma Machine_Attribute (Entity         => Pin_Change_Interrupt,
                             Attribute_Name => "signal");
   pragma Export (Convention    => C,
                  Entity        => Pin_Change_Interrupt,
                  External_Name => MCU.Sig_PCINT0_String);

   procedure Pin_Change_Interrupt is
      use Pins;
      Pulse_Length : Unsigned_8;
   begin
      if Rx_Signal = High then
         MCU.TCNT0 := 0;
      else
         Pulse_Length := MCU.TCNT0;

         if Pulse_Length < Low_Limit or else Pulse_Length > High_Limit then
            null;
            -- error case, report it somehow
         elsif Pulse_Length < Mode_1_Limit then
            Modes.Mode := 0;
         elsif Pulse_Length < Mode_2_Limit then
            Modes.Mode := 1;
         else
            Modes.Mode := 2;
         end if;
      end if;
   end Pin_Change_Interrupt;


   procedure Init is
      use AVR.Ext_Int;
   begin
      Timer0.Init_Normal (Timer0.Scale_By_64);
      -- enable interrupts, configure pin change interrupt
      Enable_External_Interrupt_0;
      Set_Int0_Sense_Control (Toggle);
   end Init;


begin
   Init;
end Pulses;
