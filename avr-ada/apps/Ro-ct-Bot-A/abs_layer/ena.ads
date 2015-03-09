--      Routinen zur Steuerung der Enable-Leitungen

with Interfaces;                   use Interfaces;

package Enable is

   Abstand  : constant := 2 ** 0; -- Enable-Leitung Abstandssensoren
   Radled   : constant := 2 ** 1; -- Enable-Leitung Radencoder
   Schranke : constant := 2 ** 2; -- Enable-Leitung Fachueberwachung
   Kantled  : constant := 2 ** 3; -- Enable-Leitung Angrundsensor
   Klappled : constant := 2 ** 4; -- Enable-Leitung Schieberueberwachung
   Maus     : constant := 2 ** 5; -- Enable-Leitung Maussensor
   Erw1     : constant := 2 ** 6; -- Enable-Leitung Reserve 1
   Erw2     : constant := 2 ** 7; -- Enable-Leitung Reserve 2


   --!
   -- Initialisiert die Enable-Leitungen
   --/
   procedure Init;

   --!
   -- Schaltet einzelne Enable-Leitungen an,
   -- andere werden nicht beeinflusst
   -- @param enable Bitmaske der anzuschaltenden LEDs
   --/
   procedure On (Enable : Unsigned_8);

   --!
   -- Schaltet einzelne Enable-Leitungen aus,
   -- andere werden nicht beeinflusst
   -- @param enable Bitmaske der anzuschaltenden LEDs
   --/
   procedure Off (Enable : Unsigned_8);

   --!
   -- Schaltet die Enable-Leitungen
   -- @param LED Wert der gezeigt werden soll
   --/
   procedure Set (Enable : Unsigned_8);

end Enable;
