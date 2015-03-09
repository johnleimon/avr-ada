with AVR.Strings;
with Debug;

package body Net.Buffer is


   procedure Debug_Put (B : Storage) is
      use Debug;
      I_Mod_16    : Unsigned_8 range 0 .. 15;
      Text        : AVR.Strings.AStr16;
      Unprintable : constant Character := '.';
   begin
      Debug.Put_Line ("buffer out");
      for Offset in B'Range loop
         I_Mod_16 := Unsigned_8 ((Offset-1) mod 16);

         if I_Mod_16 = 0 then
            if Offset > 1 then
               Put (' ');
               Put (Text);
               New_Line;
            end if;

            Put (Unsigned_16 (Offset-1), 16);
            Put (": ");
         end if;

         declare
            Data : constant Unsigned_8 := Unsigned_8 (B(Offset));
         begin
            Put (Data, 16);
            Put (' ');

            if Data >= 32 and then Data <= 126 then
               Text (I_Mod_16 + 1) := Character'Val (Data);
            else
               Text (I_Mod_16 + 1) := Unprintable;
            end if;
         end;
      end loop;
      New_Line;
   end Debug_Put;

end Net.Buffer;


