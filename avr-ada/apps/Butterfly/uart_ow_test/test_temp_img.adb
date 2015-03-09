with Ada.Text_IO;                  use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;                   use Interfaces;

With Temperatures;                 use Temperatures;

procedure Test_Temp_Img is

   package T9_IO is new Ada.Text_IO.Fixed_IO (Temperatures.Temperature_9bit);
   use T9_IO;
   package T12_IO is new Ada.Text_IO.Fixed_IO (Temperatures.Temperature_12bit);
   use T12_IO;
   package U16_IO is new Ada.Text_IO.Modular_IO (Interfaces.Unsigned_16);
   use U16_IO;

   function U16 is new Ada.Unchecked_Conversion
     (Source => Temperature_12bit,
      Target => Interfaces.Unsigned_16);

   function U16 is new Ada.Unchecked_Conversion
     (Source => Temperature_9bit,
      Target => Interfaces.Unsigned_16);


   T9  : Temperature_9bit;
   T12 : Temperature_12bit;

   D   : constant Temperature_12bit := Temperature_12bit'Small;


   procedure Put_All (V : Temperature_9bit) is
   begin
      Put ("Ada: ");
      Put (V);
      Put (", Rimg: ");
      Put (Image (V));
      Put (", Hex: ");
      Put (U16 (V), Width => 8, Base => 16);
   end Put_All;


   procedure Put_All (V : Temperature_12bit) is
      Ada_Out_Str      : String (1 .. 5);
      Ada_Out_Str_Full : String (1 .. 8);
      R_Out_Str        : constant String (1 .. 5) := Image (V);
      R_Out_Str_full   : constant String (1 .. 8) := Image_Full (V);
   begin
      Put ("Ada: ");
      Put (Ada_Out_Str_Full, V, Aft => 4);
      Put (Ada_Out_Str_Full);
      Put (", RimgF: ");
      Put (R_Out_Str_Full);
      Put (", Ada: ");
      Put (Ada_Out_Str, V, Aft => 1);
      Put (Ada_Out_Str);
      Put (", Rimg: ");
      Put (R_Out_Str);
      Put (", Hex: ");
      Put (U16 (V), Width => 8, Base => 16);
      if Ada_Out_Str /= R_Out_Str then
         Put ("    FAIL");
      else
         Put ("    PASS");
      end if;
   end Put_All;

   L : Natural;
begin

   Put ("T9'Fore = ");
   L := Temperature_9bit'Fore;
   Put (L'Img);

   Put (", T9'Aft = ");
   L := Temperature_9bit'Aft;
   Put (L'Img);

   Put (", T12'Fore = ");
   L := Temperature_12bit'Fore;
   Put (L'Img);

   Put (", T12'Aft = ");
   L := Temperature_12bit'Aft;
   Put (L'Img);

   New_Line;

   T9 :=   0.0;   Put_All (T9);  New_Line;
   T9 :=  -3.0;   Put_All (T9);  New_Line;
   T9 :=  10.0;   Put_All (T9);  New_Line;
   T9 :=  12.5;   Put_All (T9);  New_Line;
   T9 := -23.0;   Put_All (T9);  New_Line;
   T9 := 125.0;   Put_All (T9);  New_Line;
   T9 := -55.0;   Put_All (T9);  New_Line;

   T12 :=   0.0;  Put_All (T12);  New_Line;
   T12 :=  -3.0;  Put_All (T12);  New_Line;
   T12 :=  10.0;  Put_All (T12);  New_Line;
   T12 :=  12.5;  Put_All (T12);  New_Line;
   T12 := -23.0;  Put_All (T12);  New_Line;
   T12 := 125.0;  Put_All (T12);  New_Line;
   T12 := -55.0;  Put_All (T12);  New_Line;


   T12 := -55.0;
   loop
      T12 := T12  + D;
      Put_All (T12);
      New_Line;
      exit when T12 >= 125.0;
   end loop;

end Test_Temp_Img;
