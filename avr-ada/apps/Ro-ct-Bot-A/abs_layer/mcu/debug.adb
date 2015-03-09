with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;
with AVR.UART;

package body Debug is

   package U renames AVR.UART;

   procedure Init is
      Baudrate : constant := 12; --  9600bps @ 1MHz, u2x = 1
   begin
      U.Init (Baudrate, Double_Speed => True);
   end Init;

   procedure Put (Text : AVR_String) is
   begin
      U.Put (Text);
   end Put;

   procedure Put (C : Character) is
   begin
      U.Put (C);
   end Put;

   procedure Put (Data : Unsigned_8;   Base : Unsigned_8 := 10) is
   begin
      U.Put (Data, Base);
   end Put;

   procedure Put (Data : Integer_16;   Base : Unsigned_8 := 10) is
   begin
      U.Put (Data, Base);
   end Put;

   procedure Put (Data : Unsigned_16;  Base : Unsigned_8 := 10) is
   begin
      U.Put (Data, Base);
   end Put;

   procedure Put_Line (Text : AVR_String) is
   begin
      U.Put_Line (Text);
   end Put_Line;

   procedure New_Line is
   begin
      U.New_Line;
   end New_Line;


begin
   Init;
end Debug;
