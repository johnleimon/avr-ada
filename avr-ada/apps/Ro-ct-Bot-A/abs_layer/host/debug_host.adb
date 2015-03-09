--   implementation for development host machine

with Ada.Text_IO;
with Ada.Calendar;
with GNAT.Calendar.Time_IO;

package body Debug is

   procedure Put (Text : AVR_String) is
   begin
      for I in Text'Range loop
         Put (Text (I));
      end loop;
   end Put;


--     procedure Put (Text : String) is
--     begin
--        for I in Text'Range loop
--           Put (Text (I));
--        end loop;
--     end Put;


   procedure Put (C : Character) is
   begin
      Ada.Text_IO.Put (C);
   end Put;


   package U8_IO is new Ada.Text_IO.Modular_IO (Unsigned_8);
   package I16_IO is new Ada.Text_IO.Integer_IO (Integer_16);
   package U16_IO is new Ada.Text_IO.Modular_IO (Unsigned_16);


   procedure Put (Data : Unsigned_8;   Base : Unsigned_8 := 10) is
   begin
      U8_IO.Put (Item => Data, Base => Ada.Text_IO.Number_Base (Base));
   end Put;


   procedure Put (Data : Integer_16;   Base : Unsigned_8 := 10) is
   begin
      I16_IO.Put (Item => Data, Base => Ada.Text_IO.Number_Base (Base));
   end Put;


   procedure Put (Data : Unsigned_16;  Base : Unsigned_8 := 10) is
   begin
      U16_IO.Put (Item => Data, Base => Ada.Text_IO.Number_Base (Base));
   end Put;


   procedure Put_Line (Text : AVR_String) is
   begin
      Put (Text);
      New_Line;
   end Put_Line;


--     procedure Put_Line (Text : String) is
--     begin
--        Put (Text);
--        New_Line;
--     end Put_Line;


   procedure New_Line is
   begin
      Ada.Text_IO.New_Line;
   end New_Line;


   function Timestamp return AStr8
   is
      use GNAT.Calendar.Time_IO;
      Str : constant String := GNAT.Calendar.Time_IO.Image (Ada.Calendar.Clock, "%H:%M:%S");
      Result : AStr8;
   begin
      for I in Result'Range loop
         Result (I) := Str (Integer (I));
      end loop;
      return Result;
   end Timestamp;


   function Timestamp_ms return AStr12
   is
      use GNAT.Calendar.Time_IO;
      Str : constant String := GNAT.Calendar.Time_IO.Image (Ada.Calendar.Clock, "%H:%M:%S.%i");
      Result : AStr12;
   begin
      for I in Result'Range loop
         Result (I) := Str (Integer (I));
      end loop;
      return Result;
   end Timestamp_ms;

end Debug;
