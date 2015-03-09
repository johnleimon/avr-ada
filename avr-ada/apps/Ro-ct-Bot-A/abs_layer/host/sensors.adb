--      Low-Level Routinen fuer die Sensor Steuerung des c't-Bots

with Commands;

package body Sensors is


   --  Initialisiere alle Sensoren
   procedure Init is
   begin
      null;
   end Init;


   --  Alle Sensoren aktualisieren.
   procedure Bot_Sens is
   begin
      --  evaluate the command contents, i.e. store the received data
      --  in the corresponding sensor data
      Commands.Evaluate;

   end Bot_Sens;


end Sensors;
