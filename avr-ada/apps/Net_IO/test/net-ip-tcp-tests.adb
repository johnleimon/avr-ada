with AUnit.Test_Cases.Registration;
 use AUnit.Test_Cases.Registration;

with AUnit.Assertions;             use AUnit.Assertions;

with Interfaces;                   use Interfaces;

with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with AUnit.Test_Cases;
use AUnit.Test_Cases;

package body Net.IP.TCP.Tests is



   TCP_Pkg_Byte_Len : constant := 200;
   subtype Byte_Index is Unsigned_8 range 1 .. TCP_Pkg_Byte_Len;
   type Overlayed_Bytes is array (Byte_Index range <>) of Unsigned_8;
   Bytes1 : constant Overlayed_Bytes :=
     (16#00#, 16#22#, 16#F9#, 16#01#, 16#0e#, 16#Fd#, 16#00#, 16#1a#,
      16#92#, 16#42#, 16#84#, 16#7c#, 16#08#, 16#00#, 16#45#, 16#00#,
      16#00#, 16#30#, 16#Bd#, 16#1c#, 16#40#, 16#00#, 16#80#, 16#06#,
      16#58#, 16#3b#, 16#C0#, 16#A8#, 16#B2#, 16#0b#, 16#C0#, 16#A8#,
      16#B2#, 16#13#, 16#0e#, 16#Df#, 16#00#, 16#17#, 16#2d#, 16#1c#,
      16#9e#, 16#5b#, 16#00#, 16#00#, 16#00#, 16#00#, 16#70#, 16#02#,
      16#Ff#, 16#Ff#, 16#C3#, 16#41#, 16#00#, 16#00#, 16#02#, 16#04#,
      16#05#, 16#B4#, 16#01#, 16#01#, 16#04#, 16#02#);

   Pkg1 : Net.IP.TCP.TCP_Package_Type;
   for Pkg1'Address use Bytes1'Address;

   --  init (SYN) by client
   --  00000000: 0015 0ce6 7b41 0019 e08f 5ff4 0800 4500  ....{A...._...E.
   --  00000010: 0030 05c1 4000 8006 0f9d c0a8 b217 c0a8  .0..@...........
   --  00000020: b201 0421 0017 3ec6 d085 0000 0000 7002  ...!..>.......p.
   --  00000030: 4000 4a31 0000 0204 05b4 0101 0402       @.J1..........

   Bytes_Init : constant Overlayed_Bytes :=
     (16#00#, 16#15#, 16#0c#, 16#E6#, 16#7b#, 16#41#, 16#00#, 16#19#,
      16#E0#, 16#8f#, 16#5f#, 16#F4#, 16#08#, 16#00#, 16#45#, 16#00#,
      16#00#, 16#30#, 16#05#, 16#C1#, 16#40#, 16#00#, 16#80#, 16#06#,
      16#0f#, 16#9d#, 16#C0#, 16#A8#, 16#B2#, 16#17#, 16#C0#, 16#A8#,
      16#B2#, 16#01#, 16#04#, 16#21#, 16#00#, 16#17#, 16#3e#, 16#C6#,
      16#D0#, 16#85#, 16#00#, 16#00#, 16#00#, 16#00#, 16#70#, 16#02#,
      16#40#, 16#00#, 16#4a#, 16#31#, 16#00#, 16#00#, 16#02#, 16#04#,
      16#05#, 16#B4#, 16#01#, 16#01#, 16#04#, 16#02#);

   P_Init : Net.IP.TCP.TCP_Package_Type;
   for P_Init'Address use Bytes_Init'Address;


   --  response (SYN, ACK) by server
   --  00000000: 0019 e08f 5ff4 0015 0ce6 7b41 0800 4500  ...._.....{A..E.
   --  00000010: 0030 0000 4000 4006 555e c0a8 b201 c0a8  .0..@.@.U^......
   --  00000020: b217 0017 0421 89d8 0141 3ec6 d086 7012  .....!...A>...p.
   --  00000030: 16d0 e836 0000 0204 05b4 0101 0402       ...6..........

   Bytes_Res_Srv : constant Overlayed_Bytes :=
     (16#00#, 16#19#, 16#E0#, 16#8f#, 16#5f#, 16#F4#, 16#00#, 16#15#,
      16#0c#, 16#E6#, 16#7b#, 16#41#, 16#08#, 16#00#, 16#45#, 16#00#,
      16#00#, 16#30#, 16#00#, 16#00#, 16#40#, 16#00#, 16#40#, 16#06#,
      16#55#, 16#5e#, 16#C0#, 16#A8#, 16#B2#, 16#01#, 16#C0#, 16#A8#,
      16#B2#, 16#17#, 16#00#, 16#17#, 16#04#, 16#21#, 16#89#, 16#D8#,
      16#01#, 16#41#, 16#3e#, 16#C6#, 16#D0#, 16#86#, 16#70#, 16#12#,
      16#16#, 16#D0#, 16#E8#, 16#36#, 16#00#, 16#00#, 16#02#, 16#04#,
      16#05#, 16#B4#, 16#01#, 16#01#, 16#04#, 16#02#);

   P_Srv : Net.IP.TCP.TCP_Package_Type;
   for P_Srv'Address use Bytes_Res_Srv'Address;


   --  response (ACK) by client
   --  00000000: 0015 0ce6 7b41 0019 e08f 5ff4 0800 4500  ....{A...._...E.
   --  00000010: 0028 05c2 4000 8006 0fa4 c0a8 b217 c0a8  .(..@...........
   --  00000020: b201 0421 0017 3ec6 d086 89d8 0142 5010  ...!..>......BP.
   --  00000030: 4470 e75a 0000                           Dp.Z..

   Bytes_Res_Clt : constant Overlayed_Bytes :=
     (16#00#, 16#15#, 16#0c#, 16#E6#, 16#7b#, 16#41#, 16#00#, 16#19#,
      16#E0#, 16#8f#, 16#5f#, 16#F4#, 16#08#, 16#00#, 16#45#, 16#00#,
      16#00#, 16#28#, 16#05#, 16#C2#, 16#40#, 16#00#, 16#80#, 16#06#,
      16#0f#, 16#A4#, 16#C0#, 16#A8#, 16#B2#, 16#17#, 16#C0#, 16#A8#,
      16#B2#, 16#01#, 16#04#, 16#21#, 16#00#, 16#17#, 16#3e#, 16#C6#,
      16#D0#, 16#86#, 16#89#, 16#D8#, 16#01#, 16#42#, 16#50#, 16#10#,
      16#44#, 16#70#, 16#E7#, 16#5a#, 16#00#, 16#00#);

   P_Clt : Net.IP.TCP.TCP_Package_Type;
   for P_Clt'Address use Bytes_Res_Clt'Address;


   procedure Test_IP1_Struct (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Hdr : IP_Header renames Pkg1.IP;
   begin
      Assert (Hdr.Version = 4, "IP_Header Version");
      Assert (Hdr.Header_Size = 5, "IP_Header Size");
      Assert (NtoH_16 (Hdr.Total_Len) = 48, "total length");
      Assert (Hdr.TOS = 0, "TOS");
      Assert (NtoH_16 (Hdr.Sum) = 16#583b#, "Checksum");
      Assert (Hdr.Src = (192,168,178,11), "Source IP");
      Assert (Hdr.Dst = (192,168,178,19), "Dest IP");
   end Test_IP1_Struct;


   procedure Test_IPI_Struct (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Hdr : IP_Header renames P_Init.IP;
   begin
      Assert (Hdr.Version = 4, "IP_Header Version");
      Assert (Hdr.Header_Size = 5, "IP_Header Size");
      Assert (NtoH_16 (Hdr.Total_Len) = 48, "total length");
      Assert (Hdr.TOS = 0, "TOS");
      Assert (NtoH_16 (Hdr.Sum) = 16#0f9d#, "Checksum");
      Assert (Hdr.Src = (192,168,178,23), "Source IP");
      Assert (Hdr.Dst = (192,168,178,1), "Dest IP");
   end Test_IPI_Struct;


   procedure Test_TCP_Struct (T : in out AUnit.Test_Cases.Test_Case'Class) is
      T1  : TCP_Header renames Pkg1.TCP;
      T_I : TCP_Header renames P_Init.TCP;
      T_R : TCP_Header renames P_Srv.TCP;
      Tmp_16 : Unsigned_16;
      Tmp_32 : Unsigned_32;
      F : TCP_Flags_Type renames P_Init.TCP.Flags;
   begin
      Tmp_16 := NtoH_16 (T_I.Src_Port);
      Assert (Tmp_16 = 1057, "Source port 1057 /= " & Tmp_16'Img);
      Tmp_16 := NtoH_16 (T_I.Dst_Port);
      Assert (Tmp_16 =23, "destination port 23 /= " & Tmp_16'Img);
      Tmp_32 := NtoH_32 (T_I.Seq_Nr);
      Assert (Tmp_32 = 16#3ec6d085#, "sequence nr 1053216901 /= " & Tmp_32'Img);
      Assert (T_I.Hdr_Size/4 = 28, "header length 28*4 /= " & T_I.Hdr_Size'Img);
      Assert (F(FIN) = False, "Init FIN /= False");
      Assert (F(SYN) = True, "Init SYN /= True");
      Assert (F(RST) = False, "Init RST /= False");
      Assert (F(PSH) = False, "Init PSH /= False");
      Assert (F(ACK) = False, "Init ACK /= False");
      Assert (F(URG) = False, "Init URG /= False");
      Assert (F(ECE) = False, "Init ECE /= False");
      Assert (F(CWR) = False, "Init CWR /= False");
      Tmp_16 := NtoH_16 (T_I.Window);
      Assert (Tmp_16 = 16384, "window size 16384 /= " & Tmp_16'Img);
      Tmp_16 := NtoH_16 (T_I.Sum);
      Assert (Tmp_16 = 16#4A31#, "check sum 18993 /= " & Tmp_16'Img);
      Assert (P_Srv.Data (1) = 2, "data(1) /= 2" );
      Assert (P_Srv.Data (2) = 4, "data(2) /= 4" );
      Assert (P_Srv.Data (3) = 5, "data(3) /= 5" );
      Assert (P_Srv.Data (4) = 16#B4#, "data(4) /= b4" );
      Assert (P_Srv.Data (5) = 1, "data(5) /= 1" );
      Assert (P_Srv.Data (6) = 1, "data(6) /= 1" );
      Assert (P_Srv.Data (7) = 4, "data(7) /= 4" );
      Assert (P_Srv.Data (8) = 2, "data(8) /= 2" );

   end Test_TCP_Struct;

   procedure Register_Tests (T : in out Test_Case)
   is
   begin
      Register_Routine (T, Test_IP1_Struct'Access, "test IP1 Struct");
      Register_Routine (T, Test_IPI_Struct'Access, "test IPI Struct");
      Register_Routine (T, Test_TCP_Struct'Access, "test TCP Struct");
   end Register_Tests;

   --  Register routines to be run

   function Name (T : Test_Case) return String_Access
   is
   begin
      return new String'("IP, TCP");
   end Name;

   --  Returns name identifying the test case

end Net.IP.TCP.Tests;
