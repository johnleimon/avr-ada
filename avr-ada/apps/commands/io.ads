with AVR.Strings;                  use AVR.Strings;
with Commands;                     use Commands;
with PM_Str;                       use PM_Str;

package IO is
   pragma Preelaborate;


   procedure Parse;
   procedure IO_Get;
   procedure IO_Set;
   procedure Dump;
   procedure Show_IO_Commands;

   Get_Txt    : constant AVR_String := "get";
   Set_Txt    : constant AVR_String := "set";
   Dump_Txt   : constant AVR_String := "dump";
   Help_Txt   : constant AVR_String := "help";

private

   Get_PM     : constant Text_In_Progmem := (Get_Txt'Length, Get_Txt);
   Set_PM     : constant Text_In_Progmem := (Set_Txt'Length, Set_Txt);
   Dump_PM    : constant Text_In_Progmem := (Dump_Txt'Length, Dump_Txt);
   Help_PM    : constant Text_In_Progmem := (Help_Txt'Length, Help_Txt);

   pragma Linker_Section (Get_PM, ".progmem");
   pragma Linker_Section (Set_PM, ".progmem");
   pragma Linker_Section (Dump_PM, ".progmem");
   pragma Linker_Section (Help_PM, ".progmem");

   IO_Cmds : constant Cmd_List_T :=
     ((PM_String(Get_PM'Address), 0, IO_Get'Access),
      (PM_String(Set_PM'Address), 0, IO_Set'Access),
      (PM_String(Dump_PM'Address), 0, Dump'Access),
      (PM_String(Help_PM'Address), 0, Show_IO_Commands'Access));

   IO_Default : constant Cmd_Action := Show_IO_Commands'Access;

end IO;
