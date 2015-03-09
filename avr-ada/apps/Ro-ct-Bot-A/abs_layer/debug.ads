with System;
with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;

package Debug is

   type Channel_Name is (Std_Out, Std_Err, File, Socket, Memory);

   type Channel_T (Name : Channel_Name := Std_Out) is record
      case Name is
      when Std_Out |
           Std_Err =>
         null;
      when File    =>
         Filename : access String;
      when Socket =>
         Server_Name : access String;
         Server_Port : Natural;
      when Memory =>
         Start_Addr  : System.Address;
         Memory_Size : Natural;
      when others =>
         null;
      end case;
   end record;


   --  procedure Set_Output_Channel (Ch : Channel_T);


   Sensors   : constant Boolean := True;

   procedure Put (Text : AVR_String);
   procedure Put (C : Character);
   procedure Put (Data : Unsigned_8;   Base : Unsigned_8 := 10);
   procedure Put (Data : Integer_16;   Base : Unsigned_8 := 10);
   procedure Put (Data : Unsigned_16;  Base : Unsigned_8 := 10);
   procedure Put_Line (Text : AVR_String);
   procedure New_Line;

   function Timestamp return AStr8;
   function Timestamp_ms return AStr12;

end Debug;
