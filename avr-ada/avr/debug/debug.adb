with AVR;                          use AVR;
with AVR.Strings;                  use AVR.Strings;
with AVR.UART;

package body Debug is

   package U renames AVR.UART;

   procedure Init is separate;

   procedure Put (Text : AVR_String) is
   begin
      U.Put (Text);
   end Put;

   procedure Put (C : Character) is
   begin
      U.Put (C);
   end Put;

   procedure Put (Q : Boolean) is
   begin
      if Q then
         U.Put ('X');
      else
         U.Put ('0');
      end if;
   end Put;

   procedure Put (Len : Unsigned_8; Start : Program_Address) is
      Tmp  : Unsigned_8;
      C    : Character;
      Addr : Program_Address := Start;
   begin
      for I in Unsigned_8'(1) .. Len loop
         Tmp := AVR.Programspace.Get (Addr);
         C := Character'Val (Tmp);
         Put (C);
         AVR.Programspace.Inc (Addr);
      end loop;
   end Put;

   procedure Put_P (Text : Progmem_String) is
   begin
      Put (Text'Length, Text'Address);
   end Put_P;

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

   procedure Put (Data : Unsigned_32;  Base : Unsigned_8 := 10) is
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
