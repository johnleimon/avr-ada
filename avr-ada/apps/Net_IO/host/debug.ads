with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;
with AVR.PStrings;                 use AVR.PStrings;
#if not Target = "host" then
with AVR.Programspace;             use AVR.Programspace;
#end if;

package Debug is
   -- pragma Preelaborate;

   One_Wire  : constant Boolean := False;
   Dataflash : constant Boolean := False;
   Menu      : constant Boolean := False;
   Sensors   : constant Boolean := True;

   procedure Put (Text : AVR_String);
   procedure Put_String (Text : String);
   procedure Put_P (Text : P_STring);
   procedure Put (C : Character);
   procedure Put (Q : Boolean);
   procedure Put (Data : Unsigned_8;   Base : Unsigned_8 := 10);
   procedure Put (Data : Integer_16;   Base : Unsigned_8 := 10);

   procedure Put (Data : Unsigned_16;  Base : Unsigned_8 := 10);
   procedure Put_Line (Text : AVR_String);
   procedure New_Line;

   pragma Inline (Put);
   pragma Inline (New_Line);

end Debug;
