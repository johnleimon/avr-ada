--  command interpreter and chip inspection
with AVR;                          use AVR;
with AVR.Strings;                  use AVR.Strings;
with AVR.Strings.Edit;
with AVR.Serial;
with Commands;                     use Commands;

procedure Main is
   Prompt : constant AVR_String := "$> ";
   Greet  : constant AVR_String := "starting chip inspection";
begin
   Serial.Init (Serial.Baud_19200_16MHz);
   Serial.Put_Line (Greet);

   Cmd_Loop : loop
      Serial.Put (Prompt);
      Serial.Get_Line (Strings.Edit.Input_Line, Strings.Edit.Input_Last);
      Strings.Edit.Input_Ptr := 1;
      Strings.Edit.Output_Last := 1;

      Parse_Input_And_Trigger_Action (Commands.Cmd_List, Commands.Default);
   end loop Cmd_Loop;
end Main;
