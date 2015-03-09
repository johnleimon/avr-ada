--      Verbindung c't-Bot zu c't-Sim

with Ada.Text_IO;
with AVR.Strings;                  use type AVR.Strings.AVR_String;

with TCP;
with Commands;
with Debug;

package body Bot_2_Sim is


   Dbg_Sent_Log : Ada.Text_IO.File_Type;
   Dbg_Rcvd_Log : Ada.Text_IO.File_Type;


   procedure Low_Init renames TCP.Init;


   procedure Tell_Impl (Command    : Commands.Cmd_Code;
                        Subcommand : Commands.Cmd_Code;
                        Data_L     : Integer_16;
                        Data_R     : Integer_16;
                        Payload    : Ada.Streams.Stream_Element_Array := Null_Data);


   --  Dieser Thread nimmt die Sensor-Daten vom PC entgegen,
   task Bot_2_Sim_Thread is
      pragma Priority (5);

      entry Start;
   end Bot_2_Sim_Thread;


   task body Bot_2_Sim_Thread is
      use Debug;
   begin
      accept Start;

      Debug.Put_Line ("bot_2_sim thread coming up at " & Debug.Timestamp_Ms);

      loop
         -- only write if noone reads command
         if not Commands.Read then
            Debug.Put_Line ("Error reading command");  -- read a command
         else
            --  permit the other task to run
            null;
            --  Commands.Evaluate;
         end if;

         delay 0.001;

      end loop;
   end Bot_2_Sim_Thread;


   -- Ein wenig Initialisierung kann nicht schaden
   procedure Init is
      use Ada.Text_IO;
   begin
      Low_Init;
      Create (Dbg_Sent_Log, Out_File, "sent.log");
      Create (Dbg_Rcvd_Log, Out_File, "rcvd.log");
      Bot_2_Sim_Thread.Start;
   end Init;


   Sequence_Count : Unsigned_16 := 1;    -- Zaehler fuer Paket-Sequenznummer
                                         --  Not_Answered_Error : Boolean := True;


   --!
   --  Gibt dem Simulator Daten und wartet nicht auf Antwort
   --/
   procedure Tell (Command    : Commands.Cmd_Code;
                   Subcommand : Commands.Cmd_Code;
                   Data_L     : Integer_16;
                   Data_R     : Integer_16;
                   Payload    : Ada.Streams.Stream_Element_Array := Null_Data)
   is
   begin
      Tell_Impl (Command, Subcommand, Data_L, Data_R, Payload);
   end Tell;


   procedure Tell_Impl (Command    : Commands.Cmd_Code;
                        Subcommand : Commands.Cmd_Code;
                        Data_L     : Integer_16;
                        Data_R     : Integer_16;
                        Payload    : Ada.Streams.Stream_Element_Array := Null_Data)
   is
      Cmd     : Commands.Command_T;
      subtype Cmd_Stream_Elements is Ada.Streams.Stream_Element_Array (1 .. 11);
      Cmd_Stream_Elems : Cmd_Stream_Elements;
      for Cmd_Stream_Elems'Address use Cmd'Address;

   begin
      Ada.Text_IO.Put_Line ("going to send pkg" & Sequence_Count'Img);

      Cmd.Start_Code         := Commands.CMD_STARTCODE;
      Cmd.Request.Direction  := Commands.Request;
      Cmd.Request.Command    := Command;
      Cmd.Request.Subcommand := Subcommand;

      if Payload'Length > 255 then
         Cmd.Payload := 255;
      else
         Cmd.Payload := Payload'Length;
      end if;

      Cmd.Data_L  := Data_L;
      Cmd.Data_R  := Data_R;
      Cmd.Seq     := Sequence_Count;
      Sequence_Count := Sequence_Count + 1;
      Cmd.CRC     := Commands.CMD_STOPCODE;

      Debug_Log:
      declare
         Cmd_AStr : constant Avr.Strings.AVR_String :=
           Debug.Timestamp_Ms & ": " & Commands.Image (Cmd);
      begin
         for I in Cmd_Astr'Range loop
            Ada.Text_IO.Put (Dbg_Sent_Log, Cmd_AStr (I));
         end loop;
         Ada.Text_IO.New_Line (Dbg_Sent_Log);
      end Debug_Log;


      TCP.Write (Cmd_Stream_Elems);

      Debug.Put_Line ("sent package");

   end Tell_Impl;


   pragma Warnings (Off);
   function Ask (Command    : Commands.Cmd_Code;
                 Subcommand : Commands.Cmd_Code;
                 Data_L     : Integer_16;
                 Data_R     : Integer_16) return Unsigned_16
   is
   begin
      return 0;
   end Ask;


end Bot_2_Sim;
