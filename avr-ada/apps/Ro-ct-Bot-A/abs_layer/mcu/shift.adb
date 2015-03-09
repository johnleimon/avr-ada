--      Routinen zur Ansteuerung der Shift-Register

with Interfaces;
with AVR;
with AVR.MCU;
with AVR.IO;

package body Shift is


   -- Alle Pins, die Ausgänge sind
   SHIFT_OUT  : constant            := 16#1F#;
   -- Port, an dem die Register haengen
   SHIFT_PORT : constant AVR.IO_Address := AVR.MCU.PORTC;
   -- DDR des Ports, an dem die Register haengen
   SHIFT_DDR  : constant AVR.IO_Address := AVR.MCU.DDRC;


   --!
   -- reset shift-registers
   --/
   procedure Clear
   is
      use AVR.IO;
   begin
      Set (Shift_Port, Get (Shift_Port) and not Shift_Out); -- to zero
   end Clear;


   --!
   -- Initialisert die Shift-Register
   --/
   procedure Init
   is
      use AVR.IO;
   begin
      Set (Shift_DDR, Get (Shift_DDR) or Shift_Out); -- set output direction
      Clear;
   end Init;


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
                       Latch_Store : Unsigned_8)
   is
      use AVR.IO;
      D : Unsigned_8 := Data;
   begin
      Clear;
      for I in AVR.Bit_Number loop
         --  get the top bit of Data to the data line of the shift register
         Set (Shift_Port, Get (Shift_Port) or (Shift_Right (D, 7) and 1));
         Set (Shift_Port, Get (Shift_Port) or Latch_Data);
         D := Shift_Left (D, 1);
         Clear;
      end loop;
      -- latch all from storage to output
      Set (Shift_Port, Get (Shift_Port) or Latch_Store);
   end Data_Out;


   --!
   -- Schiebt Daten durch eines der drei 74HC595-Schieberegister,
   -- vereinfachte Version, braucht kein Clear.
   -- Funktioniert NICHT fuer das Shift-Register, an dem das Display haengt!!!
   -- @param data       Das Datenbyte
   --  @param latch_data der Pin, an dem der Daten-latch-Pin des
   --  Registers (PIN 11) haengt
   procedure Shift_Data (Data : Unsigned_8; Latch_Data : Unsigned_8)
   is
   begin
      Data_Out (Data, Latch_Data, Latch);
      Clear;
   end Shift_Data;


end Shift;
