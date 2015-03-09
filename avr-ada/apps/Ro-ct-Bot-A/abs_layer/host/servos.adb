--       Low-Level Routinen fuer die Motorsteuerung des c't-Bots

with Commands;
with Bot_2_Sim;

package body Servos is


   --  Initilisiert alles fuer die Motosteuerung
   procedure Init is
   begin
      null;
   end Init;


   pragma Warnings (Off);
   procedure Set (Servo : Index_T; Pos : Position_T)
   is
   begin
      -- Bot_2_Sim.Tell (Commands.CMD_AKT_SERVO, Commands.SUB_CMD_NORM,
      --                 Left, Right);
      null;
   end Set;

end Servos;
