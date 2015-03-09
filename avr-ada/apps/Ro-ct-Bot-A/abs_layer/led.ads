--      Routinen zur LED-Steuerung

with Interfaces;                   use Interfaces;

package LED is

   LED_RECHTS  : constant Unsigned_8 := 2**0;
   LED_LINKS   : constant Unsigned_8 := 2**1;
   LED_ROT     : constant Unsigned_8 := 2**2;
   LED_ORANGE  : constant Unsigned_8 := 2**3;
   LED_GELB    : constant Unsigned_8 := 2**4;
   LED_GRUEN   : constant Unsigned_8 := 2**5;
   LED_TUERKIS : constant Unsigned_8 := 2**6;
   LED_WEISS   : constant Unsigned_8 := 2**7;

   LED_ALL     : constant Unsigned_8 := 16#FF#;


   --!
   -- Initialisiert die LEDs
   --
   procedure Init;

   --!
   -- Zeigt eine 8-Bit Variable mit den LEDs an
   -- @param LED Wert der gezeigt werden soll
   --
   procedure Set (LED : Unsigned_8);

   --! Schaltet eine LED aus
   --
   -- @param LED HEX-Code der LED
   --
   procedure Off (LED : Unsigned_8);

   --! Schaltet eine LED an
   --
   -- @param LED HEX-Code der LED
   --
   procedure On (LED : Unsigned_8);

private
   pragma Inline (Set);
end LED;
