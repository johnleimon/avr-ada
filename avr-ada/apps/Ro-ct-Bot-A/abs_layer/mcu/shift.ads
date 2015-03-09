--      Routinen zur Ansteuerung der Shift-Register

with Interfaces;                   use Interfaces;
with AVR;

package Shift is


   LATCH            : constant := 2**1;   -- Clock to store data into shiftregister

   DISPLAY_REGISTER : constant := 16#04#; -- Port-Pin for shiftregister latch (display)
   LED_REGISTER     : constant := 16#10#; -- Port-Pin for shiftregister latch (leds)
   ENA_REGISTER     : constant := 16#08#; -- Port-Pin for shiftregister latch (enable)

   --!
   -- Initialisert die Shift-Register
   --/
   procedure Init;

   --!
   --  Schiebt Daten durch eines der drei 74HC595-Schieberegister
   --  Achtung: den Port sollte man danach noch per Clear
   --  zuruecksetzen!
   --  @param data      Das Datenbyte
   --  @param latch_data der Pin, an dem der Daten-latch-Pin des
   --         Registers (PIN 11) haengt
   --  @param latchtore der Pin, an dem der latch-Pin zum Transfer des
   --         Registers (PIN 12) haengt
   --/
   procedure Data_Out (Data        : Unsigned_8;
                       Latch_Data  : Unsigned_8;
                       Latch_Store : Unsigned_8);

   --!
   -- Schiebt Daten durch eines der drei 74HC595-Schieberegister,
   -- vereinfachte Version, braucht kein Clear.
   -- Funktioniert NICHT fuer das Shift-Register, an dem das Display haengt!!!
   -- @param data       Das Datenbyte
   --  @param latch_data der Pin, an dem der Daten-latch-Pin des
   --  Registers (PIN 11) haengt
   procedure Shift_Data (Data : Unsigned_8; Latch_Data : Unsigned_8);

   --!
   -- Setzt die Shift-Register wieder zurueck
   --/
   procedure Clear;
   
private
   pragma Inline (Clear);
end Shift;
