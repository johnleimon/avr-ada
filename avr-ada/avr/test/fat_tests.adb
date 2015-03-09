with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;
with AdaDIO;
with FATFS;                            use FATFS;

use Ada.Text_IO;

package body FAT_Tests is

   Failure :         exception;

   FAT16_Suite_No :  Unsigned_32 := 0;          -- Test Suite Number
   FAT32_Suite_No :  Unsigned_32 := 0;          -- Test Suite Number
   Space :           Unsigned_32 := 0;          -- File System available space in bytes
   T_Min, T_Max :    Unsigned_32 := 0;

   package U8 is new Ada.Text_IO.Modular_IO(Interfaces.Unsigned_8);
   package U16 is new Ada.Text_IO.Modular_IO(Interfaces.Unsigned_16);
   package U32 is new Ada.Text_IO.Modular_IO(Interfaces.Unsigned_32);

   package R8 is new Ada.Numerics.Discrete_Random(Unsigned_8);
   package R16 is new Ada.Numerics.Discrete_Random(Unsigned_16);

   Gen8 :   R8.Generator;
   Gen16 :  R16.Generator;

   -------------------------------------------------------------------
   -- Generate a Random Unsigned_8 Value
   -------------------------------------------------------------------
   function Rand_U8 return Unsigned_8 is
   begin
      return R8.Random(Gen8);
   end Rand_U8;

   -------------------------------------------------------------------
   -- Generate a Random Printable Character
   -------------------------------------------------------------------
   function Rand_Char return Character is
      Char_Set : String := "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/.";
      X :        Natural := Natural(Rand_U8 mod Char_Set'Length) + Char_Set'First;
   begin
      return Char_Set(X);
   end Rand_Char;

   -------------------------------------------------------------------
   -- Generate a Random Unsigned_16 Value
   -------------------------------------------------------------------
   function Rand_U16 return Unsigned_16 is
   begin
      return R16.Random(Gen16);
   end Rand_U16;

   -------------------------------------------------------------------
   -- Return a Random String of Text
   -------------------------------------------------------------------
   function Rand_String(Limit : Positive := 80) return String is
      Len : Unsigned_16 := ( Rand_U16 mod Unsigned_16(Limit-1) );
      Str : String(1..Natural(Len));
   begin

      for X in Str'Range loop
         Str(X) := Rand_Char;
      end loop;
      return Str;

   end Rand_String;

   -------------------------------------------------------------------
   -- Return a Random Byte String
   -------------------------------------------------------------------
   function Rand_Bytes(Limit : Positive := 80) return U8_Array is
      Len : Unsigned_16 := Rand_U16 mod Unsigned_16(Limit);
      Buf : U8_Array(1..Len);
   begin

      for X in Buf'Range loop
         Buf(X) := Rand_U8;
      end loop;
      return Buf;

   end Rand_Bytes;

   -------------------------------------------------------------------
   -- Print Message and Raise "Failed" Exception
   -------------------------------------------------------------------
   procedure Failed(Msg : String) is
   begin
      New_Line;
      Put("Operation Failed: ");
      Put_Line(Msg);
      Flush;
      raise Failure;
   end Failed;

   -------------------------------------------------------------------
   -- Report Success or Failure
   -------------------------------------------------------------------
   procedure Report(What : String; OK : Boolean) is
   begin
      if OK then
         Put_Line("OK.");
      else
         Failed(What);
      end if;
   end Report;

   -------------------------------------------------------------------
   -- Report Failure if not OK
   -------------------------------------------------------------------
   procedure Report_Failed(What : String; OK : Boolean) is
   begin
      if not OK then
         Failed(What);
      end if;
   end Report_Failed;

   -------------------------------------------------------------------
   -- Generate a FAT Filename from a File Number
   -------------------------------------------------------------------
   function Test_Filename(File_No : Unsigned_16; Suffix : String) return String is
      As_No :  String := Unsigned_16'Image(File_No);
      Name :   String := "00000000";
   begin

      Name(Name'First+Name'Length-(As_No'Length-1)..Name'Last) := As_No(As_No'First+1..As_No'Last);
      if Suffix = "" then
         return Name;
      else
         return Name & "." & Suffix;
      end if;

   end Test_Filename;

   -------------------------------------------------------------------
   -- Create and Write a 1 Sector File
   -------------------------------------------------------------------
   procedure Create_1S_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      E :      Dir_Entry_Type;
      File :   WCB_Type;
      Block :  Block_512 := ( others => Unsigned_8(File_No mod 256) );
      Name :   String := Test_Filename(File_No,"DAT");
      OK :     Boolean;
   begin

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      if Should_Succeed then
         pragma assert(OK);
         null;
      else
         Report_Failed("Create should fail because dir should be full.",not OK);
         Close_Dir(Root);
         return;
      end if;

      Write_File(File,Block,512,OK);
      pragma assert(OK);

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = 512);
      Close_Dir(Root);

   end Create_1S_File;

   -------------------------------------------------------------------
   -- Open and Read 1 Sector File and Check its Content
   -------------------------------------------------------------------
   procedure Check_1S_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      File :   FCB_Type;
      Block :  Block_512 := ( others => 0 );
      Count :  Unsigned_16 := 0;
      Name :   String := Test_Filename(File_No,"DAT");
      Byte :   Unsigned_8 := Unsigned_8(File_No mod 256);
      OK :     Boolean;
   begin

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      Read_File(File,Block,Count,OK);
      pragma assert(OK);
      pragma assert(Count = 512);

      for X in Block'Range loop
         OK := Byte = Block(X);
         pragma assert(OK);
      end loop;

      Read_File(File,Block,Count,OK);
      pragma assert(not OK);              -- Should be end of file
      pragma assert(Count = 0);

      Close_File(File);
      Close_Dir(Root);

   end Check_1S_File;

   -------------------------------------------------------------------
   -- Delete Root File by Number
   -------------------------------------------------------------------
   procedure Delete_File(File_No : Unsigned_16) is
      Root :   DCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      OK :     Boolean;
   begin

      Open_Dir(Root,OK);
      pragma assert(OK);

      Delete_File(Root,Name,OK);
      if not OK then
         PUT_LINE("OOPS!!");        -- DELETE ME
      end if;
      pragma assert(OK);
      
      Close_Dir(Root);

   end Delete_File;

   -------------------------------------------------------------------
   -- Create and Write a Multi-Sectored File
   -------------------------------------------------------------------
   procedure Create_MS_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      E :      Dir_Entry_Type;
      File :   WCB_Type;
      Block :  Block_512;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_8;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No));
      Count := R8.Random(Gen8) mod Unsigned_8(Sects_Per_Cluster*2+2);

      T_Min := Unsigned_32'Min(T_Min,Unsigned_32(Count));
      T_Max := Unsigned_32'Max(T_Max,Unsigned_32(Count));

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      if Should_Succeed then
         pragma assert(OK);
         null;
      else
         Report_Failed("Create should fail because dir should be full.",not OK);
         Close_Dir(Root);
         return;
      end if;
      
      for X in 1..Count loop
         for Y in Block'Range loop
            Block(Y) := R8.Random(Gen8);
         end loop;
         Write_File(File,Block,512,OK);
         pragma assert(OK);
      end loop;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Unsigned_32(Count) * 512);
      Close_Dir(Root);

   end Create_MS_File;

   -------------------------------------------------------------------
   -- Open and Read Multi-Sector File and Check its Content
   -------------------------------------------------------------------
   procedure Check_MS_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      File :   FCB_Type;
      Block :  Block_512 := ( others => 0 );
      Count :  Unsigned_16 := 0;
      Name :   String := Test_Filename(File_No,"DAT");
      Check :  Unsigned_8;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No));
      Check := R8.Random(Gen8) mod Unsigned_8(Sects_Per_Cluster*2+2);

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Check loop
         Read_File(File,Block,Count,OK);
         pragma assert(OK);
         pragma assert(Count = 512);

         for Y in Block'Range loop
            OK := Block(Y) = R8.Random(Gen8);
            pragma assert(OK);
         end loop;
      end loop;

      Read_File(File,Block,Count,OK);
      pragma assert(not OK);              -- Should be end of file
      pragma assert(Count = 0);

      Close_File(File);
      Close_Dir(Root);

   end Check_MS_File;

   -------------------------------------------------------------------
   -- Create and Write a Variable Length File
   -------------------------------------------------------------------
   procedure Create_VL_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      E :      Dir_Entry_Type;
      File :   WCB_Type;
      Block :  Block_512;
      Name :   String := Test_Filename(File_No,"DAT");
      Bytes :  Unsigned_32;
      Count :  Unsigned_16;
      X :      Unsigned_16 := 0;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No+1));
      R16.Reset(Gen16,Integer(File_No+1));
      Bytes := Unsigned_32(R16.Random(Gen16)) mod (Unsigned_32(Sects_Per_Cluster*2+2) * 512);

      T_Min := Unsigned_32'Min(T_Min,Bytes);
      T_Max := Unsigned_32'Max(T_Max,Bytes);

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      if Should_Succeed then
         pragma assert(OK);
         null;
      else
         Report_Failed("Create should fail because dir should be full.",not OK);
         Close_Dir(Root);
         return;
      end if;

      loop
         if X > 0 and then ( ( Unsigned_32(X) >= Bytes ) or else ( X mod 512 = 0 ) ) then
            Count := X mod 512;
            if Count = 0 then
               Count := 512;
            end if;
            Write_File(File,Block,Count,OK);
            pragma assert(OK);
         end if;
         exit when Unsigned_32(X) >= Bytes;

         Block(X mod 512) := R8.Random(Gen8);
         X := X + 1;
      end loop;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Root);

   end Create_VL_File;

   -------------------------------------------------------------------
   -- Open and Read Multi-Sector File and Check its Content
   -------------------------------------------------------------------
   procedure Check_VL_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Root :   DCB_Type;
      File :   FCB_Type;
      Block :  Block_512 := ( others => 0 );
      Count :  Unsigned_16 := 0;
      Name :   String := Test_Filename(File_No,"DAT");
      Bytes :  Unsigned_32;
      Byte :   Unsigned_8;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No+1));
      R16.Reset(Gen16,Integer(File_No+1));
      Bytes := Unsigned_32(R16.Random(Gen16)) mod (Unsigned_32(Sects_Per_Cluster*2+2) * 512);

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Bytes loop
         if ( X - 1 ) mod 512 = 0 then
            Read_File(File,Block,Count,OK);
            pragma assert(OK);

            if Count < 512 then
               OK := Unsigned_32(Count) + X - 1 = Bytes;
               pragma assert(OK);
            else
               OK := Count = 512;
               pragma assert(OK);
            end if;
         end if;

         Byte := R8.Random(Gen8);
         OK := Block(Unsigned_16(X-1) mod 512) = Byte;
         pragma assert(OK);
      end loop;

      if Count < 512 then
         Read_File(File,Block,Count,OK);
         pragma assert(not OK);              -- Should be end of file
         pragma assert(Count = 0);
      end if;

      Close_File(File);
      Close_Dir(Root);

   end Check_VL_File;

   -------------------------------------------------------------------
   -- Create and Write a Text File
   -------------------------------------------------------------------
   procedure Create_TX_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TWCB_Type;
      E :      Dir_Entry_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Bytes :  Unsigned_32 := 0;
      OK :     Boolean;
   begin

      if not Should_Succeed then
         return;                             -- Skip this test
      end if;

      R8.Reset(Gen8,Integer(File_No+2));
      R16.Reset(Gen16,Integer(File_No+2));
      Count := Rand_U16 mod Count_Max + 1;   -- # of text lines to write

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      if Should_Succeed then
         pragma assert(OK);
         null;
      else
         Report_Failed("Create should fail because dir should be full.",not OK);
         Close_Dir(Root);
         return;
      end if;

      for X in 1..Count loop
         declare
            Line : String := Rand_String;
         begin
            Bytes := Bytes + Line'Length + 2;

            Put_Line(File,Line,OK);
            if not OK then
               if Free_Space = 0 then
                  Failed("OUT OF DISK SPACE FOR FILE " & Name);
                  Put("Writing line ");
                  U16.Put(X);
                  Put(" of ");
                  U16.Put(Count);
                  New_Line;
               end if;
            end if;
            pragma assert(OK);

            T_Min := Unsigned_32'Min(T_Min,Unsigned_32(Line'Length));
            T_Max := Unsigned_32'Max(T_Max,Unsigned_32(Line'Length));
         end;
      end loop;

      if Rand_U16 mod 2 /= 0 then
         Sync_File(File,OK);
         Rewind_Dir(Root);
         Search_Dir(Root,E,Name,OK);
         pragma assert(OK);
         pragma assert(Name = Filename(E));
         pragma assert(E.File_Size = Bytes);
      end if;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Root);

   end Create_TX_File;

   -------------------------------------------------------------------
   -- Open and Read Text File and Check its Content
   -------------------------------------------------------------------
   procedure Check_TX_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TFCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Temp :   Unsigned_16;
      Line :   String(1..80);
      Last :   Natural;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No+2));
      R16.Reset(Gen16,Integer(File_No+2));
      Count := Rand_U16 mod Count_Max + 1;      -- # of text lines expected

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Count loop
         declare
            Cmp_Line : String := Rand_String;
         begin
            Read_Line(File,Line,Last,OK);
            if not OK then
               Failed("Read_Line Not OK: " & Name);
            end if;
            pragma assert(OK);
            pragma assert(Line(1..Last) = Cmp_Line);
         end;
      end loop;

      Read_Line(File,Line,Last,OK);
      if OK then
         Put_Line("Should have failed: " & Name);
      end if;

      pragma assert(not OK);

      Rewind_File(File);
      R8.Reset(Gen8,Integer(File_No+2));
      R16.Reset(Gen16,Integer(File_No+2));
      Temp := Rand_U16 mod Count_Max + 1;
      pragma assert(Temp = Count);

      for X in 1..Count loop
         declare
            Cmp_Line : String := Rand_String;
         begin
            Read_Line(File,Line,Last,OK);
            pragma assert(OK);
            pragma assert(Line(1..Last) = Cmp_Line);
         end;
      end loop;

      Read_Line(File,Line,Last,OK);
      pragma assert(not OK);

      Close_File(File);
      Close_Dir(Root);

   end Check_TX_File;

   -------------------------------------------------------------------
   -- Create and Write a Binary String File
   -------------------------------------------------------------------
   procedure Create_BS_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TWCB_Type;
      E :      Dir_Entry_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Bytes :  Unsigned_32 := 0;
      OK, OK2 : Boolean;
   begin

      if not Should_Succeed then
         return;                             -- Skip this test
      end if;

      R8.Reset(Gen8,Integer(File_No+3));
      R16.Reset(Gen16,Integer(File_No+3));
      Count := Rand_U16 mod Count_Max + 1;   -- # of binary records to write

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      pragma assert(OK);

      for X in 1..Count loop
         declare
            Recd : U8_Array := Rand_Bytes(256);
         begin
            Bytes := Bytes + Recd'Length + 1;

            Write(File,Unsigned_8(Recd'Length),OK);
            Write(File,Recd,OK2);
            if not OK or not OK2 then
               if Free_Space = 0 then
                  Failed("OUT OF DISK SPACE FOR FILE " & Name);
                  Put("Writing binary string ");
                  U16.Put(X);
                  Put(" of ");
                  U16.Put(Count);
                  New_Line;
               end if;
            end if;
            pragma assert(OK and OK2);
         end;
      end loop;

      if Rand_U16 mod 2 /= 0 then
         Sync_File(File,OK);
         Rewind_Dir(Root);
         Search_Dir(Root,E,Name,OK);
         pragma assert(OK);
         pragma assert(Name = Filename(E));
         pragma assert(E.File_Size = Bytes);
      end if;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Root);

   end Create_BS_File;

   -------------------------------------------------------------------
   -- Open and Read Binary String File and Check its Content
   -------------------------------------------------------------------
   procedure Check_BS_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TFCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Temp :   Unsigned_16;
      OK :     Boolean;
      Recd :   U8_Array(1..256);
      Len :    Unsigned_8;
      K :      Unsigned_16;
   begin

      R8.Reset(Gen8,Integer(File_No+3));
      R16.Reset(Gen16,Integer(File_No+3));
      Count := Rand_U16 mod Count_Max + 1;      -- # of text lines expected

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Count loop
         Read(File,Len,OK);
         if OK then
            Read(File,Recd(1..Unsigned_16(Len)),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Unsigned_16(Len));

         declare
            Cmp : U8_Array := Rand_Bytes(256);
         begin
            OK := Recd(1..Unsigned_16(Len)) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      if OK then
         Put_Line("Should have failed: " & Name);
      end if;

      pragma assert(not OK);
      pragma assert(K=0);

      Rewind_File(File);
      R8.Reset(Gen8,Integer(File_No+3));
      R16.Reset(Gen16,Integer(File_No+3));
      Temp := Rand_U16 mod Count_Max + 1;
      pragma assert(Temp = Count);

      for X in 1..Count loop
         Read(File,Len,OK);

         if OK then
            Read(File,Recd(1..Unsigned_16(Len)),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Unsigned_16(Len));

         declare
            Cmp : U8_Array := Rand_Bytes(256);
         begin
            OK := Recd(1..Unsigned_16(Len)) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      pragma assert(not OK);
      pragma assert(K=0);

      Close_File(File);
      Close_Dir(Root);

   end Check_BS_File;

   -------------------------------------------------------------------
   -- Create and Write a Binary String File using U16
   -------------------------------------------------------------------
   procedure Create_B2_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TWCB_Type;
      E :      Dir_Entry_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Bytes :  Unsigned_32 := 0;
      OK, OK2 : Boolean;
   begin

      if not Should_Succeed then
         return;                             -- Skip this test
      end if;

      R8.Reset(Gen8,Integer(File_No+4));
      R16.Reset(Gen16,Integer(File_No+4));
      Count := Rand_U16 mod Count_Max + 1;   -- # of binary records to write

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      pragma assert(OK);

      for X in 1..Count loop
         declare
            Recd : U8_Array := Rand_Bytes(600);
         begin
            Bytes := Bytes + Recd'Length + 2;

            Write(File,Unsigned_16(Recd'Length),OK);
            Write(File,Recd,OK2);
            if not OK or not OK2 then
               if Free_Space = 0 then
                  Failed("OUT OF DISK SPACE FOR FILE " & Name);
                  Put("Writing binary string ");
                  U16.Put(X);
                  Put(" of ");
                  U16.Put(Count);
                  New_Line;
               end if;
            end if;
            pragma assert(OK and OK2);
         end;
      end loop;

      if Rand_U16 mod 2 /= 0 then
         Sync_File(File,OK);
         Rewind_Dir(Root);
         Search_Dir(Root,E,Name,OK);
         pragma assert(OK);
         pragma assert(Name = Filename(E));
         pragma assert(E.File_Size = Bytes);
      end if;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Root);

   end Create_B2_File;

   -------------------------------------------------------------------
   -- Open and Read Binary String (U16) File and Check its Content
   -------------------------------------------------------------------
   procedure Check_B2_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TFCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Temp :   Unsigned_16;
      OK :     Boolean;
      Recd :   U8_Array(1..600);
      Len :    Unsigned_16;
      K :      Unsigned_16;
   begin

      R8.Reset(Gen8,Integer(File_No+4));
      R16.Reset(Gen16,Integer(File_No+4));
      Count := Rand_U16 mod Count_Max + 1;      -- # of text lines expected

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Count loop
         Read(File,Len,OK);
         if OK then
            Read(File,Recd(1..Len),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Len);

         declare
            Cmp : U8_Array := Rand_Bytes(600);
         begin
            OK := Recd(1..Len) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      if OK then
         Put_Line("Should have failed: " & Name);
      end if;

      pragma assert(not OK);
      pragma assert(K=0);

      Rewind_File(File);
      R8.Reset(Gen8,Integer(File_No+4));
      R16.Reset(Gen16,Integer(File_No+4));
      Temp := Rand_U16 mod Count_Max + 1;
      pragma assert(Temp = Count);

      for X in 1..Count loop
         Read(File,Len,OK);

         if OK then
            Read(File,Recd(1..Len),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Len);

         declare
            Cmp : U8_Array := Rand_Bytes(600);
         begin
            OK := Recd(1..Len) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      pragma assert(not OK);
      pragma assert(K=0);

      Close_File(File);
      Close_Dir(Root);

   end Check_B2_File;

   -------------------------------------------------------------------
   -- Create and Write a Binary String File using U32
   -------------------------------------------------------------------
   procedure Create_B4_File(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TWCB_Type;
      E :      Dir_Entry_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Bytes :  Unsigned_32 := 0;
      OK, OK2 : Boolean;
   begin

      if not Should_Succeed then
         return;                             -- Skip this test
      end if;

      R8.Reset(Gen8,Integer(File_No+5));
      R16.Reset(Gen16,Integer(File_No+5));
      Count := Rand_U16 mod Count_Max + 1;   -- # of binary records to write

      Open_Dir(Root,OK);
      pragma assert(OK);

      Create_File(File,Root,Name,OK);
      pragma assert(OK);

      for X in 1..Count loop
         declare
            Recd : U8_Array := Rand_Bytes(600);
         begin
            Bytes := Bytes + Recd'Length + 4;

            Write(File,Unsigned_32(Recd'Length),OK);
            Write(File,Recd,OK2);
            if not OK or not OK2 then
               if Free_Space = 0 then
                  Failed("OUT OF DISK SPACE FOR FILE " & Name);
                  Put("Writing binary string ");
                  U16.Put(X);
                  Put(" of ");
                  U16.Put(Count);
                  New_Line;
               end if;
            end if;
            pragma assert(OK and OK2);
         end;
      end loop;

      if Rand_U16 mod 2 /= 0 then
         Sync_File(File,OK);
         Rewind_Dir(Root);
         Search_Dir(Root,E,Name,OK);
         pragma assert(OK);
         pragma assert(Name = Filename(E));
         pragma assert(E.File_Size = Bytes);
      end if;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Root);
      Search_Dir(Root,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Root);

   end Create_B4_File;

   -------------------------------------------------------------------
   -- Open/Close a File to Check Existance:
   -------------------------------------------------------------------
   procedure Open_Check(File_No : Unsigned_16) is
      Root :   DCB_Type;
      File :   FCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      OK :     Boolean;
   begin

      Open_Dir(Root,OK);
      pragma Assert(OK);

      Open_File(File,Root,Name,OK);
      pragma Assert(OK);

      Close_File(File);
      Close_Dir(Root);

   end Open_Check;

   -------------------------------------------------------------------
   -- Open and Read Binary String (U32) File and Check its Content
   -------------------------------------------------------------------
   procedure Check_B4_File(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32) is
      Count_Max : Unsigned_16 := Unsigned_16(Sects_Per_Cluster);
      Root :   DCB_Type;
      File :   TFCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Temp :   Unsigned_16;
      OK :     Boolean;
      Recd :   U8_Array(1..600);
      Len :    Unsigned_32;
      K :      Unsigned_16;
   begin

      R8.Reset(Gen8,Integer(File_No+5));
      R16.Reset(Gen16,Integer(File_No+5));
      Count := Rand_U16 mod Count_Max + 1;      -- # of text lines expected

      Open_Dir(Root,OK);
      pragma assert(OK);

      Open_File(File,Root,Name,OK);
      pragma assert(OK);
      
      for X in 1..Count loop
         Read(File,Len,OK);
         if OK then
            Read(File,Recd(1..Unsigned_16(Len)),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Unsigned_16(Len));

         declare
            Cmp : U8_Array := Rand_Bytes(600);
         begin
            OK := Recd(1..Unsigned_16(Len)) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      if OK then
         Put_Line("Should have failed: " & Name);
      end if;

      pragma assert(not OK);
      pragma assert(K=0);

      Rewind_File(File);
      R8.Reset(Gen8,Integer(File_No+5));
      R16.Reset(Gen16,Integer(File_No+5));
      Temp := Rand_U16 mod Count_Max + 1;
      pragma assert(Temp = Count);

      for X in 1..Count loop
         Read(File,Len,OK);

         if OK then
            Read(File,Recd(1..Unsigned_16(Len)),K,OK);
         end if;

         if not OK then
            Failed("Read Not OK: " & Name);
         end if;

         pragma assert(OK);
         pragma assert(K=Unsigned_16(Len));

         declare
            Cmp : U8_Array := Rand_Bytes(600);
         begin
            OK := Recd(1..Unsigned_16(Len)) = Cmp;
            pragma assert(OK);
         end;
      end loop;

      Read(File,Recd,K,OK);
      pragma assert(not OK);
      pragma assert(K=0);

      Close_File(File);
      Close_Dir(Root);

   end Check_B4_File;

   -------------------------------------------------------------------
   -- Create A Randomized Subdirectory Path
   -------------------------------------------------------------------

   procedure Random_Make_Subdir(Dir : out DCB_Type; Levels_Max : Natural) is
      OK :     Boolean;
      Count :  Natural := 0;
      R :      Unsigned_16;
   begin

      Open_Dir(Dir,OK);
      pragma assert(OK);

      loop
         exit when Count >= Levels_Max;

         Count := Count + 1;

         R := ( Unsigned_16(Rand_U8) mod 101 ) + 9_000;
         exit when R = 9_100;

         declare
            Dir_Name : String := Test_Filename(R,"DIR");
         begin
            Open_Dir(Dir,Dir_Name,OK);
            if not OK then
               Create_Subdir(Dir,Dir_Name,Ok);
               pragma Assert(OK);
               Open_Dir(Dir,Dir_Name,OK);
               pragma Assert(OK);
            end if;
         end;

      end loop;

   end Random_Make_Subdir;

   -------------------------------------------------------------------
   -- Open a Randomized Subdirectory Path
   -------------------------------------------------------------------

   procedure Random_Change_Subdir(Dir : out DCB_Type; Levels_Max : Natural) is
      OK :     Boolean;
      Count :  Natural := 0;
      R :      Unsigned_16;
   begin

      Open_Dir(Dir,OK);
      pragma assert(OK);

      loop
         exit when Count >= Levels_Max;

         Count := Count + 1;

         R := ( Unsigned_16(Rand_U8) mod 101 ) + 9_000;
         exit when R = 9_100;

         declare
            Dir_Name : String := Test_Filename(R,"DIR");
         begin
            Open_Dir(Dir,Dir_Name,OK);
            pragma Assert(OK);
         end;

      end loop;

   end Random_Change_Subdir;

   -------------------------------------------------------------------
   -- Create and Write a Text File (in a Subdirectory)
   -------------------------------------------------------------------
   procedure Create_SD_File(File_No : Unsigned_16) is
      Count_Max : Unsigned_16 := 300;
      Dir :    DCB_Type;
      File :   TWCB_Type;
      E :      Dir_Entry_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Bytes :  Unsigned_32 := 0;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No+99));
      R16.Reset(Gen16,Integer(File_No+99));
      Count := Rand_U16 mod Count_Max + 1;   -- # of text lines to write

      Random_Make_Subdir(Dir,10);            -- Create Random Subdir

      Create_File(File,Dir,Name,OK);
      pragma assert(OK);

      for X in 1..Count loop
         declare
            Line : String := Rand_String;
         begin
            Bytes := Bytes + Line'Length + 2;

            Put_Line(File,Line,OK);
            if not OK then
               if Free_Space = 0 then
                  Failed("OUT OF DISK SPACE FOR FILE " & Name);
                  Put("Writing line ");
                  U16.Put(X);
                  Put(" of ");
                  U16.Put(Count);
                  New_Line;
               end if;
            end if;
            pragma assert(OK);
         end;
      end loop;

      Close_File(File,OK);
      pragma assert(OK);

      Rewind_Dir(Dir);
      Search_Dir(Dir,E,Name,OK);
      pragma assert(OK);
      pragma assert(Name = Filename(E));
      pragma assert(E.File_Size = Bytes);
      Close_Dir(Dir);

   end Create_SD_File;

   -------------------------------------------------------------------
   -- Open and Read Text File and Check its Content (in Subdir)
   -------------------------------------------------------------------
   procedure Check_SD_File(File_No : Unsigned_16) is
      Count_Max : Unsigned_16 := 300;
      Dir :    DCB_Type;
      File :   TFCB_Type;
      Name :   String := Test_Filename(File_No,"DAT");
      Count :  Unsigned_16;
      Temp :   Unsigned_16;
      Line :   String(1..80);
      Last :   Natural;
      OK :     Boolean;
   begin

      R8.Reset(Gen8,Integer(File_No+99));
      R16.Reset(Gen16,Integer(File_No+99));
      Count := Rand_U16 mod Count_Max + 1;      -- # of text lines expected

      Random_Change_Subdir(Dir,10);

      Open_File(File,Dir,Name,OK);
      pragma assert(OK);
      
      for X in 1..Count loop
         declare
            Cmp_Line : String := Rand_String;
         begin
            Read_Line(File,Line,Last,OK);
            if not OK then
               Failed("Read_Line Not OK: " & Name);
            end if;
            pragma assert(OK);
            pragma assert(Line(1..Last) = Cmp_Line);
         end;
      end loop;

      Read_Line(File,Line,Last,OK);
      if OK then
         Put_Line("Should have failed: " & Name);
      end if;

      pragma assert(not OK);

      Rewind_File(File);

      R8.Reset(Gen8,Integer(File_No+99));
      R16.Reset(Gen16,Integer(File_No+99));
      Temp := Rand_U16 mod Count_Max + 1;
      pragma assert(Temp = Count);

      Close_Dir(Dir);
      Random_Change_Subdir(Dir,10);             -- Necessary to track random # generator

      for X in 1..Count loop
         declare
            Cmp_Line : String := Rand_String;
         begin
            Read_Line(File,Line,Last,OK);
            pragma assert(OK);
            pragma assert(Line(1..Last) = Cmp_Line);
         end;
      end loop;

      Read_Line(File,Line,Last,OK);
      pragma assert(not OK);

      Close_File(File);
      Close_Dir(Dir);

   end Check_SD_File;

   -------------------------------------------------------------------
   -- Return The Number Of Entries To Test With
   -------------------------------------------------------------------

   function No_Test_Entries return Unsigned_16 is
   begin

      if File_System = FS_FAT16 then
         return FS_Root_Entries;
      else
         return 512;
      end if;

   end No_Test_Entries;

   -------------------------------------------------------------------
   -- Apply File Tests - Form 1 -- Root Directory Only
   -------------------------------------------------------------------

   type Test_Proc_1 is access
      procedure(File_No : Unsigned_16; Should_Succeed : Boolean; Sects_Per_Cluster : Unsigned_32);

   type Check_Proc_1 is access
      procedure(File_No : Unsigned_16; Sects_Per_Cluster : Unsigned_32);

   procedure File_Test_1(Test : Test_Proc_1; Check : Check_Proc_1; Sects_Per_Cluster : Unsigned_32; Units, What : String) is
      OK :     Boolean;
      Root :   DCB_Type;
      E :      Dir_Entry_Type;
   begin

      T_Min := Unsigned_32'Last;
      T_Max := Unsigned_32'First;

      Put("  Creating " & What & " Files.. ");
      U16.Put(No_Test_Entries);
      
      for X in 1..No_Test_Entries loop
         Test(X,True,Sects_Per_Cluster);
      end loop;

      Put_Line(" OK.");

      if Sects_Per_Cluster /= 0 and Units /= "" then
         Put("  Min ............... ");
         U32.Put(T_Min);
         Put(" " & Units);
         New_Line;
      
         Put("  Max ............... ");
         U32.Put(T_Max);
         Put(" " & Units);
         New_Line;
      end if;

      if File_System = FS_FAT16 then
         Test(No_Test_Entries+1,False,Sects_Per_Cluster);     -- This should fail (dir is full)
      end if;

      ----------------------------------------------------------------
      -- Now Open and Read Check Each File
      ----------------------------------------------------------------
      Put("  Checking " & What & " Files.. ");
      U16.Put(No_Test_Entries);
      
      if What /= "TX" then
         for X in 1..No_Test_Entries loop
            Check(X,Sects_Per_Cluster);
         end loop;
      else
         for X in reverse 1..No_Test_Entries loop           -- Check in reverse order
            Check(X,Sects_Per_Cluster);
         end loop;
      end if;

      Put_Line(" OK.");

      Open_Dir(Root,OK);
      pragma Assert(OK);
      Search_Dir(Root,E,Test_Filename(No_Test_Entries+1,"DAT"),OK);
      pragma assert(not OK);                       -- This file should not exist

      ----------------------------------------------------------------
      -- Report Free Space
      ----------------------------------------------------------------

      Put("  Free Space Now..... ");
      U32.Put(Free_Space);
      Put_Line(" bytes.");
      pragma assert(Free_Space < Space);

      ----------------------------------------------------------------
      -- Delete All Created Files
      ----------------------------------------------------------------
      Put("  Deleting Files..... ");
      U16.Put(No_Test_Entries);
      
      for X in 1..No_Test_Entries loop
         Open_Check(X);
      end loop;

      for X in 1..No_Test_Entries loop
         Open_Check(X);
         Delete_File(X);
      end loop;

      Put_Line(" OK.");

      ----------------------------------------------------------------
      -- Check Free Space
      ----------------------------------------------------------------

      Put("  Free Space Now..... ");
      U32.Put(Free_Space);
      Put_Line(" bytes.");

      if File_System = FS_FAT16 then
         pragma assert(Space = Free_Space);
         null;
      else
         -- Allow for root directory growth (512 entries => 32 sectors)
         pragma assert(Free_Space + 31 * 512 >= Space);
         null;
      end if;

   end File_Test_1;

   -------------------------------------------------------------------
   -- Apply File Tests - Form 2 - In Random Subdirectories
   -------------------------------------------------------------------

   procedure File_Test_2(Sects_Per_Cluster : Unsigned_32) is
      OK :     Boolean;
      Dir : DCB_Type;
      E :      Dir_Entry_Type;
   begin

      T_Min := Unsigned_32'Last;
      T_Max := Unsigned_32'First;

      Put("  Creating SD Files..    512");
      
      for X in 1..Unsigned_16(512) loop
         Create_SD_File(X);
      end loop;

      Put_Line(" OK.");

      ----------------------------------------------------------------
      -- Now Open and Read Check Each File
      ----------------------------------------------------------------
      Put("  Checking SD Files..    512");
      
      for X in 1..Unsigned_16(512) loop
         Check_SD_File(X);
      end loop;

      Put_Line(" OK.");

      ----------------------------------------------------------------
      -- Report Free Space
      ----------------------------------------------------------------

      Put("  Free Space Now..... ");
      U32.Put(Free_Space);
      Put_Line(" bytes.");
      pragma assert(Free_Space < Space);

      ----------------------------------------------------------------
      -- Delete All Created Files
      ----------------------------------------------------------------
      Put_Line("  Deleting Files.....    512:");
      
      Open_Dir(Dir,OK);
      pragma Assert(OK);

      Get_Dir_Entry(Dir,E,OK);

      loop
         exit when not OK;
         
         declare
            Name : String := Filename(E);
         begin
            if not E.Subdirectory then
               Put("  Deleting file ");
               Put(Name);
      
               Delete_File(Dir,Name,OK);
               pragma Assert(OK);
               Put_Line(" OK");
            else
               Put("  Deleting subdirectory ");
               Put(Name);

               Delete_Subdir(Dir,Name,OK);
               pragma Assert(OK);
               Put_Line(" OK");
            end if;
         end;

         Next_Dir_Entry(Dir,E,OK);
      end loop;

      Put_Line(" All Deletes OK.");

      ----------------------------------------------------------------
      -- Check Free Space
      ----------------------------------------------------------------

      Put("  Free Space Now..... ");
      U32.Put(Free_Space);
      Put_Line(" bytes.");

      if File_System = FS_FAT16 then
         pragma assert(Space = Free_Space);
         null;
      else
         -- Allow for root directory growth (512 entries => 32 sectors)
         pragma assert(Free_Space + 31 * 512 >= Space);
         null;
      end if;

      Close_Dir(Dir);

   end File_Test_2;

   -------------------------------------------------------------------
   -- Perform the FAT16 Test Suite
   -------------------------------------------------------------------
   procedure FAT16_Suite(Sectors, Sects_Per_Cluster, Root_Entries, FATs, Reserved : Unsigned_32) is
      OK :     Boolean;
      Root :   DCB_Type;
      E :      Dir_Entry_Type;

      TX_Count, BS_Count, B9_Count : Unsigned_32;
   begin

      AdaDIO.Open("fatfs.img",For_Write => True, Create => True);

      FAT16_Suite_No    := FAT16_Suite_No + 1;

      Put("FAT16 TEST SUITE..... ");
      U32.Put(FAT16_Suite_No);
      New_Line;

      Put("  Media.............. ");
      U32.Put(Sectors);
      Put_Line(" sectors.");

      Put("  Sectors/Cluster.... ");
      U32.Put(Sects_Per_Cluster);
      New_Line;

      Put("  Root Dir Entries... ");
      U32.Put(Root_Entries);
      New_Line;

      Put("  FAT Tables......... ");
      U32.Put(FATs);
      New_Line;

      Put("  Reserved Sectors... ");
      U32.Put(Reserved);
      Put_Line(" sectors.");

      ----------------------------------------------------------------
      -- Format the File System
      ----------------------------------------------------------------
      New_Line;
      Put("  Formatting......... ");

      FATFS.Format(
         Total_Sectors        => Sector_Type(Sectors),
         Sectors_Per_Cluster  => Unsigned_8(Sects_Per_Cluster),
         Root_Dir_Entries_16  => Unsigned_16(Root_Entries),
         OEM_Name             => "XFAT16",
         No_Of_FATs           => FAT_Copies_Type(FATs),
         OK                   => OK
      );

      Report("Format",OK);

      ----------------------------------------------------------------
      -- Open the File System
      ----------------------------------------------------------------
      Put("  Opening FS......... ");
      FATFS.Open_FS(OK);
      Report("FS Open",OK);

      ----------------------------------------------------------------
      -- Check that the created FS is FAT16
      ----------------------------------------------------------------
      Put("  FS Type............ ");
      Put(FS_Type'Image(File_System));
      if File_System = FS_FAT16 then
         Put_Line(" OK.");
      else
         New_Line;
         Report("File system type",False);
      end if;

      ----------------------------------------------------------------
      -- Check the OEM Name
      ----------------------------------------------------------------
      Put("  OEM Name........... ");
      Put(OEM_Name);
      if OEM_Name = "XFAT16  " then
         Put_Line("OK.");
      else
         New_Line;
         Report("OEM Name",False);
      end if;

      ----------------------------------------------------------------
      -- Check Basic File Sytem Paramters
      ----------------------------------------------------------------
      Report_Failed("Root Entries",No_Test_Entries = Unsigned_16(Root_Entries));
      Report_Failed("Sectors/Cluster",FS_Sectors_Per_Cluster = Unsigned_16(Sects_Per_Cluster));
   
      Put("  Total Clusters..... ");
      U32.Put(FS_Clusters);
      New_Line;
      pragma assert(FS_Clusters > 0);

      Space := Free_Space;                      -- Save amount of free space available in bytes
      Put("  Free Space......... ");
      U32.Put(Space);
      Put_Line(" bytes.");

      ----------------------------------------------------------------
      -- Check that root dir is empty (and has no . or .. entry)
      ----------------------------------------------------------------
      Open_Dir(Root,OK);
      pragma assert(OK);
      Get_Dir_Entry(Root,E,OK);
      pragma assert(not OK);
      Close_Dir(Root);

      if Root_Entries <= 512 then
         TX_Count := 600;
         BS_Count := 500;
         B9_Count := 100;
      elsif Root_Entries <= 1024 then
         TX_Count := 300;
         BS_Count := 200;
         B9_Count :=  50;
      else
         TX_Count := 200;
         BS_Count := 100;
         B9_Count :=  20;
      end if;

      File_Test_1(Create_1S_File'Access,Check_1S_File'Access,0,"","1S");
      File_Test_1(Create_MS_File'Access,Check_MS_File'Access,Sects_Per_Cluster,"Sectors","MS");
      File_Test_1(Create_VL_File'Access,Check_VL_File'Access,Sects_Per_Cluster,"Bytes","VL");
      File_Test_1(Create_TX_File'Access,Check_TX_File'Access,TX_Count,"Bytes","TX");
      File_Test_1(Create_BS_File'Access,Check_BS_File'Access,BS_Count,"","BS");
      File_Test_1(Create_B2_File'Access,Check_B2_File'Access,B9_Count,"","B2");
      File_Test_1(Create_B4_File'Access,Check_B4_File'Access,B9_Count,"","B4");
      File_Test_2(Sects_Per_Cluster);
      
      ----------------------------------------------------------------
      -- Close File System
      ----------------------------------------------------------------
      Put("  Closing FS......... ");
      FATFS.Close_FS;
      Report("FS Close",True);

      AdaDIO.Close;

      New_Line;
      
   exception
      when Failure =>
         AdaDIO.Close;
         raise;

   end FAT16_Suite;

   -------------------------------------------------------------------
   -- Perform the FAT32 Test Suite
   -------------------------------------------------------------------
   procedure FAT32_Suite(Sectors, Sects_Per_Cluster, FATs, Reserved : Unsigned_32) is
      Root_Entries : Unsigned_32 := 512;
      OK :     Boolean;
      Root :   DCB_Type;
      E :      Dir_Entry_Type;

      TX_Count, BS_Count, B9_Count : Unsigned_32;
   begin

      AdaDIO.Open("fatfs.img",For_Write => True, Create => True);

      FAT32_Suite_No    := FAT32_Suite_No + 1;

      Put("FAT32 TEST SUITE..... ");
      U32.Put(FAT32_Suite_No);
      New_Line;

      Put("  Media.............. ");
      U32.Put(Sectors);
      Put_Line(" sectors.");

      Put("  Sectors/Cluster.... ");
      U32.Put(Sects_Per_Cluster);
      New_Line;

      Put("  Root Dir Entries... ");
      U32.Put(Root_Entries);
      New_Line;

      Put("  FAT Tables......... ");
      U32.Put(FATs);
      New_Line;

      Put("  Reserved Sectors... ");
      U32.Put(Reserved);
      Put_Line(" sectors.");

      ----------------------------------------------------------------
      -- Format the File System
      ----------------------------------------------------------------
      New_Line;
      Put("  Formatting......... ");

      FATFS.Format(
         Total_Sectors        => Sector_Type(Sectors),
         Sectors_Per_Cluster  => Unsigned_8(Sects_Per_Cluster),
         Root_Dir_Entries_16  => Unsigned_16(Root_Entries),
         OEM_Name             => "XFAT32",
         No_Of_FATs           => FAT_Copies_Type(FATs),
         OK                   => OK
      );

      Report("Format",OK);

      ----------------------------------------------------------------
      -- Open the File System
      ----------------------------------------------------------------
      Put("  Opening FS......... ");
      FATFS.Open_FS(OK);
      Report("FS Open",OK);

      ----------------------------------------------------------------
      -- Check that the created FS is FAT32
      ----------------------------------------------------------------
      Put("  FS Type............ ");
      Put(FS_Type'Image(File_System));
      if File_System = FS_FAT32 then
         Put_Line(" OK.");
      else
         New_Line;
         Report("File system type",False);
      end if;

      ----------------------------------------------------------------
      -- Check the OEM Name
      ----------------------------------------------------------------
      Put("  OEM Name........... ");
      Put(OEM_Name);
      if OEM_Name = "XFAT32  " then
         Put_Line("OK.");
      else
         New_Line;
         Report("OEM Name",False);
      end if;

      ----------------------------------------------------------------
      -- Check Basic File Sytem Paramters
      ----------------------------------------------------------------
      Report_Failed("Sectors/Cluster",FS_Sectors_Per_Cluster = Unsigned_16(Sects_Per_Cluster));
   
      Put("  Total Clusters..... ");
      U32.Put(FS_Clusters);
      New_Line;
      pragma assert(FS_Clusters > 0);

      Space := Free_Space;                      -- Save amount of free space available in bytes
      Put("  Free Space......... ");
      U32.Put(Space);
      Put_Line(" bytes.");

      ----------------------------------------------------------------
      -- Check that root dir is empty (and has no . or .. entry)
      ----------------------------------------------------------------
      Open_Dir(Root,OK);
      pragma assert(OK);
      Get_Dir_Entry(Root,E,OK);
      pragma assert(not OK);
      Close_Dir(Root);

      if Root_Entries <= 512 then
         TX_Count := 600;
         BS_Count := 500;
         B9_Count := 100;
      elsif Root_Entries <= 1024 then
         TX_Count := 300;
         BS_Count := 200;
         B9_Count :=  50;
      else
         TX_Count := 200;
         BS_Count := 100;
         B9_Count :=  20;
      end if;

      File_Test_1(Create_1S_File'Access,Check_1S_File'Access,0,"","1S");
      File_Test_1(Create_MS_File'Access,Check_MS_File'Access,Sects_Per_Cluster,"Sectors","MS");
      File_Test_1(Create_VL_File'Access,Check_VL_File'Access,Sects_Per_Cluster,"Bytes","VL");
      File_Test_1(Create_TX_File'Access,Check_TX_File'Access,TX_Count,"Bytes","TX");
      File_Test_1(Create_BS_File'Access,Check_BS_File'Access,BS_Count,"","BS");
      File_Test_1(Create_B2_File'Access,Check_B2_File'Access,B9_Count,"","B2");
      File_Test_1(Create_B4_File'Access,Check_B4_File'Access,B9_Count,"","B4");
      File_Test_2(Sects_Per_Cluster);
      
      ----------------------------------------------------------------
      -- Close File System
      ----------------------------------------------------------------
      Put("  Closing FS......... ");
      FATFS.Close_FS;
      Report("FS Close",True);

      AdaDIO.Close;

      New_Line;
      
   exception
      when Failure =>
         AdaDIO.Close;
         raise;

   end FAT32_Suite;

begin

   R8.Reset(Gen8,23);
   R16.Reset(Gen16,95);

end FAT_Tests;
