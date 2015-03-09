--       Low-Level Routinen fuer die Motorsteuerung des c't-Bots

with Commands;
with Bot_2_Sim;

package body Motor.Low is


   --  Initilisiert alles fuer die Motosteuerung
   procedure Init is
   begin
      null;
   end Init;


   -- Unmittelbarer Zugriff auf die beiden Motoren,
   -- normalerweise NICHT verwenden!
   -- @param left PWM links
   -- @param right PWM rechts
   procedure Set (Left : Integer_16; Right : Integer_16)
   is
   begin
      Bot_2_Sim.Tell (Commands.CMD_AKT_MOT, Commands.SUB_CMD_NORM,
                      Left, Right);
   end Set;


end Motor.Low;
