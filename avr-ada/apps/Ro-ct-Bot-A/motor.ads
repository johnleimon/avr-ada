--      High-Level Routinen fuer die Motorsteuerung des c't-Bots

with Interfaces;                   use Interfaces;

package Motor is


   subtype Ext_Speed_T is Integer_16 range -256 .. 256;
   subtype Speed_T is Ext_Speed_t range -255 .. 255;

   Bot_Speed_Stop   : constant Speed_T :=   0; --  Motor off
   Bot_Speed_Slow   : constant Speed_T :=  10; --  langsame Fahrt
   Bot_Speed_Normal : constant Speed_T :=  50; --  normale Fahrt
   Bot_Speed_Fast   : constant Speed_T := 150; --  schnelle Fahrt
   Bot_Speed_Max    : constant Speed_T := 255; --  maximale Fahrt
   Bot_Speed_Ignore : constant         := 256; --  ignore speed


   function Speed_L return Speed_T; --  Geschwindigkeit des linken Motors
   function Speed_R return Speed_T; --  Geschwindigkeit des rechten Motors


   --  Initialisiere den Motorkrams
   procedure Init;


   -- Zugriff auf den Motor
   -- @param left  Geschwindigkeit fuer den linken Motor
   -- @param right Geschwindigkeit fuer den rechten Motor
   -- zwischen -255 und +255;
   -- 0 bedeutet Stillstand, 255 volle Kraft voraus, -255 volle Kraft zurueck
   -- Sinnvoll ist die Verwendung der Konstanten: BOT_SPEED_XXX,
   -- also z.B. motor_set(BOT_SPEED_LOW,-BOT_SPEED_LOW);
   -- fuer eine langsame Drehung
   procedure Set (Left : Speed_T; Right : Speed_T);

private
   pragma Inline (Speed_L);
   pragma Inline (Speed_R);
end Motor;
