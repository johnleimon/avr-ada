with AVR.Strings;                  use AVR.Strings;
with Commands;                     use Commands;

package OW is
   pragma Preelaborate;


   procedure Parse;
   procedure Ow_Convert;
   procedure Ow_Get;
   procedure Ow_List;


   Convert_Txt : constant AVR_String := "convert";
   Get_Txt     : constant AVR_String := "get";
   List_Txt    : constant AVR_String := "list";

private

   Convert_PM : constant Text_In_Progmem := (Convert_Txt'Length, Convert_Txt);
   Get_PM     : constant Text_In_Progmem := (Get_Txt'Length, Get_Txt);
   List_PM    : constant Text_In_Progmem := (List_Txt'Length, List_Txt);

   pragma Linker_Section (Convert_PM, ".progmem");
   pragma Linker_Section (Get_PM, ".progmem");
   pragma Linker_Section (List_PM, ".progmem");

end OW;
