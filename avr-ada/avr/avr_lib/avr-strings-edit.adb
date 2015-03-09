package body AVR.Strings.Edit is


   function Length (Text : Edit_String) return All_Edit_Index_T is
   begin
      return Text.Last - Text.First + 1;
   end Length;


   function First (Text : Edit_String) return All_Edit_Index_T is
   begin
      return Text.First;
   end First;


   function Last (Text : Edit_String) return All_Edit_Index_T is
   begin
      return Text.Last;
   end Last;


   procedure Skip (Blank : Character := ' ') is
   begin
      while Input_Line (Input_Ptr) = Blank loop
         Input_Ptr := Input_Ptr + 1;
         exit when Input_Ptr > Input_Last;
      end loop;
   end Skip;


   --  This procedure skips the blank characters starting from
   --  Input_Line(ptr_input).  Ptr_Input is advanced to the first
   --  non-blank character or to Input_Buffer_Length + 1.
   procedure Get_Str (Stop : Character := ' ') is
   begin
      while Input_Line(Input_Ptr) /= Stop loop
         Input_Ptr := Input_Ptr + 1;
         exit when Input_Ptr > Input_Last;
      end loop;
   end Get_Str;


   function Get_Str (Stop : Character := ' ') return Edit_String is
      Word : Edit_String;
   begin
      Skip;
      Word.First := Input_Ptr;
      Get_Str (Stop);
      Word.Last := Input_Ptr - 1;
      return Word;
   end Get_Str;


   -- Put -- Put a character into a string
   --
   --    Value       - The character to be put
   --    Field       - The output field
   --    Justify     - Alignment within the field
   --    Fill        - The fill character
   --
   --  This procedure places the specified character Value into the
   --  Output_Line. The character is written at Output_Last.
   procedure Put (Value       : Character;
                  Field       : All_Edit_Index_T := 0;
                  Justify     : Alignment := Left;
                  Fill        : Character := ' ')
   is
   begin
      if Field > 1 then
         if Output_Last + Field > All_Edit_Index_T'Last then
            -- error;
            raise Constraint_Error;
            -- return;
         else
            if Justify = Right then
               for I in 1 .. Field - 1 loop
                  Output_Line (Output_Last) := Fill;
                  Output_Last := Output_Last + 1;
               end loop;
            end if;
         end if;
      end if;

      -- in all cases we append the Value
      Output_Line (Output_Last) := Value;
      Output_Last := Output_Last + 1;

      if Justify = Left and then Field > 1 then
         for Pos in 1 .. Field-1 loop
            Output_Line (Output_Last) := Fill;
            Output_Last := Output_Last + 1;
         end loop;
      end if;
   end Put;


   procedure Put (Value       : AVR_String;
                  Field       : All_Edit_Index_T := 0;
                  Justify     : Alignment := Left;
                  Fill        : Character := ' ')
   is
      Value_Length : constant All_Edit_Index_T := Value'Length;
   begin
      if Field > Value_Length then
         if Output_Last + Field > All_Edit_Index_T'Last then
            -- error;
            return;
         else
            if Justify = Right then
               for I in Value_Length .. Field - 1 loop
                  Output_Line (Output_Last) := Fill;
                  Output_Last := Output_Last + 1;
               end loop;
            end if;
         end if;
      end if;
      -- in all cases we append the Value
      Output_Line(Output_Last..Output_Last+Value_Length-1) := Value;
      Output_Last := Output_Last + Value_Length;

      if Justify = Left and then Field > Value_Length then
         for I in Value_Length .. Field - 1 loop
            Output_Line (Output_Last) := Fill;
            Output_Last := Output_Last + 1;
         end loop;
      end if;
   end Put;


   procedure Put_Line (Value       : AVR_String;
                       Field       : All_Edit_Index_T := 0;
                       Justify     : Alignment := Left;
                       Fill        : Character := ' ')
   is
   begin
      Put (Value, Field, Justify, Fill);
      New_Line;
   end Put_Line;


   procedure New_Line  --  only line-feed (LF)
   is
      EOL : constant Character := Character'Val(16#0A#);
   begin
      Put (EOL);
   end New_Line;


   procedure CRLF is   --  DOS like CR & LF
      LF : constant Character := Character'Val(16#0A#);
      CR : constant Character := Character'Val(16#0D#);
   begin
      Put (CR);
      Put (LF);
   end CRLF;


   procedure Flush_Output is
   begin
      for I in 1 .. Output_Last - 1 loop
         Put_Raw (Unsigned_8(Character'Pos(Output_Line(I))));
      end loop;
      Output_Last := 1;
   end Flush_Output;

end AVR.Strings.Edit;
