--      Verbindung c't-Bot zu c't-Sim

with Ada.Streams;
with Interfaces;                   use Interfaces;
with Commands;

package Bot_2_Sim is


   --!
   -- Ein wenig Initilisierung kann nicht schaden
   --/
   procedure Init;


   --!
   --  Frage Simulator nach Daten
   --/
   function Ask (Command    : Commands.Cmd_Code;
                 Subcommand : Commands.Cmd_Code;
                 Data_L     : Integer_16;
                 Data_R     : Integer_16) return Unsigned_16;


   Null_Data : constant Ada.Streams.Stream_Element_Array;

   --!
   --  Gib dem Simulator Daten -- und warte nicht auf eine Antwort!
   --
   procedure Tell (Command    : Commands.Cmd_Code;
                   Subcommand : Commands.Cmd_Code;
                   Data_L     : Integer_16;
                   Data_R     : Integer_16;
                   Payload    : Ada.Streams.Stream_Element_Array := Null_Data);

private


   Null_Data : constant Ada.Streams.Stream_Element_Array (1 .. 0) := (others => 0);


end Bot_2_Sim;
