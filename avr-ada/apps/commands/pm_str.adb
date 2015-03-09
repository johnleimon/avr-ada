--  PM_Strings are text strings stored in program memory.  As such
--  they are essentially constants.  They can only be sent to an
--  output stream.

with System;                       use type System.Address;
with Interfaces;                   use Interfaces;
with Ada.Unchecked_Conversion;
with AVR.Programspace;             use AVR.Programspace;

package body PM_Str is

   function Length (Text : PM_String) return PM_Index
   is
      Text_Len : constant Unsigned_8 := Get_Byte (Program_Address(Text));
   begin
      return PM_Index (Text_Len);
   end Length;


   function To_C is new Ada.Unchecked_Conversion (Source => AVR.Nat8,
                                                  Target => Character);

   procedure To_String (Text : PM_String; Text_Out : out AVR_String)
   is
      Text_Len : constant Unsigned_8 := Get_Byte (Program_Address(Text));
      Outp_Len : constant Unsigned_8 := Text_Out'Length;
      Len      : constant Unsigned_8 := Unsigned_8'Min (Text_Len, Outp_Len);
      Outp     : AVR_String (1 .. Len);
      Pos      : Program_Address := Program_Address(Text);
   begin
      for I in Outp'Range loop
         Pos := Pos + 1;
         Outp(I) := To_C(AVR.Programspace.Get_Byte (Pos));
      end loop;
      Text_Out := Outp;
   end To_String;


   --  function To_String (Text : PM_String) return AVR_String
   --  is
   --     Len  : constant Unsigned_8 := Get_Byte (Program_Address(Text));
   --     Outp : AVR_String (1 .. Len);
   --     Pos  : Program_Address := Program_Address(Text);
   --  begin
   --     for I in Outp'Range loop
   --        Pos := Pos + 1;
   --        Outp(I) := To_C(AVR.Programspace.Get_Byte (Pos));
   --     end loop;
   --     return Outp;
   --  end To_String;


   procedure Generic_Put (T : PM_String)
   is
      Pos : Program_Address := Program_Address(T);
      Len : Unsigned_8;
   begin
      Len := Get_Byte (Pos);
      for I in 1 .. Len loop
         Pos := Pos + 1;
         Put (To_C (AVR.Programspace.Get_Byte (Pos)));
      end loop;
   end Generic_Put;

end PM_Str;
