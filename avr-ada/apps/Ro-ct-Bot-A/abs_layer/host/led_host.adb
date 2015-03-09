--      Routinen zur LED-Steuerung

with Interfaces;                   use Interfaces;

package body LED is


   Status : Unsigned_8;


   --!
   -- Initialisiert die LEDs
   --
   procedure Init
   is
   begin
      Off (LED_ALL);
   end Init;


   --!
   -- Zeigt eine 8-Bit Variable mit den LEDs an
   --
   procedure Set (LED : Unsigned_8)
   is
   begin
      null;
   end Set;


   --! Schaltet eine LED aus
   procedure Off (LED : Unsigned_8)
   is
   begin
      null;
   end Off;


   --! Schaltet eine LED an
   procedure On (LED : Unsigned_8)
   is
   begin
      null;
   end On;

end LED;
