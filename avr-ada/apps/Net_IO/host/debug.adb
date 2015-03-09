--   implementation for development host machine

with GNAT.IO;
with AVR.Int_Img;                  use AVR.Int_Img;

package body Debug is

   procedure Put_Char (C : Character) renames GNAT.IO.Put;

   procedure Put_String (Text : String) is
   begin
      for I in Text'Range loop
         Put_Char (Text (I));
      end loop;
   end Put_String;

   procedure Put (Text : AVR_String) is
   begin
      for I in Text'Range loop
         Put_Char (Text (I));
      end loop;
   end Put;

   procedure Put_P (Text : P_STring) is
   begin
      null;
   end;

#if not Target = "host" then

   procedure Put (Len : Unsigned_8; Start : Program_Address) is
      C    : Character;
      Addr : Program_Address := Start;
   begin
      for I in Unsigned_8'(1) .. Len loop
         C := AVR.Programspace.Get (Addr);
         Put_Char (C);
         AVR.Programspace.Inc (Addr);
      end loop;
   end Put;
#end if;

   procedure Put (C : Character) renames Put_Char;

   procedure Put (Q : Boolean) is
   begin
      if Q then
         Put ('X');
      else
         Put ('0');
      end if;
   end Put;


   --package U8_IO is new Ada.Text_IO.Modular_IO (Unsigned_8);
   --package I16_IO is new Ada.Text_IO.Integer_IO (Integer_16);
   --package U16_IO is new Ada.Text_IO.Modular_IO (Unsigned_16);


   procedure Put (Data : Unsigned_8;   Base : Unsigned_8 := 10) is
      Img : AStr3;
      L   : Unsigned_8;
   begin
      if Base = 10 then
         U8_Img (Data, Img, L);
         Put (Img (1..L));
      else
         U8_Hex_Img (Data, Img(1..2));
         --Put ("16#");
         Put (Img (1..2));
         --Put ('#');
      end if;
   end Put;


   procedure Put (Data : Integer_16;   Base : Unsigned_8 := 10) is
      Img : AStr5;
      L   : Unsigned_8;
   begin
      if Base = 10 then
         if Data < 0 then
            Put ('-');
            U16_Img (-Unsigned_16(Data), Img, L);
         else
            U16_Img (Unsigned_16(Data), Img, L);
         end if;
         Put (Img (1..L));
      else
         declare
            Udata : constant Unsigned_16 := Unsigned_16 (Data);
         begin
            Put (Udata);
         end;
      end if;
   end Put;


   procedure Put (Data : Unsigned_16;  Base : Unsigned_8 := 10) is
      Img   : AStr2;
   begin
      --Put ("16#");
      U8_Hex_Img (AVR.High_Byte (Data), Img);
      Put (Img);
      U8_Hex_Img (AVR.Low_Byte (Data), Img);
      Put (Img);
      --Put ('#');
   end Put;


   procedure Put_Line (Text : AVR_String) is
   begin
      Put (Text);
      New_Line;
   end Put_Line;


   procedure New_Line is
   begin
      GNAT.IO.New_Line;
   end New_Line;

end Debug;
