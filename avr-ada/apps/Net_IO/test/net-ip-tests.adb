with AUnit.Test_Cases.Registration;
 use AUnit.Test_Cases.Registration;

with AUnit.Assertions;             use AUnit.Assertions;

with Interfaces;                   use Interfaces;

-- needed only on hosts when the package is not declared Pure in the spec.
-- pragma Elaborate_All (AVR.Real_Time);

package body Net.IP.Tests is

   Hdr : Net.IP.IP_Header;

   IP_Hdr_Byte_Len : constant := 20;
   subtype Byte_Index is Unsigned_8 range 1 .. IP_Hdr_Byte_Len;
   type Overlayed_Bytes is array (Byte_Index) of Unsigned_8;
   Bytes : Overlayed_Bytes;
   for Bytes'Address use Hdr'Address;


   procedure Test_IP_Struct (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Bytes := (16#45#, 16#00#, 16#00#, 16#3c#, 16#4f#,
                16#55#, 16#00#, 16#00#, 16#80#, 16#01#,
                16#D6#, 16#77#, 16#0a#, 16#31#, 16#Fe#,
                16#7a#, 16#0a#, 16#31#, 16#02#, 16#18#);

      Assert (Hdr.Version = 4, "IP_Header Version");
      Assert (Hdr.Header_Size = 5, "IP_Header Size");
      Assert (NtoH_16 (Hdr.Total_Len) = 60, "total length");
      Assert (Hdr.TOS = 0, "TOS");
      Assert (NtoH_16 (Hdr.Sum) = 54903, "Checksum");
      Assert (Hdr.Src = (10,49,254,122), "Source IP");
      Assert (Hdr.Dst = (10,49,2,24), "Dest IP");
   end Test_IP_Struct;


   procedure Test_IP_Chksum (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Bytes := (16#45#, 16#00#, 16#00#, 16#3c#, 16#4f#,
                16#55#, 16#00#, 16#00#, 16#80#, 16#01#,
                16#D6#, 16#77#, 16#0a#, 16#31#, 16#Fe#,
                16#7a#, 16#0a#, 16#31#, 16#02#, 16#18#);
      Hdr.Sum := HtoN_16 (0);
      Set_Checksum (Hdr);
      Assert (NtoH_16 (Hdr.Sum) = 54903, "Checksum");

      Bytes := (16#45#, 16#00#, 16#00#, 16#3c#, 16#35#,
                16#86#, 16#00#, 16#00#, 16#7e#, 16#01#,
                16#F2#, 16#4d#, 16#0a#, 16#31#, 16#02#,
                16#11#, 16#0a#, 16#31#, 16#Fe#, 16#7a#);

      Hdr.Sum := HtoN_16 (0);
      Set_Checksum (Hdr);
      Assert (NtoH_16 (Hdr.Sum) = (16#4d# * 256 + 16#FD#), "Checksum 2");

   end;

   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("IP structure");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_IP_Struct'Access, "test IP_Struct");
      Register_Routine (T, Test_IP_Struct'Access, "test IP checksum");
   end Register_Tests;

end Net.IP.Tests;
