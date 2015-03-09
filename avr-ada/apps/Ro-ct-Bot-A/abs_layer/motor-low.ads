--      Low-Level Routinen fuer die Motorsteuerung des c't-Bots

with Interfaces;                   use Interfaces;

package Motor.Low is

   --!
   --  Initialisiert alles fuer die Motorsteuerung
   --/
   procedure Init;

   
   --!
   -- Unmittelbarer Zugriff auf die beiden Motoren
   --/
   procedure Set (Left : Integer_16; Right : Integer_16);


end Motor.Low;
