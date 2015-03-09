--      High-Level-Routinen fuer die Motorsteuerung des c't-Bot

with Motor.Low;

package body Motor is


   Local_Speed_L : Speed_T; --  Geschwindigkeit des linken Motors
   Local_Speed_R : Speed_T; --  Geschwindigkeit des rechten Motors


   --!
   -- Direkter Zugriff auf den Motor
   -- @param left  Geschwindigkeit fuer den linken Motor
   -- @param right Geschwindigkeit fuer den rechten Motor
   -- Geschwindigkeit liegt zwischen -255 und +255.
   -- 0 bedeutet Stillstand, 255 volle Kraft voraus, -255 volle Kraft zurueck.
   -- Sinnvoll ist die Verwendung der Konstanten: BOT_SPEED_XXX,
   -- also z.B. motor_set(BOT_SPEED_LOW,-BOT_SPEED_LOW);
   -- fuer eine langsame Drehung

   procedure Set (Left : Speed_T; Right : Speed_T)
   is
      procedure Validate_Speed (S : Speed_T; Vald : out Speed_T) is
      begin
         if S = 0  then
            -- Stop wird nicht veraendert
            Vald := BOT_SPEED_STOP;

         elsif abs (S) < BOT_SPEED_SLOW then
            -- Nicht langsamer als die Motoren koennen
            Vald := BOT_SPEED_SLOW;
            if S < 0 then
               Vald := - Vald;
            end if;

         else
            -- Sonst den Wunsch uebernehmen
            Vald := S;
         end if;

      end Validate_Speed;

   begin
      Validate_Speed (Left,  Local_Speed_L);
      Validate_Speed (Right, Local_Speed_R);

      Motor.Low.Set (Local_Speed_L, Local_Speed_R);
   end Set;


   function Speed_L return Speed_T is
   begin
      return Local_Speed_L;
   end Speed_L;


   function Speed_R return Speed_T is
   begin
      return Local_Speed_R;
   end Speed_R;


   --!
   -- Initialisiere den Motorkrams
   --/
   procedure Init
   is
   begin
      Local_Speed_L := 0;
      Local_Speed_R := 0;
      Motor.Low.Init;
   end Init;

end Motor;
