--      Routinen fuer die Servos des c't-Bots

with Interfaces;                   use Interfaces;

package Servos is

   LEFT_Pos  : constant := 8;
   RIGHT_Pos : constant := 16;

   subtype Position_T is Unsigned_8 range Left_Pos .. Right_Pos;
   Middle_Pos : constant Position_T := (Right_Pos + Left_Pos)/2;


   subtype Index_T is Unsigned_8 range 1 .. 2;
   Servo_Klappe : constant Index_T := 1;

   --!
   --  Initialisiert alles fuer die Servos
   --/
   procedure Init;

   --!
   -- Stellt die Servos.
   -- Sinnvolle Werte liegen zwischen 8 und 16
   --/
   procedure Set (Servo : Index_T; Pos : Position_T);

end Servos;
