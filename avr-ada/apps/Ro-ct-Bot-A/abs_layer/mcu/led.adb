--      Routinen zur LED-Steuerung

with Interfaces;                   use Interfaces;
with Shift;

package body LED is


   Led_Status : Unsigned_8 := 0;

   --!
   -- Initialisiert die LEDs
   --
   procedure Init
   is
   begin
      Shift.Init;
      Off (LED_ALL);
   end Init;


   --!
   -- Zeigt eine 8-Bit Variable mit den LEDs an
   -- @param LED Wert der gezeigt werden soll
   --
   procedure Set (LED : Unsigned_8)
   is
   begin
      Led_Status := LED;
      Shift.Data (Led_Status, Shift.LED_Register);
   end Set;


   --! Schaltet eine LED aus
   --
   -- @param LED HEX-Code der LED
   --
   procedure Off (LED : Unsigned_8)
   is
   begin
      Led_Status := Led_Status and not LED;
      Set (Led_Status);
   end Off;


   --! Schaltet eine LED an
   --
   -- @param LED HEX-Code der LED
   --
   procedure On (LED : Unsigned_8)
   is
   begin
      Led_Status := Led_Status or LED;
      Set (Led_Status);
   end On;


end LED;
