--  PM_Strings are text strings stored in program memory.  As such
--  they are essentially constants.  They can only be sent to an
--  output stream.

with Interfaces;                   use Interfaces;
with AVR.Programspace;             use AVR.Programspace;
with AVR.Strings;                  use AVR.Strings;

package PM_Str is
   pragma Preelaborate;


   --  By limiting the length of PM_Strings to 255 bytes we can index
   --  them with unsigned 8-bit variables.  The first character alway
   --  has the index 1.
   type PM_Index is new Unsigned_8;

   --  a handle to the string in program memory (=flash)
   type PM_String is new Program_Address;


   --  function To_String (Text : PM_String) return AVR_String;
   function Length (Text : PM_String) return PM_Index;
   procedure To_String (Text : PM_String; Text_Out : out AVR_String);
   --  In order to avoid using the secondary stack we provide the two
   --  routines above.  You first have to determine the length, than
   --  you can create an appropriate variable on the client side and
   --  convert the PM_String to a variable string.

   generic
      with procedure Put (C : Character);
   procedure Generic_Put (T : PM_String);
   --  iterate over all characters in the string and apply the Put.
   --  Mostly used for output.

private

   --     type PM_String is new Program_Address;

end PM_Str;
