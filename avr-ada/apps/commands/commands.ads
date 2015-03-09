with AVR;                          use AVR;
with AVR.Strings;                  use AVR.Strings;
with PM_Str;                       use PM_Str;

package Commands is
   pragma Preelaborate;


   type Cmd_Action is not null access procedure;

   type Cmd_Info is record
      Id     : PM_String;
      Doc    : PM_String;
      Action : Cmd_Action;
   end record;

   type Cmd_List_T is array(Positive range <>) of Cmd_Info;

   procedure Parse_Input_And_Trigger_Action (Cmd_List       : Cmd_List_T;
                                             Default_Action : Cmd_Action);


   type Text_In_Progmem (Len : Nat8) is record
      Text : AVR_String(1..Len);
   end record;


   Cmd_List : constant Cmd_List_T;
   Default  : constant Cmd_Action;

private


   procedure Show_Commands;
   procedure Reset;
   procedure Wd_Reset;
   procedure OW_Parse;
   procedure IO_Parse;


   Help_Txt    : constant AVR_String := "help";
   Reset_Txt   : constant AVR_String := "reset";
   Wd_Reset_Txt : constant AVR_String := "wd_reset";
   Ow_Txt      : constant AVR_String := "1w";
   IO_Txt      : constant AVR_String := "io";

   Help_PM     : constant Text_In_Progmem := (Help_Txt'Length, Help_Txt);
   Reset_PM    : constant Text_In_Progmem := (Reset_Txt'Length, Reset_Txt);
   Wd_Reset_PM : constant Text_In_Progmem := (Wd_Reset_Txt'Length, Wd_Reset_Txt);
   Ow_PM       : constant Text_In_Progmem := (Ow_Txt'Length, Ow_Txt);
   IO_PM       : constant Text_In_Progmem := (IO_Txt'Length, IO_Txt);

   pragma Linker_Section (Help_PM, ".progmem");
   pragma Linker_Section (Reset_PM, ".progmem");
   pragma Linker_Section (Wd_Reset_PM, ".progmem");
   pragma Linker_Section (Ow_PM, ".progmem");
   pragma Linker_Section (IO_PM, ".progmem");

   Reset_Doc       : constant AVR_String := "warm reset, restart from 0.";
   Reset_Doc_PM    : constant Text_In_Progmem := (Reset_Doc'Length, Reset_Doc);
   Wd_Reset_Doc    : constant AVR_String := "going to reset via watchdog.";
   Wd_Reset_Doc_PM : constant Text_In_Progmem := (Wd_Reset_Doc'Length, Wd_Reset_Doc);
   pragma Linker_Section (Reset_Doc_PM, ".progmem");
   pragma Linker_Section (Wd_Reset_Doc_PM, ".progmem");

   subtype P is PM_String;

   Cmd_List : constant Cmd_List_T :=
     ((P(Help_PM'Address),     0,                       Show_Commands'Access),
      (P(Reset_PM'Address),    P(Reset_Doc_PM'Address),    Reset'Access),
      (P(Wd_Reset_PM'Address), P(Wd_Reset_Doc_PM'Address), Wd_Reset'Access),
      (P(OW_PM'Address),       0,                       OW_Parse'Access),
      (P(IO_PM'Address),       0,                       IO_Parse'Access));

   Default : constant Cmd_Action := Show_Commands'Access;
end Commands;
