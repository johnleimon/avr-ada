with Interfaces;                   use Interfaces;
package Pulses.Limits is

   Dummy : Unsigned_16;

   Low    : Unsigned_8 := 30;
   High   : Unsigned_8 := 253;
   Mode_1 : Unsigned_8 := 170;
   Mode_2 : Unsigned_8 := 210;

private
   pragma Linker_Section (Dummy,  ".eeprom");
   pragma Linker_Section (Low,    ".eeprom");
   pragma Linker_Section (High,   ".eeprom");
   pragma Linker_Section (Mode_1, ".eeprom");
   pragma Linker_Section (Mode_2, ".eeprom");
end Pulses.Limits;
