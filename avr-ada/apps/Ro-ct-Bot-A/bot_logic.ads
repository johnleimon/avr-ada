--      High-Level-Routinen fuer die Steuerung des c't-Bots

with Motor;

package Bot_Logic is

   Target_Speed_L : Motor.Speed_T; --  Sollgeschwindigkeit des linken Motors
   pragma Volatile (Target_Speed_L);

   Target_Speed_R : Motor.Speed_T; --  Sollgeschwindigkeit des rechten Motors
   pragma Volatile (Target_Speed_R);


   --!
   -- the general behaviour routine,
   --/
   procedure Bot_Behave;


   --  Initialisiere das Verhalten
   procedure Init;


private


end Bot_Logic;
