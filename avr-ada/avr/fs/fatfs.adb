-- fatfs.ads - Mon Nov  1 10:09:32 2010
--
-- Author: Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

package body FATFS is

   ------------------------------------------------------------------
   --           F I L E   S Y S T E M   S T A T E
   ------------------------------------------------------------------
   
   IO_Context :            IO_Context_Type;
   
   FS_Open :               Boolean := False;       -- True when FS is open and ready
   Sector_Size :           Unsigned_16;            -- Sector size
   F_System :              FS_Type;                -- File system type
   FS_Time :               FS_Time_Type;           -- File System Date/Time (for writing/changes)
   
   FAT_Start :             Sector_Array(1..4);     -- Up to 4 FATs
   FAT_Count :             FAT_Copies_Type;        -- Number of FATs
   FAT_Index :             FAT_Copies_Type;        -- Which FAT to use
   FAT_Mod :               Unsigned_16;            -- FAT table modulus
   Sectors_Per_FAT :       Unsigned_32;            -- Sectors per FAT
   
   Root_Dir_Start :        Sector_Type;            -- Where the root directory starts
   Root_Dir_Entries :      Unsigned_16;            -- Boot_Sector.Root_Dir_Entries
   Root_Dir_Cluster :      Cluster_Type;           -- First cluster for root directory
   Next_Cluster :          Cluster_Type;           -- Next writable cluster
   
   Cluster_Start :         Sector_Type;            -- Where the data clusters start
   Sectors_Per_Cluster:    Unsigned_16;            -- Sectors per Cluster
   Number_of_Clusters :    Unsigned_32;            -- No. of clusters for disk/image
   
   Search_Cluster :        Cluster_Type;           -- First Cluster to search for free space

   Magic_Dir :             constant := 95;         -- Magic value for directories
   Magic_FCB :             constant := 98;         -- Magic value for Physical File Reads
   Magic_WCB :             constant := 97;         -- Magic value for Physical File Writes
   

   pragma Inline(Rewind_File);
   pragma Inline(Close_File);


   function Is_Valid_Cluster(Cluster : Cluster_Type) return Boolean;
   function FAT_Sector(Cluster : Cluster_Type) return Sector_Type;
   function FAT_Entry(Block : Block_512; Cluster : Cluster_Type) return Cluster_Type;
   function FAT_Entry_Index(Cluster : Cluster_Type) return Unsigned_16;
   function FAT_Sector_Offset(Cluster : Cluster_Type) return Sector_Type;
   function FAT_Sector_Offset(Sector : Sector_Type) return Sector_Type;
   function Get_First_Cluster(Dir_Entry : Dir_Entry_Type) return Cluster_Type;
   function Last_File_Cluster return Cluster_Type;
   procedure Put_FAT_Entry(Block : Block_512; Index, Cluster : Cluster_Type);
   procedure Update_FAT(Sector : Sector_Type; Block : in out Block_512; OK : out Boolean);

   ------------------------------------------------------------------
   --                 C L U S T E R   A P I 
   ------------------------------------------------------------------


   ------------------------------------------------------------------
   -- COMPUTE SECTOR ADDRESS OF A CLUSTER
   ------------------------------------------------------------------

   function Cluster_Sector(Cluster : Cluster_Type) return Sector_Type is
   begin

      return Cluster_Start + Sector_Type(Cluster - 2) * Sector_Type(Sectors_Per_Cluster);

   end Cluster_Sector;


   ------------------------------------------------------------------
   -- RETURN TRUE IF THE CCB IS VALID
   ------------------------------------------------------------------
   
   function Is_Valid_CCB(CCB : CCB_Type) return Boolean is
   begin
   
      return CCB.Start_Sector > 0 and then CCB.Sector_Count > 0;
   
   end Is_Valid_CCB;

   ------------------------------------------------------------------
   -- RETURN TRUE IF AT END OF CLUSTER
   ------------------------------------------------------------------
   
   function Is_End_Cluster(CCB : CCB_Type) return Boolean is
   begin
   
      return Unsigned_16(CCB.Cur_Sector - CCB.Start_Sector) >= CCB.Sector_Count;
   
   end Is_End_Cluster;

   ------------------------------------------------------------------
   -- OPEN AN ARBITRAY REGION OF DISK AS IF IT WERE A CLUSTER
   ------------------------------------------------------------------
   
   procedure Open_Cluster(CCB : out CCB_Type; Sector : Sector_Type; Count : Unsigned_16) is
   begin
   
      CCB.Start_Sector    := Sector;
      CCB.Prev_Sector     := 0;
      CCB.Cur_Sector      := Sector;
      CCB.Sector_Count    := Count;
      CCB.Cluster         := 0;           -- This is not actually a cluster
      CCB.First_Cluster   := 0;           -- There is no first cluster
      CCB.IO_Bytes        := 0;
   
   end Open_Cluster;


   ------------------------------------------------------------------
   -- OPEN A PARTICULAR CLUSTER
   ------------------------------------------------------------------
   
   procedure Open_Cluster(CCB : in out CCB_Type; Cluster : Cluster_Type; Keep_First : Boolean) is
      The_Cluster :     Cluster_Type := Cluster;
      First_Cluster :   Cluster_Type := CCB.First_Cluster;
      IO_Bytes :        Unsigned_32 := CCB.IO_Bytes;
   begin
   
      if Is_Valid_Cluster(The_Cluster) then
         Open_Cluster(CCB,Cluster_Sector(The_Cluster),Sectors_Per_Cluster);
         CCB.Cluster := The_Cluster;               -- Save cluster number
      else
         The_Cluster   := 0;
         First_Cluster := 0;
         Open_Cluster(CCB,0,Sectors_Per_Cluster);  -- No clusters
      end if;
      
      if Keep_First then
         CCB.First_Cluster := First_Cluster;
         CCB.IO_Bytes      := IO_Bytes;
      else
         CCB.First_Cluster := The_Cluster;
      end if;
   
   end Open_Cluster;


   ------------------------------------------------------------------
   -- OPEN THE NEXT CLUSTER, IF ANY
   ------------------------------------------------------------------
   
   procedure Get_Next_Cluster(CCB : in out CCB_Type; Block : in out Block_512; OK : out Boolean) is
      Sector :    Sector_Type    := FAT_Start(FAT_Index);   -- Start of FAT
      Cluster :   Cluster_Type   := CCB.Cluster;            -- Current, then next Cluster #
   begin
   
      if not Is_Valid_CCB(CCB) or else Cluster < 2 or else CCB.First_Cluster < 2 then
         OK := False;                  -- Invalid CCB or at end of Cluster chain
         return;
      end if;
      
      Sector := FAT_Sector(Cluster);   -- Locate FAT sector for this cluster number
      IO_Context.Read(Sector,Block,OK);-- Read FAT sector
      
      if not OK then
         Cluster := 0;                 -- Read Failure
         return;
      end if;
      
      Cluster := FAT_Entry(Block,Cluster); -- Retrieve next cluster #
      
      if not Is_Valid_Cluster(Cluster) then
         Cluster := 0;                 -- There is no next cluster #
         OK := False;                  -- Treat as an error
      else
         Open_Cluster(CCB,Cluster,Keep_First => True);
      end if;
      
   end Get_Next_Cluster;
   
   
   ------------------------------------------------------------------
   -- REWIND TO THE START OF THE CLUSTER CHAIN
   ------------------------------------------------------------------
   
   procedure Rewind_Cluster(CCB : in out CCB_Type) is
   begin
   
      if CCB.First_Cluster >= 2 then
         Open_Cluster(CCB,CCB.First_Cluster,Keep_First => True);
      else
         CCB.Cur_Sector := CCB.Start_Sector;
      end if;
      
      CCB.Prev_Sector := 0;
      CCB.IO_Bytes    := 0;
   
   end Rewind_Cluster;
   
   ------------------------------------------------------------------
   -- READ CLUSTER AND WITHOUT ADVANCING
   ------------------------------------------------------------------
   
   procedure Peek_Cluster(CCB : in out CCB_Type; Block : out Block_512; OK : out Boolean) is
   begin
   
      if not Is_Valid_CCB(CCB) then
         OK := False;
         return;
      end if;
      
      if Is_End_Cluster(CCB) then
         Get_Next_Cluster(CCB,Block,OK);
      else
         OK := True;
      end if;
      
      if OK then
         IO_Context.Read(CCB.Cur_Sector,Block,OK);
      end if;
   
   end Peek_Cluster;    
   
   
   ------------------------------------------------------------------
   -- READ CLUSTER AND ADVANCE ONE SECTOR
   ------------------------------------------------------------------
   
   procedure Read_Cluster(CCB : in out CCB_Type; Block : out Block_512; OK : out Boolean) is
   begin
   
      Peek_Cluster(CCB,Block,OK);
      if OK then
         CCB.Prev_Sector := CCB.Cur_Sector;
         CCB.Cur_Sector  := CCB.Cur_Sector + 1;
         CCB.IO_Bytes    := CCB.IO_Bytes + Unsigned_32(Sector_Size);
      end if;
      
   end Read_Cluster;    
   
   ------------------------------------------------------------------
   -- RE-READ LAST READ SECTOR FROM CLUSTER
   ------------------------------------------------------------------

   procedure Reread_Cluster(CCB : in out CCB_Type; Block : out Block_512; OK : out Boolean) is
   begin
   
      if CCB.Prev_Sector = 0 then
         OK := False;
         return;
      end if;
      
      IO_Context.Read(CCB.Prev_Sector,Block,OK);
   
   end Reread_Cluster;
   
   ------------------------------------------------------------------
   -- ADVANCE ONE SECTOR
   ------------------------------------------------------------------
   
   procedure Advance_Cluster(CCB : in out CCB_Type; Block : in out Block_512; OK : out Boolean) is
   begin
   
      if not Is_Valid_CCB(CCB) then
         OK := False;
         return;
      end if;
      
      if Is_End_Cluster(CCB) then
         Get_Next_Cluster(CCB,Block,OK);
      else
         CCB.Cur_Sector := CCB.Cur_Sector + 1;
         OK := True;
      end if;
   
   end Advance_Cluster;
   
   
   ------------------------------------------------------------------
   -- CLOSE A CLUSTER FOR SAFETY
   ------------------------------------------------------------------
   
   procedure Close_Cluster(CCB : out CCB_Type) is
   begin
   
      CCB.Start_Sector := 0;
      CCB.Sector_Count := 0;
   
   end Close_Cluster;
   
   
   ------------------------------------------------------------------
   --             F I L E   S Y S T E M   A P I 
   ------------------------------------------------------------------
   
   
   ------------------------------------------------------------------
   -- REGISTER A I/O READ SECTOR PROCEDURE
   ------------------------------------------------------------------
   
   procedure Register_Read_Proc(Read : Read_Proc) is
   begin

      IO_Context.Read := Read;

   end Register_Read_Proc;
   
   
   ------------------------------------------------------------------
   -- REGISTER A I/O WRITE SECTOR PROCEDURE
   ------------------------------------------------------------------
   
   procedure Register_Write_Proc(Write : Write_Proc) is
   begin

      IO_Context.Write := Write;

   end Register_Write_Proc;
   
   
   ------------------------------------------------------------------
   -- UPPERCASE A STRING
   ------------------------------------------------------------------
   
   function Uppercase(S : String) return String is
      R : String := S;
   begin

      for X in R'Range loop
         if R(X) in 'a' .. 'z' then
         R(X) := Character'Val(Character'Pos(R(X))-32);
         end if;
      end loop;

      return R;

   end Uppercase;
   
   
   ------------------------------------------------------------------
   -- READ THE BOOT SECTOR
   ------------------------------------------------------------------
   
   procedure Read_Boot_Sector(Boot_Sector : out Boot_Sector_Type; OK : out Boolean) is
      Block :         Block_512;
      for Block'Address use Boot_Sector'Address;
   begin

      IO_Context.Read(0,Block,OK);

   end Read_Boot_Sector;
   
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF THIS IS A FAT32 FILE SYSTEM
   ------------------------------------------------------------------
   
   function FS_Is_FAT32(Boot_Sector : Boot_Sector_Type) return Boolean is
   begin

      return Boot_Sector.Sectors_Per_FAT = 0;

   end FS_Is_FAT32;
   
   
   ------------------------------------------------------------------
   -- RETURN THE HIDDEN SECTOR COUNT
   ------------------------------------------------------------------
   
   function FS_Hidden_Sectors(Boot_Sector : Boot_Sector_Type) return Unsigned_32 is
   begin

      if not FS_Is_FAT32(Boot_Sector) then
         return Boot_Sector.Hidden_Sectors_32 and 16#0000FFFF#;  -- Just low order 16-bits
      else
         return Boot_Sector.Hidden_Sectors_32;                   -- Full 32 bits
      end if;

   end FS_Hidden_Sectors;
   
   
   ------------------------------------------------------------------
   -- RETURN THE "SECTORS PER FAT" VALUE
   ------------------------------------------------------------------
   
   function FS_Sectors_Per_FAT(Boot_Sector : Boot_Sector_Type) return Unsigned_32 is
   begin

      if not FS_Is_FAT32(Boot_Sector) then
         return Unsigned_32(Boot_Sector.Sectors_Per_FAT);
      else
         return Boot_Sector.Sectors_Per_FAT_32;
      end if;

   end FS_Sectors_Per_FAT;
   
   
   ------------------------------------------------------------------
   -- RETURN THE TOTAL # OF SECTORS IN THIS FILE SYSTEM
   ------------------------------------------------------------------
   
   function Total_Sectors(Boot_Sector : Boot_Sector_Type) return Unsigned_32 is
   begin

      if not FS_Is_FAT32(Boot_Sector) then
         return Unsigned_32(Boot_Sector.Total_Sectors_in_FS);
      else
         return Boot_Sector.Total_Sectors_32;
      end if;

   end Total_Sectors;
   
   
   ------------------------------------------------------------------
   -- RETURN THE TOTAL NUMBER OF DATA CLUSTERS
   ------------------------------------------------------------------
   
   function Total_Clusters(Boot_Sector : Boot_Sector_Type) return Unsigned_32 is
   begin

      return ( Total_Sectors(Boot_Sector)
         - FS_Sectors_Per_FAT(Boot_Sector) * Unsigned_32(FAT_Count)
         - Unsigned_32(Boot_Sector.Reserved_Sectors)
         ) / Unsigned_32(Boot_Sector.Sectors_Per_Cluster);

   end Total_Clusters;
   
   
   ------------------------------------------------------------------
   -- OPEN THE FAT FILE SYSTEM
   ------------------------------------------------------------------
   
   procedure Open_FS(OK : out Boolean) is
      Boot_Sector :   Boot_Sector_Type;
      Block :         Block_512;
      for Block'Address use Boot_Sector'Address;
   
      Sector :        Sector_Type;
      Is_FAT32 :      Boolean;
   begin
      
      OK          := False;
      FS_Open     := False;
      Is_FAT32    := False;
      
      FAT_Index   := FAT_Start'First;
   
      Search_Cluster := 0;
      Next_Cluster   := 0;

      --------------------------------------------------------------
      -- Initialize FS Date/Time (can be overriden by user after)
      --------------------------------------------------------------
      
      if FS_Time.Year = 0 then
         FS_Time.Year    := Year_Type(2010 - 1980);
         FS_Time.Month   := 09;
         FS_Time.Day     := 03;
         FS_Time.Hour    := 11;
         FS_Time.Minute  := 21;
         FS_Time.Second2 := 00;
      end if;
   
      --------------------------------------------------------------
      -- Read Boot Sector
      --------------------------------------------------------------
      Read_Boot_Sector(Boot_Sector,OK);
      if not OK then
         return;
      end if;
      
      Is_FAT32 := FS_Is_FAT32(Boot_Sector);
   
      --------------------------------------------------------------
      -- Check Disk Parameters
      --------------------------------------------------------------
      if Boot_Sector.Bytes_Per_Sector /= 512 then
         OK := False;
         return;
      end if;
   
      if Boot_Sector.FAT_Copies < 1 or Boot_Sector.FAT_Copies > FAT_Start'Length then
         OK := False;                -- too many FATs
         return;
      end if;
   
      --------------------------------------------------------------
      -- Initialize table of starting FAT sector numbers
      --------------------------------------------------------------
      Sector_Size    := Boot_Sector.Bytes_Per_Sector;
   
      if Sector_Size /= 512 then
         OK := False;                -- Unsupported sector size
         return;
      end if;
   
      Sectors_Per_FAT := FS_Sectors_Per_FAT(Boot_Sector);
      
      --------------------------------------------------------------
      -- Compute the Start of Each FAT Table
      --------------------------------------------------------------
      Sector              := Sector_Type(Boot_Sector.Reserved_Sectors);
      Root_Dir_Start      := 0;
      Root_Dir_Entries    := Boot_Sector.Root_Dir_Entries;
      Root_Dir_Cluster    := 0;
      FAT_Count           := 0;
      
      for X in FAT_Start'Range loop
         if X <= Boot_Sector.FAT_Copies then
            FAT_Start(X) := Sector;
            FAT_Count    := FAT_Count + 1;
            Sector       := Sector + Sector_Type(Sectors_Per_FAT);
         else
            FAT_Start(X) := 0;
         end if;
      end loop;
      
      if Root_Dir_Start = 0 then
         Root_Dir_Start  := Sector;
         Sector := Sector + Sector_Type((Root_Dir_Entries * 32 + Sector_Size - 1) / Sector_Size);
      end if;
   
      --------------------------------------------------------------
      -- Compute the Start of the Data Clusters and No. of Clusters
      --------------------------------------------------------------
      Cluster_Start       := Sector;
      Sectors_Per_Cluster := Unsigned_16(Boot_Sector.Sectors_Per_Cluster);
      Number_of_Clusters  := Total_Clusters(Boot_Sector);
   
      --------------------------------------------------------------
      -- Root Directory is in a Cluster for FAT32
      --------------------------------------------------------------
      if Is_FAT32 then
         Root_Dir_Cluster := Cluster_Type(Boot_Sector.Root_Dir_First_Cluster);
         Root_Dir_Start   := Cluster_Sector(Root_Dir_Cluster);
      end if;
   
      --------------------------------------------------------------
      -- Identify File System Type
      --------------------------------------------------------------
      if not Is_FAT32 then
--       if Number_of_Clusters < 4087 then
--          F_System := FS_FAT12;
--       else
            F_System := FS_FAT16;
--       end if;
      elsif Number_of_Clusters < 268_435_457 then
         F_System := FS_FAT32;
      else
         F_System := FS_Unknown;
      end if;
   
      --------------------------------------------------------------
      -- Return Status to Caller
      --------------------------------------------------------------
      if File_System /= FS_Unknown and then File_System /= FS_FAT12 then
         case F_System is
            when FS_FAT16 =>
               FAT_Mod := 256;
            when FS_FAT32 =>
               FAT_Mod := 128;
            when others =>
               null;
         end case;
      
         FS_Open := True;
         OK      := FS_Open;
      else
         FS_Open := False;
         OK      := False;
      end if;
   
   end Open_FS;
   
   ------------------------------------------------------------------
   -- Close a File System
   ------------------------------------------------------------------
   procedure Close_FS is
   begin

      F_System := FS_Unknown;
      FS_Open := False;

   end Close_FS;
   
   ------------------------------------------------------------------
   -- RETURN THE FILE SYSTEM TYPE
   ------------------------------------------------------------------
   
   function File_System return FS_Type is
   begin

      return F_System;

   end File_System;
   
   
   ------------------------------------------------------------------
   -- RETURN THE OEM NAME OF THE FILE SYSTEM
   ------------------------------------------------------------------
   
   function OEM_Name return String is
      Boot_Sector :   Boot_Sector_Type;
      OK :            Boolean;
   begin
   
      Read_Boot_Sector(Boot_Sector,OK);
      if OK then
         return Boot_Sector.OEM_Name;
      else
         return "?";
      end if;
   
   end OEM_Name;
   

   -------------------------------------------------------------------
   -- RETURN # OF ROOT DIRECTORY ENTRIES FOR FAT16, ELSE 0 FOR FAT32
   -------------------------------------------------------------------

   function FS_Root_Entries return Unsigned_16 is
   begin

      if Root_Dir_Cluster < 2 then
         return Root_Dir_Entries;                  -- FAT16
      else
         return 0;                                 -- FAT32 (root dir in a cluster)
      end if;

   end FS_Root_Entries;
   

   -------------------------------------------------------------------
   -- RETURN SECTORS / CLUSTER FOR FILE SYSTEM
   -------------------------------------------------------------------

   function FS_Sectors_Per_Cluster return Unsigned_16 is
   begin

      return Sectors_Per_Cluster;

   end FS_Sectors_Per_Cluster;


   -------------------------------------------------------------------
   -- RETURN TOTAL NUMBER OF CLUSTERS IN FILE SYSTEM
   -------------------------------------------------------------------

   function FS_Clusters return Unsigned_32 is
   begin

      return Number_of_Clusters;

   end FS_Clusters;

   
   ------------------------------------------------------------------
   --                F A T   U T I L I T I E S 
   ------------------------------------------------------------------
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF CLUSTER POINTS TO A DATA CLUSTER
   ------------------------------------------------------------------
   
   function Is_Valid_Cluster(Cluster : Cluster_Type) return Boolean is
   begin

      case F_System is
         when FS_FAT16 =>
            return Cluster >= 2 and Cluster < 16#FFF0#;
         when FS_FAT32 =>
            return Cluster >= 2 and Cluster < 16#FFFFFFF0#;
         when others =>
            return False;
      end case;

   end Is_Valid_Cluster;
   
   ------------------------------------------------------------------
   -- RETURN FAT ENTRY BASED UPON CLUSTER #
   ------------------------------------------------------------------
   
   function FAT_Entry(Block : Block_512; Cluster : Cluster_Type) return Cluster_Type is
      FAT16 :     U16_Array(0..255);                  -- FAT16 table entries
      FAT32 :     U32_Array(0..127);                  -- FAT32 table entries
      
      for FAT16'Address use Block'Address;
      for FAT32'Address use Block'Address;
   begin
   
      case F_System is
         when FS_FAT16 =>
            return Cluster_Type(FAT16(FAT_Entry_Index(Cluster)));
         when FS_FAT32 =>
            return Cluster_Type(FAT32(FAT_Entry_Index(Cluster)));
         when others =>
            return 1;
      end case;
   
   end FAT_Entry;
   
   ------------------------------------------------------------------
   -- RETURN THE SECTOR # OF ACTIVE FAT FOR CLUSTER #
   ------------------------------------------------------------------
   
   function FAT_Sector(Cluster : Cluster_Type) return Sector_Type is
   begin

      return FAT_Start(FAT_Index) + FAT_Sector_Offset(Cluster);

   end FAT_Sector;
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF SECTOR POINTS PAST END OF CURRENT FAT
   ------------------------------------------------------------------
   
   function Is_FAT_End(Sector : Sector_Type) return Boolean is
      FAT_End :   Sector_Type := FAT_Start(FAT_Index) + Sector_Type(Sectors_Per_FAT);
   begin

      return Sector >= FAT_End;

   end Is_FAT_End;
   
   ------------------------------------------------------------------
   -- RETURN FAT ENTRY INDEX WITHIN A FAT SECTOR
   ------------------------------------------------------------------
   
   function FAT_Entry_Index(Cluster : Cluster_Type) return Unsigned_16 is
   begin

      return Unsigned_16( Cluster mod Cluster_Type(FAT_Mod) );

   end FAT_Entry_Index;
   
   ------------------------------------------------------------------
   -- COMPUTE THE RELATIVE FAT SECTOR FOR A GIVEN CLUSTER #
   ------------------------------------------------------------------
   
   function FAT_Sector_Offset(Cluster : Cluster_Type) return Sector_Type is
   begin

      return Sector_Type(Cluster) / Sector_Type(FAT_Mod);

   end FAT_Sector_Offset;
   
   
   ------------------------------------------------------------------
   --              D I R E C T O R Y   A P I
   ------------------------------------------------------------------
   
   
   ------------------------------------------------------------------
   -- INTERNAL : RETURN TRUE IF DIR A VALID AND OPEN DIR 
   ------------------------------------------------------------------
   
   function Is_Valid_Dir(Dir : DCB_Type) return Boolean is
   begin
   
      if FS_Open and then Root_Dir_Start >= 0 then
         return Dir.Magic = Magic_Dir;
      else
         return False;
      end if;
      
   end Is_Valid_Dir;
   
   pragma Inline(Is_Valid_Dir);
   
   
   ------------------------------------------------------------------
   -- REWIND THE DIRECTORY
   ------------------------------------------------------------------
   
   procedure Rewind_Dir(Dir : in out DCB_Type) is
   begin
   
      if Is_Valid_Dir(Dir) then
         Rewind_Cluster(Dir.CCB);
         Dir.Cur_Index := 0;
      end if;
   
   end Rewind_Dir;
   
   
   ------------------------------------------------------------------
   -- OPEN THE ROOT DIRECTORY
   ------------------------------------------------------------------
   
   procedure Open_Dir(Dir : out DCB_Type; OK : out Boolean) is
   begin
   
      OK := False;

      if not FS_Open then
         Dir.Magic := 0;
         return;
      end if;
   
      if Root_Dir_Cluster = 0 then
         Open_Cluster(Dir.CCB,Root_Dir_Start,Root_Dir_Entries * 32 / Sector_Size);
         Dir.Dir_Entries := Root_Dir_Entries;
      else
         Open_Cluster(Dir.CCB,Root_Dir_Cluster,Keep_First => False);
         Dir.Dir_Entries := Unsigned_16(Sectors_Per_Cluster * Sector_Size / 32);
      end if;
      
      Dir.Cur_Index   := 0;
      Dir.Magic       := Magic_Dir;
      OK              := True;
   
   end Open_Dir;
   
   
   ------------------------------------------------------------------
   -- OPEN SELECTED DIRECTORY
   ------------------------------------------------------------------
   
   procedure Open_Dir(Dir : out DCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean) is
   begin
   
      if Dir_Entry.Subdirectory then
         Open_Cluster(Dir.CCB,Get_First_Cluster(Dir_Entry),Keep_First => False);
         Dir.Dir_Entries     := Unsigned_16(Sectors_Per_Cluster * Sector_Size / 32);
         Dir.Magic           := Magic_Dir;
      else
         Dir.Magic           := 0;           -- Not valid
      end if;
      
      Dir.Cur_Index   := 0;
      OK              := Dir_Entry.Subdirectory;
   
   end Open_Dir;
   
   
   ------------------------------------------------------------------
   -- OPEN A DIRECTORY BY NAME
   ------------------------------------------------------------------
   
   procedure Open_Dir(Dir : in out DCB_Type; Name : String; OK : out Boolean) is
      Dir_Entry : Dir_Entry_Type;
   begin
   
      Search_Dir(Dir,Dir_Entry,Name,OK);
      if OK then
         Open_Dir(Dir,Dir_Entry,OK);
      end if;
   
   end Open_Dir;
   
   
   ------------------------------------------------------------------
   -- CLOSE DIRECTORY 
   ------------------------------------------------------------------
   
   procedure Close_Dir(Dir : in out DCB_Type) is
   begin
   
      Close_Cluster(Dir.CCB);
      Dir.Magic := 0;
   
   end Close_Dir;
   
   
   ------------------------------------------------------------------
   -- CHECK FOR DIRECTORY EOF
   ------------------------------------------------------------------
   
   function Is_Dir_End(Dir : DCB_Type) return Boolean is
   begin
   
      if not Is_Valid_Dir(Dir) then
         return False;       -- Bad Dir entry
      elsif Dir.CCB.First_Cluster < 2 then
         return Dir.Cur_Index >= Dir.Dir_Entries;
      else
         return Is_End_Cluster(Dir.CCB);
      end if;
   
   end Is_Dir_End;
   
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF DIR ENTRY REPRESENTS "END OF DIRECTORY"
   ------------------------------------------------------------------
   
   function Is_Dir_End(Dir_Entry : Dir_Entry_Type) return Boolean is
   begin
   
      return Character'Pos(Dir_Entry.Filename(Dir_Entry.Filename'First)) = 16#00#;
   
   end Is_Dir_End;
   
   ------------------------------------------------------------------
   -- GET THE CURRENT DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Raw_Get_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean) is
      Directory :     Dir_Entry_Array(0..Sector_Size / 32 - 1);
      X :             Unsigned_16 := Dir.Cur_Index mod Unsigned_16(Sector_Size / 32);
      Block :         Bytes(0..Unsigned_16(Sector_Size-1));
      for Block'Address use Directory'Address;
   begin
   
      if Is_Dir_End(Dir) then
         Advance_Cluster(Dir.CCB,Block,OK);
         if not OK then
            Dir_Entry.Filename(1) := Character'Val(1);      -- Make non-end dir char
            return;
         end if;
      end if;
      
      Peek_Cluster(Dir.CCB,Block,OK);
      if not OK then
         Dir_Entry.Filename(1) := Character'Val(1);  -- Make non-end dir char
         return;
      end if;
      
      Dir_Entry := Directory(X);
      
      if Is_Dir_End(Dir_Entry) then
         OK := False;            -- End of directory
      else
         OK := True;
      end if;
   
   end Raw_Get_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- RETURN THE NEXT DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Raw_Next_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean) is
      Block : Block_512;
   begin
   
      if Is_Dir_End(Dir) then
         Advance_Cluster(Dir.CCB,Block,OK);
         if not OK then
            Dir_Entry.Filename(1) := Character'Val(1);      -- Make non-end dir char
            return;
         end if;
      end if;
   
      Dir.Cur_Index := Dir.Cur_Index + 1;
      if Dir.Cur_Index mod Unsigned_16(Sector_Size / 32) = 0 then
         Advance_Cluster(Dir.CCB,Block,OK);
      else
         OK := True;
      end if;
   
      if OK then
         Raw_Get_Dir_Entry(Dir,Dir_Entry,OK);
      end if;
   
   end Raw_Next_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF THIS ENTRY HAS BEEN DELETED
   ------------------------------------------------------------------
   
   function Is_Deleted(Dir_Entry : Dir_Entry_Type) return Boolean is
   begin
   
      return Character'Pos(Dir_Entry.Filename(Dir_Entry.Filename'First)) = 16#E5#;
   
   end Is_Deleted;
   
   
   ------------------------------------------------------------------
   -- APPLICATION GET DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Get_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean) is
   begin
   
      Raw_Get_Dir_Entry(Dir,Dir_Entry,OK);
      loop
         exit when not OK;
         exit when not Is_Deleted(Dir_Entry) and then not Dir_Entry.Volume_Name;
         Raw_Next_Dir_Entry(Dir,Dir_Entry,OK);
      end loop;
   
   end Get_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- APPLICATION GET NEXT DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Next_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean) is
   begin
   
      loop
         Raw_Next_Dir_Entry(Dir,Dir_Entry,OK);
         exit when not OK;
         exit when not Is_Deleted(Dir_Entry) and then not Dir_Entry.Volume_Name;
      end loop;
   
   end Next_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- SEARCH A DIRECTORY FOR A FILENAME / SUBDIR NAME
   ------------------------------------------------------------------
   
   procedure Search_Dir(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; Name : String; OK : out Boolean) is
      Local_Name : String := Uppercase(Name);
   begin
   
      if not Is_Valid_Dir(Dir) then
         OK := False;
         return;
      end if;
      
      Rewind_Dir(Dir);
      Get_Dir_Entry(Dir,Dir_Entry,OK);
      
      loop
         exit when not OK;
         
         declare
            Entry_Name : String := Filename(Dir_Entry);
         begin
            if Entry_Name = Local_Name then
            return;
            end if;
         end;
         
         Next_Dir_Entry(Dir,Dir_Entry,OK);
      end loop;
      
      OK := False;        -- Not found
   
   end Search_Dir;
   
   
   ------------------------------------------------------------------
   -- GET 16/32-BIT CLUSTER # FROM DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   function Get_First_Cluster(Dir_Entry : Dir_Entry_Type) return Cluster_Type is
   begin
   
      case F_System is
         when FS_FAT16 =>
            return Cluster_Type(Dir_Entry.First_Cluster);

         when FS_FAT32 =>
            return Cluster_Type(
               Shift_Left(Unsigned_32(Dir_Entry.Cluster_High),16)
               or Unsigned_32(Dir_Entry.First_Cluster));

         when others =>
            return 0;
      end case;
   
   end Get_First_Cluster;
   
   ------------------------------------------------------------------
   -- PUT 16/32-BIT CLUSTER # INTO DIRECTORY ENTRY
   ------------------------------------------------------------------
   procedure Put_First_Cluster(Dir_Entry : in out Dir_Entry_Type; Cluster: Cluster_Type) is
   begin
   
      Dir_Entry.First_Cluster := Unsigned_16(Unsigned_32(Cluster) and 16#FFFF#);
      
      if F_System = FS_FAT32 then
         Dir_Entry.Cluster_High := Unsigned_16(Shift_Right(Unsigned_32(Cluster),16));
      end if;
   
   end Put_First_Cluster;
   
   ------------------------------------------------------------------
   -- SEARCH ROOT DIRCTORY FOR VOLUME NAME AND RETURN IT
   ------------------------------------------------------------------
   
   function Volume return String is
      Dir :   DCB_Type;
      E :     Dir_Entry_Type;
      OK :    Boolean;
   begin
   
      Open_Dir(Dir,OK);
      if not OK then
         return "?";
      end if;
      
      Raw_Get_Dir_Entry(Dir,E,OK);
      
      loop
         exit when not OK;
         exit when not Is_Deleted(E) and then E.Volume_Name;
         Raw_Next_Dir_Entry(Dir,E,OK);
      end loop;
      
      if OK then
         if E.Volume_Name then
            return E.Filename & E.Extension;
         else
            return "";  -- No volume name
         end if;
      else
         return "?";     -- Error
      end if;
   
   end Volume;
   
   ------------------------------------------------------------------
   -- RETURN THE DIRECTORY ENTRY'S FILE NAME
   ------------------------------------------------------------------
   
   function Filename(Dir_Entry : Dir_Entry_Type) return String is
      File_Name :     String(1..12);
      X :             Positive := File_Name'First;
   begin
   
      if Is_Deleted(Dir_Entry) then
         return "";
      end if;
      
      for Y in Dir_Entry.Filename'Range loop
         exit when Dir_Entry.Filename(Y) = ' ';
         File_Name(X) := Dir_Entry.Filename(Y);
         X := X + 1;
      end loop;
      
      if Dir_Entry.Extension(Dir_Entry.Extension'First) /= ' ' then
         File_Name(X) := '.';
         X := X + 1;
         for Y in Dir_Entry.Extension'Range loop
            exit when Dir_Entry.Extension(Y) = ' ';
            File_Name(X) := Dir_Entry.Extension(Y);
            X := X + 1;
         end loop;
      end if;
      
      if Character'Pos(File_Name(1)) = 16#05# then
         File_Name(1) := Character'Val(16#E5#);
      end if;
      
      return Uppercase(File_Name(1..X-1));
   
   end Filename;
   
   ------------------------------------------------------------------
   -- D A T E / T I M E   A P I   ( T H E S E   A R E   I N L I N E D )
   ------------------------------------------------------------------
   
   procedure Set_FS_Time(Time : FS_Time_Type) is
   begin

      FS_Time := Time;

   end Set_FS_Time;
   
   procedure Get_FS_Time(Time : out FS_Time_Type) is
   begin

      Time := FS_Time;

   end Get_FS_Time;
   
   ------------------------------------------------------------------
   --  RETURN TRUE WHEN CH IS A PATHNAME SEPARATOR
   ------------------------------------------------------------------
   
   function Is_Separator(Ch : Character) return Boolean is
   begin

      return Ch = '/' or else Ch = '\';

   end Is_Separator;
   
   ------------------------------------------------------------------
   -- PARSE FILE NAME INTO 8.3 FORMAT
   ------------------------------------------------------------------
   
   procedure Parse_Filename(Base, Ext : out String; Name : String; OK : out Boolean) is
      S : String := Uppercase(Name);
      Y : Natural;
   begin
   
      Base := ( others => ' ' );
      Ext  := ( others => ' ' );
      
      Y := S'First;
      
      for X in Base'Range loop
         exit when Y > S'Last;
         exit when S(Y) = '.';
         Base(X) := S(Y);
         Y := Y + 1;
      end loop;
      
      if Y <= S'Last and then S(Y) = '.' then
         Y := Y + 1;
         for X in Ext'Range loop
            exit when Y > S'Last;
            exit when S(Y) = '.';
            Ext(X) := S(Y);
            Y := Y + 1;
         end loop;
      end if;
      
      OK := Y = S'Last + 1;
   
   end Parse_Filename;
   
   ------------------------------------------------------------------
   -- OPEN A DIRECTORY BY PATHNAME
   ------------------------------------------------------------------
   
   procedure Open_Path(Dir : out DCB_Type; Pathname : String; OK : out Boolean) is
      X, Y :  Natural;
      Base :  String(1..8);
      Ext :   String(1..3);
   begin
   
      X := Pathname'First;
      
      Open_Dir(Dir,OK);
      
      loop
         exit when not OK;
         
         loop  -- skip over '/'
            if X > Pathname'Last then
               OK := True;
               return;                 -- Reached end of Pathname
            end if;
            exit when not Is_Separator(Pathname(X));
            X := X + 1;
         end loop;
         
         Y := X + 1;
         loop
            exit when Y > Pathname'Last;
            exit when Is_Separator(Pathname(Y));
            Y := Y + 1;
         end loop;
      
         if Pathname(X..Y-1) /= "." then
            Parse_Filename(Base,Ext,Pathname(X..Y-1),OK);   -- Does this respect 8.3 format?
            exit when not OK;
            Open_Dir(Dir,Pathname(X..Y-1),OK);
            exit when not OK;
         end if;
         
         X := Y;
      end loop;
      
      Close_Dir(Dir);
      OK := False;
      
   end Open_Path;
   
   ------------------------------------------------------------------
   -- RETURN THE INDEX OF THE START OF THE FILE NAME WITHOUT DIRECTORY
   ------------------------------------------------------------------
   
   function Filename_Index(Pathname : String) return Natural is
   begin
   
      for X in reverse Pathname'Range loop
         if Is_Separator(Pathname(X)) then
            return X + 1;
         end if;
      end loop;
      
      return Pathname'First;
   
   end Filename_Index;
   
   ------------------------------------------------------------------
   -- INTERNAL : RETURN TRUE IF FILE IS VALID
   ------------------------------------------------------------------
   
   function Is_Valid_File(File : FCB_Type) return Boolean is
   begin

      return File.Magic = Magic_FCB;

   end Is_Valid_File;
   
   pragma Inline(Is_Valid_File);
   
   
   ------------------------------------------------------------------
   -- OPEN A FILE FOR I/O
   ------------------------------------------------------------------
   
   procedure Open_File(File : out FCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean) is
   begin
   
      if Dir_Entry.Volume_Name or else Dir_Entry.Subdirectory then
         OK := False;
         return;
      end if;
      
      Open_Cluster(File.CCB,Get_First_Cluster(Dir_Entry),Keep_First => False);
      File.File_Size := Dir_Entry.File_Size;
      File.Magic     := Magic_FCB;
      OK := True;
   
   end Open_File;
   
   
   ------------------------------------------------------------------
   -- OPEN A FILE BY NAME
   ------------------------------------------------------------------
   
   procedure Open_File(File : out FCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
      E :     Dir_Entry_Type;
   begin
   
      Search_Dir(Dir,E,Name,OK);
      if OK then
         Open_File(File,E,OK);
      end if;
   
   end Open_File;
   
   
   ------------------------------------------------------------------
   -- REWIND A FILE
   ------------------------------------------------------------------
   
   procedure Rewind_File(File : in out FCB_Type) is
   begin
   
      if Is_Valid_File(File) then
         Rewind_Cluster(File.CCB);
      end if;
   
   end Rewind_File;
   
   
   ------------------------------------------------------------------
   -- Finalize a File I/O Count
   ------------------------------------------------------------------
   
   procedure Finalize_IO(File : in out FCB_Type; Count : out Unsigned_16) is
   begin
   
      if File.CCB.IO_Bytes >= File.File_Size then
         Count := Unsigned_16(File.File_Size - (File.CCB.IO_Bytes - Unsigned_32(Sector_Size)));
      else
         Count := Sector_Size;
      end if;
   
   end Finalize_IO;
   
   
   ------------------------------------------------------------------
   -- READ ONE SECTOR OF A FILE
   ------------------------------------------------------------------
   
   procedure Read_File(File : in out FCB_Type; Block : out Block_512; Count : out Unsigned_16; OK : out Boolean) is
   begin
   
      Count := 0;
   
      if not Is_Valid_File(File) or else File.CCB.IO_Bytes >= File.File_Size then
         OK := False;
         return;
      end if;
      
      Read_Cluster(File.CCB,Block,OK);
      if OK then
         Finalize_IO(File,Count);
      end if;
   
   end Read_File;
   
   
   ------------------------------------------------------------------
   -- REREAD LAST READ SECTOR
   ------------------------------------------------------------------
   
   procedure Reread_File(File : in out FCB_Type; Block : out Block_512; Count : out Unsigned_16; OK : out Boolean) is
   begin
   
      Count := 0;
      
      if not Is_Valid_File(File) then
         OK := False;
         return;
      end if;
      
      Reread_Cluster(File.CCB,Block,OK);
      if OK then
         Finalize_IO(File,Count);
      end if;
      
   end Reread_File;
   
   
   ------------------------------------------------------------------
   -- Close a File
   ------------------------------------------------------------------
   
   procedure Close_File(File : in out FCB_Type) is
   begin
   
      if Is_Valid_File(File) then
         Close_Cluster(File.CCB);
         File.Magic := 0;
      end if;
   
   end Close_File;
   
   
   ------------------------------------------------------------------
   -- OPEN TEXT FILE BY DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Open_File(File : out TFCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean) is
   begin
   
      File.Byte_Offset := 0;
      Open_File(File.FCB,Dir_Entry,OK);
   
   end Open_File;
   
   
   ------------------------------------------------------------------
   -- OPEN TEXT FILE BY FILE NAME
   ------------------------------------------------------------------
   
   procedure Open_File(File : out TFCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
   begin
   
      File.Byte_Offset := 0;
      Open_File(File.FCB,Dir,Name,OK);
   
   end Open_File;
   
   
   ------------------------------------------------------------------
   -- REWIND THE TEXT FILE
   ------------------------------------------------------------------
   
   procedure Rewind_File(File : in out TFCB_Type) is
   begin
   
      Rewind_File(File.FCB);
      File.Byte_Offset := 0;
   
   end Rewind_File;
   
   
   ------------------------------------------------------------------
   -- INTERNAL -- FETCH BLOCK TO READ FROM
   ------------------------------------------------------------------
   
   procedure Get(File : in out TFCB_Type; Block : out Block_512; Count : out Unsigned_16; OK : out Boolean) is
   begin
   
      if File.Byte_Offset = 0 then
         Read_File(File.FCB,Block,Count,OK);
      else
         Reread_File(File.FCB,Block,Count,OK);
      end if;
   
   end Get;
   
   
   ------------------------------------------------------------------
   -- READ THE NEXT CHARACTER FROM THE TEXT FILE
   ------------------------------------------------------------------
   
   procedure Read_Char(File : in out TFCB_Type; Char : out Character; OK : out Boolean) is
      Block : Block_512;
      Count : Unsigned_16;
   begin
   
      Get(File,Block,Count,OK);
      if OK then
         if File.Byte_Offset < Count then
            Char := Character'Val(Block(File.Byte_Offset));
            File.Byte_Offset := ( File.Byte_Offset + 1 ) mod Sector_Size;
         else
            OK := False;    -- End file
         end if;
      end if;
   
   end Read_Char;
   
   
   ------------------------------------------------------------------
   -- READ THE NEXT TEXT LINE FROM THE TEXT FILE
   ------------------------------------------------------------------
   
   procedure Read_Line(File : in out TFCB_Type; Line : out String; Last : out Natural; OK : out Boolean) is
      Block :     Block_512;
      Count :     Unsigned_16;
      Byte :      Unsigned_8;
      End_Flag :  Boolean := False;
   begin
   
      Last := Line'First - 1;

      if Line'Length < 1 then
         OK := True;
         return;
      end if;
      
      Get(File,Block,Count,OK);
      
      if OK then
         if File.Byte_Offset >= Count then
            OK := False;
            return;
         end if;
         
         for X in Line'Range loop
            exit when File.Byte_Offset >= Count;        -- End file test
            
            Byte := Block(File.Byte_Offset);
            
            exit when Byte = 16#0D# or else Byte = 16#0A#;

            File.Byte_Offset := ( File.Byte_Offset + 1 ) mod Sector_Size;
            Line(X) := Character'Val(Byte);
            Last    := X;
            
            if File.Byte_Offset = 0 then
               Get(File,Block,Count,OK);
               exit when not OK;
            end if;
         end loop;

         loop
            exit when File.Byte_Offset >= Count;        -- End file test

            Byte := Block(File.Byte_Offset);
               
            if Byte = 16#0D# then
               File.Byte_Offset := ( File.Byte_Offset + 1 ) mod Sector_Size;
               End_Flag := True;
            elsif Byte = 16#0A# then
               File.Byte_Offset := ( File.Byte_Offset + 1 ) mod Sector_Size;
               exit;
            else
               exit;                                     -- Read line was truncated in user's buffer
            end if;
               
            if File.Byte_Offset = 0 then
               Get(File,Block,Count,OK);
               exit when not OK;
            end if;

         end loop;

      end if;
      
   end Read_Line;
   
   
   -------------------------------------------------------------------
   -- READ A BINARY RECORD
   -------------------------------------------------------------------

   procedure Read(File : in out TFCB_Type; Buffer : out U8_Array; Count : out Unsigned_16; OK : out Boolean) is
      Block :     Block_512;
      Rd_Count :  Unsigned_16;
   begin
   
      Count := 0;

      if Buffer'Length < 1 then
         OK := True;
         return;
      end if;

      Get(File,Block,Rd_Count,OK);
      
      for X in Buffer'Range loop
         exit when not OK;
         exit when File.Byte_Offset >= Rd_Count;   -- End file test
         
         Buffer(X) := Block(File.Byte_Offset);
         Count     := Count + 1;

         File.Byte_Offset := ( File.Byte_Offset + 1 ) mod Sector_Size;
         
         if File.Byte_Offset = 0 and then X < Buffer'Last then
            Get(File,Block,Rd_Count,OK);
         end if;
      end loop;
      
      if Count < 1 then
         OK := False;
      end if;

   end Read;

   -------------------------------------------------------------------
   -- Read 1 Unsigned_8
   -------------------------------------------------------------------

   procedure Read(File : in out TFCB_Type; Data : out Unsigned_8; OK : out Boolean) is
      Buffer : U8_Array(1..1);
      Count :  Unsigned_16;
   begin

      Read(File,Buffer,Count,OK);
      if OK then
         Data := Buffer(Buffer'First);
      else
         Data := 0;
      end if;

   end Read;

   -------------------------------------------------------------------
   -- Read 1 Unsigned_16
   -------------------------------------------------------------------

   procedure Read(File : in out TFCB_Type; Data : out Unsigned_16; OK : out Boolean) is
      Buffer : U8_Array(1..2);
      Count :  Unsigned_16;
   begin

      Read(File,Buffer,Count,OK);
      if OK and then Count = Buffer'Length then
         Data := Unsigned_16(Buffer(Buffer'First)) or Shift_Left(Unsigned_16(Buffer(Buffer'Last)),8);
      else
         Data := 0;
         OK   := False;
      end if;

   end Read;

   -------------------------------------------------------------------
   -- Read 1 Unsigned_32
   -------------------------------------------------------------------

   procedure Read(File : in out TFCB_Type; Data : out Unsigned_32; OK : out Boolean) is
      Buffer : U8_Array(1..4);
      Count :  Unsigned_16;
   begin

      Data := 0;
      Read(File,Buffer,Count,OK);

      if OK and then Count = Buffer'Length then
         for X in reverse Buffer'Range loop
            Data := Shift_Left(Data,8) or Unsigned_32(Buffer(X));
         end loop;
      else
         OK   := False;
      end if;

   end Read;

   ------------------------------------------------------------------
   -- CLOSE THE TEXT FILE
   ------------------------------------------------------------------
   
   procedure Close_File(File : in out TFCB_Type) is
   begin
   
      Close_File(File.FCB);
   
   end Close_File;
   
   -------------------------------------------------------------------
   -- INTERNAL - SEARCH FOR FREE CLUSTER
   -------------------------------------------------------------------
   
   procedure Internal_Locate_Cluster(Block : out Block_512; Cluster : in out Cluster_Type; OK : out Boolean) is
      Sector : Sector_Type;
      First :  Boolean := True;
   begin
      
      OK := False;

      if Cluster < 2 then
         Cluster := 2;                             -- Search from start of FAT
      end if;

      loop
         Sector := FAT_Sector(Cluster);
         exit when Is_FAT_End(Sector);
         
         if Cluster /= Next_Cluster then           -- Reserve one cluster for writes
            if FAT_Entry_Index(Cluster) = 0 or else Cluster = 2 or else First then
               First := False;
               IO_Context.Read(Sector,Block,OK);   -- Read in FAT sector
               exit when not OK;
            end if;
            
            if FAT_Entry(Block,Cluster) = 16#0000# then
               return;                             -- Free cluster located
            end if;
         end if;
         
         Cluster := Cluster + 1;
      end loop;
         
      Cluster := 0;                                -- No space or I/O error
   
   end Internal_Locate_Cluster;
   


   ------------------------------------------------------------------
   -- LOCATE A FREE CLUSTER
   ------------------------------------------------------------------
   
   procedure Locate_Cluster(Block : out Block_512; Cluster : out Cluster_Type; OK : out Boolean) is
      Retry : Boolean := Search_Cluster > 2;
   begin
      
      Internal_Locate_Cluster(Block,Search_Cluster,OK);
      if ( not OK or else Search_Cluster = 0 ) and then Retry then
         Internal_Locate_Cluster(Block,Search_Cluster,OK);
      end if;

      if OK then
         Cluster := Search_Cluster;
      else
         Cluster := 0;
      end if;

   end Locate_Cluster;
   
   
   ------------------------------------------------------------------
   -- COMPUTE FREE SPACE 
   ------------------------------------------------------------------
   
   function Free_Space return Unsigned_32 is
      Block :     Block_512;
      Space :     Unsigned_32 := 0;
      Cluster :   Cluster_Type;
      Sector :    Sector_Type;
      OK :        Boolean := True;
   begin
   
      Cluster := 2;                                   -- Skip first 2 FAT entries
      
      loop
         Sector := FAT_Sector(Cluster);
         exit when Is_FAT_End(Sector);
         
         if FAT_Entry_Index(Cluster) = 0 or else Cluster = 2 then
            IO_Context.Read(Sector,Block,OK);   -- Read in FAT sector
            exit when not OK;
         end if;
      
         if FAT_Entry(Block,Cluster) = 16#0000# then
            Space := Space + Unsigned_32(Sectors_Per_Cluster);
         end if;
      
         Cluster := Cluster + 1;
      end loop;
      
      if OK then
         return Space * Unsigned_32(Sector_Size);
      else
         return 0;               -- I/O Error
      end if;
   
   end Free_Space;
   
   
   ------------------------------------------------------------------
   -- PRE-LOCATE A FREE CLUSTER
   ------------------------------------------------------------------
   
   procedure Prelocate_Cluster(Block : out Block_512) is
      OK :        Boolean;
   begin
   
      if Next_Cluster < 2 then
         Locate_Cluster(Block,Next_Cluster,OK);
      end if;
   
   end Prelocate_Cluster;
   
   ------------------------------------------------------------------
   -- CLAIM THE CLUSTER BY MARKING IT AS LAST IN CLUSTER CHAIN
   ------------------------------------------------------------------
   
   procedure Claim_Cluster(
      Block :        out  Block_512;                      -- I/O Buffer to use
      Cluster :   in      Cluster_Type;                   -- Cluster to mark
      OK :           out  Boolean;                        -- Result of operation
      Chain :     in      Cluster_Type := Last_File_Cluster -- By default, End of Chain (EOF)
   ) is
      Sector :    Sector_Type := FAT_Sector(Cluster);
   begin
   
      if Cluster = Next_Cluster then
         Next_Cluster := 0;                              -- Mark this as in use
      end if;
      
      IO_Context.Read(sector,Block,OK);                   -- Read in the FAT cluster
      
      if OK then
         Put_FAT_Entry(Block,Cluster,Chain);             -- Mark as in use (as EOF)
         Update_FAT(Sector,Block,OK);                    -- Update all FAT copies
      end if;
   
   end Claim_Cluster;
   
   
   ------------------------------------------------------------------
   -- ALLOCATE ONE CLUSTER OF DISK SPACE
   ------------------------------------------------------------------
   
   procedure Allocate_Cluster(Block : out Block_512; Cluster : out Cluster_Type; OK : out Boolean) is
      Sector : Sector_Type;
   begin
   
      Locate_Cluster(Block,Cluster,OK);
      
      if OK then
         Put_FAT_Entry(Block,Cluster,Last_File_Cluster); -- Mark as in use (as EOF)
         Sector := FAT_Sector(Cluster);
         Update_FAT(Sector,Block,OK);
      end if;
   
   end Allocate_Cluster;
   
   
   ------------------------------------------------------------------
   -- GET THE NEXT CLUSTER IN CHAIN
   ------------------------------------------------------------------
   
   function Get_Next_Cluster(C : Cluster_Type) return Cluster_Type is
      Cluster :       Cluster_Type := C;
      Next_Cluster :  Cluster_Type;     
      Sector :        Sector_Type;      
      Block :         Block_512;
      OK :            Boolean;
   begin
   
      if not Is_Valid_Cluster(Cluster) then
         return 0;
      end if;
      
      Sector := FAT_Sector(Cluster);
      IO_Context.Read(Sector,Block,OK);   -- Read in FAT sector
      if not OK then
         return 1;
      end if;
      
      Next_Cluster := FAT_Entry(Block,Cluster);    -- Get next cluster, if any
      return Next_Cluster;
   
   end Get_Next_Cluster;
   
   
   ------------------------------------------------------------------
   -- UPDATE SECTOR IN ALL COPIES OF FAT
   ------------------------------------------------------------------
   
   procedure Update_FAT(Sector : Sector_Type; Block : in out Block_512; OK : out Boolean) is
      Sector_Offset : Sector_Type := FAT_Sector_Offset(Sector);
      Failed :        Boolean := False;
   begin
   
      for X in FAT_Start'Range loop
         if FAT_Start(X) /= 0 then
            IO_Context.Write(FAT_Start(X)+Sector_Offset,Block,OK);
            if not OK then
               Failed := True;
            end if;
         end if;
      end loop;
      
      OK := not Failed;
   
   end Update_FAT;
   
   
   ------------------------------------------------------------------
   -- COMPUTE THE FAT SECTOR OFFSET, FROM CURRENT FAT SECTOR
   ------------------------------------------------------------------
   
   function FAT_Sector_Offset(Sector : Sector_Type) return Sector_Type is
   begin
   
      return Sector - FAT_Start(FAT_Index);
   
   end FAT_Sector_Offset;
   
   
   ------------------------------------------------------------------
   -- RETURN DATA CLUSTER EOF VALUE
   ------------------------------------------------------------------
   
   function Last_File_Cluster return Cluster_Type is
   begin

      case F_System is
         when FS_FAT16 =>
            return 16#FFF8#;

         when FS_FAT32 =>
            return 16#FFFFFFF8#;

         when others =>
            return 1;               -- Should never get here
      end case;

   end Last_File_Cluster;
   

   ------------------------------------------------------------------
   -- RETURN VALUE FOR 'NO CLUSTER' OR 'BAD CLUSTER'
   ------------------------------------------------------------------
   
   function No_Cluster return Cluster_Type is
   begin

      case F_System is
         when FS_FAT16 =>
            return 16#FFF7#;

         when FS_FAT32 =>
            return 16#FFFFFFF7#;

         when others =>
            return 1;               -- Should never get here
      end case;

   end No_Cluster;
   
   
   ------------------------------------------------------------------
   -- UPDATE FAT ENTRY BASED UPON CLUSTER #
   ------------------------------------------------------------------
   
   procedure Put_FAT_Entry(Block : Block_512; Index, Cluster : Cluster_Type) is
      FAT16 :     U16_Array(0..255);                  -- FAT16 table entries
      FAT32 :     U32_Array(0..127);                  -- FAT32 table entries
      
      for FAT16'Address use Block'Address;
      for FAT32'Address use Block'Address;
      
      X :         Unsigned_16 := FAT_Entry_Index(Index);
   begin
   
      case F_System is
         when FS_FAT16 =>
            FAT16(X) := Unsigned_16(Cluster);

         when FS_FAT32 =>
            FAT32(X) := Unsigned_32(Cluster);

         when others =>
            null;
      end case;
   
   end Put_FAT_Entry;
   
   
   ------------------------------------------------------------------
   -- PERFORM A DIRECTORY SECTOR UPDATE
   ------------------------------------------------------------------
   
   procedure Update_Dir_Entry(Sector : Sector_Type; E : Dir_Entry_Type; X : Unsigned_16; OK : out Boolean) is
      Block :         Block_512;
      Dir_Entries :   Dir_Entry_Array(0..15);
      
      for Dir_Entries'Address use Block'Address;
   begin
   
      IO_Context.Read(Sector,Block,OK);
      
      if OK then
         Dir_Entries(X mod 16) := E;
         IO_Context.Write(Sector,Block,OK);
      end if;
   
   end Update_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- RELEASE A CLUSTER CHAIN 
   ------------------------------------------------------------------
   
   procedure Release_Cluster_Chain(First_Cluster : Cluster_Type; Block : out Block_512) is
      Cluster :       Cluster_Type := First_Cluster;  -- Current cluster in chain
      Next_Cluster :  Cluster_Type;                   -- Next cluster in chain
      Sector :        Sector_Type;                    -- FAT sector for cluster
      OK :            Boolean;
   begin
   
      loop
         exit when not Is_Valid_Cluster(Cluster);            -- Exit at end of chain
         
         ----------------------------------------------------------
         -- Read FAT Sector for current cluster
         ----------------------------------------------------------
         Sector := FAT_Sector(Cluster);
         IO_Context.Read(Sector,Block,OK);   -- Read in FAT sector
         exit when not OK;
         
         ----------------------------------------------------------
         -- Update the FAT Sector entry
         ----------------------------------------------------------
         Next_Cluster                 := FAT_Entry(Block,Cluster);    -- Get next cluster, if any
         Put_FAT_Entry(Block,Cluster,16#0000#);                       -- Mark this clsuter as free
         Update_FAT(Sector,Block,OK);                                 -- Update all FAT entries
         exit when not OK;
         
         Cluster := Next_Cluster;
      end loop;
   
   end Release_Cluster_Chain;
   
   
   ------------------------------------------------------------------
   -- INITIALIZE A NEW DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Initialize(Dir_Entry : out Dir_Entry_Type; Last : Boolean) is
   begin
   
      Dir_Entry.Filename      := (others => ' ');
      Dir_Entry.Extension     := (others => ' ');
      Dir_Entry.Reserved_7    := False;
      Dir_Entry.Reserved_6    := False;
      Dir_Entry.Archive       := False;
      Dir_Entry.Subdirectory  := False;
      Dir_Entry.Volume_Name   := False;
      Dir_Entry.System_File   := False;
      Dir_Entry.Hidden_File   := False;
      Dir_Entry.Read_Only     := False;
      Dir_Entry.Reserved      := (others => Character'Val(0));
      Dir_Entry.Hour          := FS_Time.Hour;
      Dir_Entry.Minute        := FS_Time.Minute;
      Dir_Entry.Second2       := FS_Time.Second2;
      Dir_Entry.Year          := FS_Time.Year;
      Dir_Entry.Month         := FS_Time.Month;
      Dir_Entry.Day           := FS_Time.Day;
      Dir_Entry.File_Size     := 0;
      
      Put_First_Cluster(Dir_Entry,Last_File_Cluster);
      
      if Last then
         Dir_Entry.Filename(1)   := Character'Val(16#00#);   -- End of directory marker
      end if;
   
   end Initialize;
   
   
   ------------------------------------------------------------------
   -- INITIALIZE A DIRECTORY BLOCK TO BE FULL OF END ENTRIES
   ------------------------------------------------------------------
   
   procedure Initialize_Dir_Cluster(Block : out Block_512; Cluster : Cluster_Type; OK : out Boolean) is
      S : Sector_Type := Cluster_Sector(Cluster);
      E : Sector_Type := S + Sector_Type(Sectors_Per_Cluster) - 1;
   begin
   
      Block := ( others => 0 );
      
      loop
         exit when S > E;
         IO_Context.Write(S,Block,OK);
         exit when not OK;
         S := S + 1;
      end loop;
   
   end Initialize_Dir_Cluster;
   
   
   ------------------------------------------------------------------
   -- LOCATE A DELETED DIR ENTRY OR ALLOCATE A NEW ONE
   ------------------------------------------------------------------
   
   procedure Allocate_Dir_Entry(
      Dir :       in out  DCB_Type;                       -- Directory control block
      Block :     in out  Block_512;                      -- I/O buffer
      Dir_Entry :    out  Dir_Entry_Type;                 -- Returned directory entry
      OK :           out  Boolean                         -- Result
   ) is
      New_Cluster :   Cluster_Type := 0;
   begin
   
      --------------------------------------------------------------
      -- Locate a Deleted Entry, if Any
      --------------------------------------------------------------
      Rewind_Dir(Dir);
      Raw_Get_Dir_Entry(Dir,Dir_Entry,OK);
      
      loop
         exit when not OK;
         exit when Is_Deleted(Dir_Entry);
         Raw_Next_Dir_Entry(Dir,Dir_Entry,OK);
      end loop;
      
      if OK then
         ----------------------------------------------------------
         -- Re-using a deleted entry
         ----------------------------------------------------------
         Initialize(Dir_Entry,False);
         Update_Dir_Entry(Dir.CCB.Cur_Sector,Dir_Entry,Dir.Cur_Index,OK);
         return;
      end if;
      
      --------------------------------------------------------------
      -- Must allocate a new directory entry
      --------------------------------------------------------------
      Initialize(Dir_Entry,True);
      
      if not Is_Dir_End(Dir) and then Is_Dir_End(Dir_Entry) then
         OK := True;
         return;                                             -- Use end marker entry
      end if;
      
      --------------------------------------------------------------
      -- See if there is a next cluster, or extend if necessary
      --------------------------------------------------------------
      
      if Dir.CCB.First_Cluster >= 2 then
         New_Cluster := Next_Cluster;                        -- Claim reserved cluster
         if New_Cluster >= 2 then
            Claim_Cluster(Block,New_Cluster,OK);            -- Put EOF marker in FAT to claim it
         else
            OK := False;                                    -- No space left
         end if;
      
         if not OK then
            return;
         end if;
      
         Initialize_Dir_Cluster(Block,New_Cluster,OK);            -- Init as new directory cluster
         if OK then
            Claim_Cluster(Block,Dir.CCB.Cluster,OK,New_Cluster); -- Link current cluster to next
         end if;
         if not OK then
            return;
         end if;
      
         Open_Cluster(Dir.CCB,New_Cluster,Keep_First => True);
         Next_Cluster := 0;
      else
         Advance_Cluster(Dir.CCB,Block,OK);                  -- Fixed size directory
         if not OK then
            return;                                         -- No space / I/O error
         end if;
      end if;
      
      Update_Dir_Entry(Dir.CCB.Cur_Sector,Dir_Entry,Dir.Cur_Index+0,OK);  -- New entry for now..
   
   end Allocate_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- CREATE A NEW DIRECTORY ENTRY USING "NAME"
   ------------------------------------------------------------------
   
   procedure Create_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; Name : String; OK : out Boolean) is
      Base :  String(1..8);
      Ext :   String(1..3);
   begin
   
      Search_Dir(Dir,Dir_Entry,Name,OK);
      if OK then
         OK := False;                            -- File already exists
         return;
      end if;
      
      Parse_Filename(Base,Ext,Name,OK);          -- Parse file name into directory format
      if not OK then
         return;
      end if;
      
      declare
         Block : Block_512;
      begin
         Prelocate_Cluster(Block);
         Allocate_Dir_Entry(Dir,Block,Dir_Entry,OK); -- Locate deleted entry or make new entry
         if not OK then
            return;                                 -- No space left
         end if;
      end;
      
      Dir_Entry.Filename  := Base;
      Dir_Entry.Extension := Ext;
      Dir_Entry.Archive   := True;
      
   end Create_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- RETURN TRUE IF THE WCB IS VALID
   ------------------------------------------------------------------
   
   function Is_Valid_File(File : WCB_Type) return Boolean is
   begin

      return File.Magic = Magic_WCB;

   end Is_Valid_File;
   
   
   ------------------------------------------------------------------
   -- OPEN A FILE BY NAME
   ------------------------------------------------------------------
   
   procedure Open_File(File : out WCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
      Dir_Entry : Dir_Entry_Type;
   begin
   
      Search_Dir(Dir,Dir_Entry,Name,OK);
      
      if OK then
         if Dir_Entry.Volume_Name or else Dir_Entry.Subdirectory then
            OK := False;
            return;
         end if;
         
         declare
            Block : Block_512;
         begin
            Release_Cluster_Chain(Get_First_Cluster(Dir_Entry),Block);
            Prelocate_Cluster(Block);           -- Keep 1 free cluster at hand
         end;
         
         Put_First_Cluster(Dir_Entry,Last_File_Cluster);
         Open_Cluster(File.CCB,Get_First_Cluster(Dir_Entry),Keep_First => False);
         
         File.Dir_Index  := Dir.Cur_Index;       -- remember which directory entry this is
         File.Dir_Sector := Dir.CCB.Cur_Sector;  -- Remember where directory entry is
         File.Magic      := Magic_WCB;
         File.Last_Sector := 0;
         OK := True;
      end if;
   
   end Open_File;
   
   
   ------------------------------------------------------------------
   -- CREATE A NEW FILE 
   ------------------------------------------------------------------
   
   procedure Create_File(File : out WCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
      E : Dir_Entry_Type;
   begin
   
      Create_Dir_Entry(Dir,E,Name,OK);            -- Allocate and create a new dir entry
      if not OK then
         return;
      end if;
      
      declare
         Block : Block_512;
      begin
         Update_Dir_Entry(Dir.CCB.Cur_Sector,E,Dir.Cur_Index,OK); -- Update dir entry
         Prelocate_Cluster(Block);               -- Keep next free cluster on hand
      end;
      
      if OK then
         Open_Cluster(File.CCB,Get_First_Cluster(E),Keep_First => False);
      
         File.Dir_Index  := Dir.Cur_Index;       -- remember which directory entry this is
         File.Dir_Sector := Dir.CCB.Cur_Sector;  -- Remember where directory entry is
         File.Magic      := Magic_WCB;
         File.Last_Sector := 0;
         OK := True;
      end if;
   
   end Create_File;
   
   
   ------------------------------------------------------------------
   -- WRITE NEXT SECTOR, GET NEXT/EXTEND CLUSTER AND WRITE 
   ------------------------------------------------------------------
   
   procedure Write_Cluster(File : in out WCB_Type; Block : in out Block_512; OK : out Boolean) is
      New_Cluster :   Cluster_Type := 0;
      X :             Unsigned_16;
   begin
   
      if File.CCB.Cur_Sector = 0 then
         -- We have an empty new file to write
         null;
      elsif not Is_Valid_CCB(File.CCB) then
         OK := False;
         return;
      end if;
      
      if Unsigned_16(File.CCB.Cur_Sector - File.CCB.Start_Sector) >= File.CCB.Sector_Count
      or else File.CCB.Cur_Sector = 0 then
         ----------------------------------------------------------
         -- Add first cluster or add a new cluster
         ----------------------------------------------------------
         if Next_Cluster < 2 then
            OK := False;
            return;             -- No more space or I/O error(s)
         end if;
      
         ----------------------------------------------------------
         -- Save write data to the new cluster
         ----------------------------------------------------------
         New_Cluster := Next_Cluster;
         IO_Context.Write(Cluster_Sector(New_Cluster),Block,OK);
         if not OK then            
            return;             -- I/O error
         end if;
         
         ----------------------------------------------------------
         -- Tell FAT that we've claimed this cluster
         ----------------------------------------------------------
         Claim_Cluster(Block,New_Cluster,OK);
         if not OK then
            return;
         end if;
         
         ----------------------------------------------------------
         -- When adding the first cluster, we must update the
         -- file's directory entry with the cluster #
         ----------------------------------------------------------
         if File.CCB.Cur_Sector = 0 then
            declare
               Dir : Dir_Entry_Array(0..15);
               for Dir'Address use Block'Address;
            begin
               IO_Context.Read(File.Dir_Sector,Block,OK);
               
               if OK then
                  X := File.Dir_Index mod 16;
                  Put_First_Cluster(Dir(X),New_Cluster);
                  IO_Context.Write(File.Dir_Sector,Block,OK);
               end if;
            end;
            
            if OK then
               Open_Cluster(File.CCB,New_Cluster,Keep_First => False);
            else
               return;                                         -- I/O Error
            end if;
         else
            ------------------------------------------------------
            -- Otherwise add a cluster to this file's chain
            ------------------------------------------------------
            Claim_Cluster(Block,File.CCB.Cluster,OK,New_Cluster); -- Link current cluster to next
            if OK then
               Open_Cluster(File.CCB,New_Cluster,Keep_First => True);
            else
               return;
            end if;
         end if;
         
         File.CCB.IO_Bytes := File.CCB.IO_Bytes + Unsigned_32(Sector_Size);
         
         Prelocate_Cluster(Block);                               -- Get next free cluster
         IO_Context.Read(File.CCB.Cur_Sector,Block,OK);          -- Restore user's buffer
      else
         IO_Context.Write(File.CCB.Cur_Sector,Block,OK);         -- Ah, a simple write
         if OK then
            File.CCB.IO_Bytes    := File.CCB.IO_Bytes + Unsigned_32(Sector_Size);
         end if;
      end if;
      
      File.CCB.Prev_Sector := File.CCB.Cur_Sector;        -- The sector just written
      File.CCB.Cur_Sector  := File.CCB.Cur_Sector + 1;    -- The next write goes here
   
   end Write_Cluster;    
   
   
   ------------------------------------------------------------------
   -- WRITE TO THE OPEN FILE
   ------------------------------------------------------------------
   
   procedure Write_File(File : in out WCB_Type; Block : in out Block_512; Count : Unsigned_16; OK : out Boolean) is
   begin
   
      if not Is_Valid_File(File) or else Count > Block'Length or else Count = 0 then
         OK := False;
         return;
      end if;
      
      --------------------------------------------------------------
      -- Clear excess portion of block, if any
      --------------------------------------------------------------
      if Count < Block'Length then
         Block(Count..Block'Last) := ( others => 16#00# );
      end if;
      
      Write_Cluster(File,Block,OK);
      if OK then
         File.Last_Sector := Count;
      end if;
   
   end Write_File;
   
   
   ------------------------------------------------------------------
   -- REWRITE THE LAST WRITTEN BLOCK
   ------------------------------------------------------------------
   
   procedure Rewrite_File(File : in out WCB_Type; Block : in out Block_512; Count : Unsigned_16; OK : out Boolean) is
   begin
   
      if not Is_Valid_File(File) or else File.CCB.Prev_Sector = 0 then
         OK := False;
         return;
      end if;
      
      IO_Context.Write(File.CCB.Prev_Sector,Block,OK);
      if OK then
         File.Last_Sector := Count;
      end if;
   
   end Rewrite_File;
   
   
   ------------------------------------------------------------------
   -- CLOSE A FILE OPEN FOR WRITE
   ------------------------------------------------------------------
   
   procedure Close_File(File : in out WCB_Type; OK : out Boolean) is
   begin
   
      Sync_File(File,OK);
      if OK then
         Close_Cluster(File.CCB);
      end if;
      File.Magic := 0;
   
   end Close_File;
   
   
   ------------------------------------------------------------------
   -- FLUSH OUT ALL DATA ETC., DO ALL BUT CLOSE THE FILE
   ------------------------------------------------------------------
   
   procedure Sync_File(File : in out WCB_Type; OK : out Boolean) is
      Block :     Block_512;
      Dir :       Dir_Entry_Array(0..15);
      X :         Unsigned_16;
      
      for Dir'Address use Block'Address;
   begin
   
      if not Is_Valid_File(File) then
         OK := False;
         return;
      end if;
      
      --------------------------------------------------------------
      -- Update File's size in directory entry
      --------------------------------------------------------------
      IO_Context.Read(File.Dir_Sector,Block,OK);
      
      if OK then
         X := File.Dir_Index mod 16;
         
         Dir(X).Year      := FS_Time.Year;
         Dir(X).Month     := FS_Time.Month;
         Dir(X).Day       := FS_Time.Day;
         Dir(X).Hour      := FS_Time.Hour;
         Dir(X).Minute    := FS_Time.Minute;
         Dir(X).Second2   := FS_Time.Second2;
         Dir(X).Archive   := True;

         if File.Last_Sector > 0 and then File.Last_Sector /= Sector_Size then
            Dir(X).File_Size := File.CCB.IO_Bytes - Unsigned_32(Sector_Size)
               + Unsigned_32(File.Last_Sector);
         else
            Dir(X).File_Size := File.CCB.IO_Bytes;
         end if;
         
         IO_Context.Write(File.Dir_Sector,Block,OK);
      end if;
   
   end Sync_File;
   
   
   ------------------------------------------------------------------
   -- DELETE A FILE BY NAME
   ------------------------------------------------------------------
   
   procedure Delete_File(Dir : in out DCB_Type; Name : String; OK : out Boolean) is
      E : Dir_Entry_Type;
   begin
   
      Search_Dir(Dir,E,Name,OK);
      if not OK then
         return;
      end if;
      
      if E.Volume_Name or else E.Subdirectory then
         OK := False;
         return;
      end if;
      
      declare
         Block :     Block_512;
         Cluster :   Cluster_Type := Get_First_Cluster(E);
      begin
         E.Filename(1) := Character'Val(16#E5#);
         E.File_Size   := 0;
         Put_First_Cluster(E,Last_File_Cluster);
         Update_Dir_Entry(Dir.CCB.Cur_Sector,E,Dir.Cur_Index,OK);
         if OK then
            Release_Cluster_Chain(Cluster,Block);
         end if;
      end;
   
   end Delete_File;
   
   
   ------------------------------------------------------------------
   -- OPEN AN EXISTING FILE FOR WRITING TEXT
   ------------------------------------------------------------------
   
   procedure Open_File(File : out TWCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
   begin
   
      File.Byte_Offset := 0;
      Open_File(File.WCB,Dir,Name,OK);
   
   end;
   
   
   ------------------------------------------------------------------
   -- CREATE A NEW FILE TO WRITE TEXT TO
   ------------------------------------------------------------------
   
   procedure Create_File(File : out TWCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean) is
   begin
   
      File.Byte_Offset := 0;
      Create_File(File.WCB,Dir,Name,OK);
   
   end Create_File;
   
   
   ------------------------------------------------------------------
   -- INTERNAL - GET PARTIAL BUFFER BEFORE APPENDING TEXT
   ------------------------------------------------------------------
   
   procedure Get(File : in out TWCB_Type; Block : in out Block_512; OK : out Boolean) is
   begin
   
      OK := Is_Valid_File(File.WCB);
      
      if OK then
         if File.Byte_Offset > 0 then
            IO_Context.Read(File.WCB.CCB.Prev_Sector,Block,OK);
         else
            Block := ( others => 0 );
         end if;
      end if;
   
   end Get;
   
   
   ------------------------------------------------------------------
   -- INTERNAL - PUT OUT TEXT IN A BLOCK
   ------------------------------------------------------------------
   
   procedure Put(File : in out TWCB_Type; Block : in out Block_512; Count : Unsigned_16; OK : out Boolean) is
   begin
   
      if File.Byte_Offset = 0 then
         Write_File(File.WCB,Block,Count,OK);    -- Start a new sector of text
      else
         Rewrite_File(File.WCB,Block,Count,OK);  -- Update last sector of text
      end if;
      
      pragma Assert(Count <= Sector_Size);
      
      if Count >= Sector_Size then
         File.Byte_Offset := 0;
      else
         File.Byte_Offset := Count;
      end if;
   
   end Put;
   
   
   ------------------------------------------------------------------
   -- PUT ONE CHARACTER OF TEXT TO FILE
   ------------------------------------------------------------------
   
   procedure Put(File : in out TWCB_Type; Char : Character; OK : out Boolean) is
      Block : Block_512;
      Count : Unsigned_16 := Unsigned_16(File.Byte_Offset) + 1;
   begin
   
      Get(File,Block,OK);
      if OK then
         Block(File.Byte_Offset) := Unsigned_8(Character'Pos(Char));
         Put(File,Block,Count,OK);
      end if;
   
   end Put;
   
   
   ------------------------------------------------------------------
   -- PUT STRING OF TEXT TO FILE
   ------------------------------------------------------------------
   
   procedure Put(File : in out TWCB_Type; Text : String; OK : out Boolean) is
      Block : Block_512;
      Count : Unsigned_16 := File.Byte_Offset;
   begin
   
      if Text'Length < 1 then
         OK := True;
         return;
      end if;

      Get(File,Block,OK);
      
      for X in Text'Range loop
         exit when not OK;

         Block(Count) := Unsigned_8(Character'Pos(Text(X)));
         Count := Count + 1;

         if Count >= Sector_Size then
            Put(File,Block,Count,OK);
            Count := 0;
         end if;
      end loop;
         
      if OK and then Count > 0 then
         Put(File,Block,Count,OK);
      end if;
   
   end Put;
   
   
   ------------------------------------------------------------------
   -- PUT ONE LINE OF TEXT TO A FILE (WITH IMPLIED NEW_LINE)
   ------------------------------------------------------------------
   
   procedure Put_Line(File : in out TWCB_Type; Text : String; OK : out Boolean) is
   begin
   
      Put(File,Text,OK);
      if OK then
         New_Line(File,OK);
      end if;
   
   end Put_Line;
   
   
   -------------------------------------------------------------------
   -- WRITE A BINARY ARRAY OF COUNT BYTES
   -------------------------------------------------------------------

   procedure Write(File : in out TWCB_Type; Buffer : U8_Array; OK : out Boolean) is
      Text : String(1..Buffer'Length);
      for Text'Address use Buffer'Address;
   begin

      Put(File,Text,OK);

   end Write;

   -------------------------------------------------------------------
   -- WRITE ONE UNSIGNED_8
   -------------------------------------------------------------------

   procedure Write(File : in out TWCB_Type; Data : Unsigned_8; OK : out Boolean) is
      Buffer : U8_Array(1..1);
   begin

      Buffer(Buffer'First) := Data;
      Write(File,Buffer,OK);

   end Write;

   -------------------------------------------------------------------
   -- WRITE ONE UNSIGNED_16
   -------------------------------------------------------------------

   procedure Write(File : in out TWCB_Type; Data : Unsigned_16; OK : out Boolean) is
      Buffer : U8_Array(1..2);
   begin

      Buffer(Buffer'First+0) := Unsigned_8( Data and 16#FF# );
      Buffer(Buffer'First+1) := Unsigned_8( Shift_Right(Data,8) );

      Write(File,Buffer,OK);

   end Write;

   -------------------------------------------------------------------
   -- WRITE ONE UNSIGNED_32
   -------------------------------------------------------------------

   procedure Write(File : in out TWCB_Type; Data : Unsigned_32; OK : out Boolean) is
      Buffer : U8_Array(1..4);
      Temp :   Unsigned_32 := Data;
   begin

      for X in Buffer'Range loop
         Buffer(X) := Unsigned_8( Temp and 16#FF# );
         Temp      := Shift_Right(Temp,8);
      end loop;
      Write(File,Buffer,OK);

   end Write;


   ------------------------------------------------------------------
   -- PUT THE LINE TERMINATOR OUT TO THE TEXT FILE
   ------------------------------------------------------------------
   
   procedure New_Line(File : in out TWCB_Type; OK : out Boolean) is
      CRLF : constant String(1..2) := ( Character'Val(16#0D#), Character'Val(16#0A#) );
   begin
   
      Put(File,CRLF,OK);
      
   end New_Line;
   
   
   ------------------------------------------------------------------
   -- FORCE UPDATE OF FILE SIZE IN DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   procedure Sync_File(File : in out TWCB_Type; OK : out Boolean) is
   begin
   
      Sync_File(File.WCB,OK);
   
   end Sync_File;
   
   
   ------------------------------------------------------------------
   -- CLOSE THE TEXT FILE 
   ------------------------------------------------------------------
   
   procedure Close_File(File : in out TWCB_Type; OK : out Boolean) is
   begin
   
      Close_File(File.WCB,OK);
   
   end Close_File;
   
   
   ------------------------------------------------------------------
   -- CREATE A SUBDIRECTORY
   ------------------------------------------------------------------
   
   procedure Create_Subdir(Dir : in out DCB_Type; Subdir : String; OK : out Boolean) is
      E :             Dir_Entry_Type;
      New_Cluster :   Cluster_Type := 0;
   begin
   
      Create_Dir_Entry(Dir,E,Subdir,OK);
      if not OK then
         return;
      end if;
      
      declare
         Block : Block_512;
      begin
         Prelocate_Cluster(Block);                       -- Get a free cluster for subdir
         if Next_Cluster = 0 then
            OK := False;                                -- No space
            return;
         end if;
      
         New_Cluster := Next_Cluster;
         Put_First_Cluster(E,Next_Cluster);              -- Assign cluster to subdir entry
         Claim_Cluster(Block,New_Cluster,OK);            -- Mark it as in use with FFF8 entry
         if OK then
            Prelocate_Cluster(Block);                   -- Replace free cluster, that we used
            Initialize_Dir_Cluster(Block,New_Cluster,OK); -- Initialize with "end dir" entries
            if OK then
               E.Subdirectory := True;
               Update_Dir_Entry(Dir.CCB.Cur_Sector,E,Dir.Cur_Index,OK); -- Update dir entry now
            end if;
         end if;
      end;
   
   end Create_Subdir;
   
   
   ------------------------------------------------------------------
   -- UPDATE DIRECTORY WITH NEW DIRECTORY ENTRY CONTENT
   ------------------------------------------------------------------
   
   procedure Update_Dir_Entry(D : DCB_Type; E : Dir_Entry_Type; OK : out Boolean) is
   begin
   
      Update_Dir_Entry(D.CCB.Cur_Sector,E,D.Cur_Index,OK);
   
   end Update_Dir_Entry;
   
   
   ------------------------------------------------------------------
   -- DELETE THE CONTENTS OF INDICATED SUBDIR
   ------------------------------------------------------------------
   
   procedure Delete_Contents(Subdir : Dir_Entry_Type; OK : out Boolean) is
      D :         DCB_Type;
      E :         Dir_Entry_Type;
      Failed :    Boolean := False;
   begin
   
      Open_Dir(D,Subdir,Ok);
      if OK then
         Get_Dir_Entry(D,E,OK);
         loop
            exit when not OK;
            
            if E.Subdirectory then
               if E.Filename(1) /= '.' then
                  Delete_Subdir(D,Filename(E),OK);
               end if;
            else
               Delete_File(D,Filename(E),OK);
            end if;
            
            if not OK then
               Failed := True;
            end if;
            
            Next_Dir_Entry(D,E,OK);
         end loop;
         Close_Dir(D);
      else
         Failed := True;
      end if;
      
      OK := not Failed;
   
   end Delete_Contents;
   
   
   ------------------------------------------------------------------
   -- DELETE SUBDIRECTORY AND IT'S CONTENTS
   ------------------------------------------------------------------
   
   procedure Delete_Subdir(Dir : in out DCB_Type; Subdir : String; OK : out Boolean) is
      Ucased_Subdir : String := Uppercase(Subdir);
      E :             Dir_Entry_Type;
   begin
   
      if not Is_Valid_Dir(Dir) or else Subdir(Subdir'First) = '.' then
         OK := False;
         return;
      end if;
   
      Rewind_Dir(Dir);
      Get_Dir_Entry(Dir,E,OK);
      
      loop
         exit when not OK;
         
         if E.Subdirectory and then Filename(E) = Ucased_Subdir then
            Delete_Contents(E,OK);          -- Delete files and subdirs contained within this subdir
            if OK then                      -- Now for the subdir itself..
               E.Filename(1) := Character'Val(16#E5#);     -- Mark as deleted
               Update_Dir_Entry(Dir,E,OK);                 -- Update dir entry
               declare                                     -- Release subdir's content
                  Block : Block_512;
               begin
                  Release_Cluster_Chain(Get_First_Cluster(E),Block);
               end;
            end if;
            return;
         end if;
         
         Next_Dir_Entry(Dir,E,OK);
      end loop;
   
   end Delete_Subdir;
   
   
   ------------------------------------------------------------------
   -- RENAME A FILE SYSTEM OBJECT
   ------------------------------------------------------------------
   
   procedure Rename(Dir : in out DCB_Type; Old_Name, New_Name : String; OK : out Boolean) is
      E : Dir_Entry_Type;
   begin
   
      if not Is_Valid_Dir(Dir) or else Old_Name(Old_Name'First) = '.' then
         OK := False;
         return;
      end if;
      
      Search_Dir(Dir,E,New_Name,OK);
      if not OK then
         Search_Dir(Dir,E,Old_Name,OK);
         if OK then
            Get_Dir_Entry(Dir,E,OK);
            if OK then
               Parse_Filename(E.Filename,E.Extension,New_Name,OK);
               if OK then
                  Update_Dir_Entry(Dir,E,OK);      -- Update dir entry
               end if;
            end if;
         end if;
      else
         OK := False;                                -- New_Name exists
      end if;
   
   end Rename;
   
   
   ------------------------------------------------------------------
   -- UPDATE FILE OBJECT'S ATTRIBUTES 
   ------------------------------------------------------------------
   procedure Update_Attributes(Dir : in out DCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean) is
      Block :         Block_512;
      Dir_Entries :   Dir_Entry_Array(0..15);
      for Dir_Entries'Address use Block'Address;
   begin
   
      IO_Context.Read(Dir.CCB.Cur_Sector,Block,OK);
      if OK then
         ----------------------------------------------------------
         -- Only update selected attributes
         ----------------------------------------------------------
         Dir_Entries(Dir.Cur_Index mod 16).Archive       := Dir_Entry.Archive;
         Dir_Entries(Dir.Cur_Index mod 16).System_File   := Dir_Entry.System_File;
         Dir_Entries(Dir.Cur_Index mod 16).Hidden_File   := Dir_Entry.Hidden_File;
         Dir_Entries(Dir.Cur_Index mod 16).Read_Only     := Dir_Entry.Read_Only;
         IO_Context.Write(Dir.CCB.Cur_Sector,Block,OK);
      end if;
   
   end Update_Attributes;
   
   
   ------------------------------------------------------------------
   -- MAKE ALL SUBDIRS ALONG THE PATH
   ------------------------------------------------------------------
   
   procedure Create_Path(Dir : out DCB_Type; Pathname : String; OK : out Boolean) is
      X, Y :  Natural;
      Base :  String(1..8);
      Ext :   String(1..3);
   begin
   
      X := Pathname'First;
      
      Open_Dir(Dir,OK);
      
      loop
         exit when not OK;
         
         loop  -- skip over '/'
            if X > Pathname'Last then
               OK := True;
               return;                 -- Reached end of Pathname
            end if;
            exit when not Is_Separator(Pathname(X));
            X := X + 1;
         end loop;
         
         Y := X + 1;
         loop
            exit when Y > Pathname'Last;
            exit when Is_Separator(Pathname(Y));
            Y := Y + 1;
         end loop;
      
         if Pathname(X..Y-1) /= "." then
            Parse_Filename(Base,Ext,Pathname(X..Y-1),OK);   -- Does this respect 8.3 format?
            exit when not OK;
            
            Open_Dir(Dir,Pathname(X..Y-1),OK);
            
            if not OK then
               Create_Subdir(Dir,Pathname(X..Y-1),OK); -- Create the subdir
               exit when not OK;                       -- exit if failed
               Open_Dir(Dir,Pathname(X..Y-1),OK);      -- Now open the subdir
            end if;
         
         exit when not OK;
         end if;
         
         X := Y;
      end loop;
      
      Close_Dir(Dir);
      OK := False;                                    -- Failed
   
   end Create_Path;
   
   
   ------------------------------------------------------------------
   -- FORMAT A FILE SYSTEM
   ------------------------------------------------------------------
   
   procedure Format(
      Total_Sectors :         in      Sector_Type;            -- Device # of sectors
      Sectors_Per_Cluster :   in      Unsigned_8;             -- Sectors per cluster
      OK :                       out  Boolean;                -- Result of format
      Root_Dir_Entries_16 :   in      Unsigned_16 := 512;     -- FAT16 Directory entries
      OEM_Name :              in      String := "FATFS";      -- OEM Name to use
      No_Of_FATs :            in      FAT_Copies_Type := 1;   -- # of FATs (4 max)
      Reserved_Sectors :      in      Unsigned_16 := 1        -- Reserved sectors, including boot sector
   ) is
      FS_Kind :           FS_Type := FS_FAT16;                -- File system type
      Sector :            Sector_Type;                        -- Current sector
      Block :             Block_512;                          -- I/O sector buffer
      Boot :              Boot_Sector_Type;                   -- Boot sector layout
      Sectors_Per_FAT :   Unsigned_32;                        -- # of sectors per FAT
      No_Of_Clusters :    Unsigned_32;                        -- # of clusters per device
      Root_Entries :      Unsigned_16 := 0;                   -- # of root entries for FAT16 (only)
   
      Media_Descriptor :  constant Unsigned_8 := 16#F8#;   -- Hard drive
      FS_Version_Major :  constant Unsigned_8 := 224;
      FS_Version_Minor :  constant Unsigned_8 := 32;
      Bytes_Per_Sector :  constant Unsigned_16 := 512;
      
      for Boot'Address use Block'Address;
      
   begin
      
      if No_Of_FATs < 1
      or else No_Of_FATs > 4
      or else Reserved_Sectors < 1 then
         OK := False;
         return;
      end if;
      
      FAT_Count   := No_Of_FATs;
      FAT_Index   := 1;

      Block := ( others => 0 );
      
      if OEM_Name'Length > Boot.OEM_Name'Length then
         OK := False;
         return;
      end if;
      
      Boot.OEM_Name               := (others => ' ');
      Boot.OEM_Name(Boot.OEM_Name'First..Boot.OEM_Name'First+OEM_Name'Length-1) := OEM_Name;
      
      Boot.Bytes_Per_Sector       := Bytes_Per_Sector;
      Boot.Reserved_Sectors       := Reserved_Sectors;    -- This includes the boot sector itself
      Boot.FAT_Copies             := No_Of_FATs;
      
      declare
         BF :    Unsigned_32 := 2;                       -- # of FAT entries per sector (initially FAT16)
         E :     Unsigned_32 := Unsigned_32(Bytes_Per_Sector) / BF;   -- Entries per FAT sector
         SC :    Unsigned_32 := Unsigned_32(Sectors_Per_Cluster); -- Sectors for each cluster
         T :     Unsigned_32 := Unsigned_32(Total_Sectors);
         R :     Unsigned_32 := Unsigned_32(Reserved_Sectors);
         N :     Unsigned_32 := Unsigned_32(No_Of_FATs);         -- # of FAT Tables
         D :     Unsigned_32 := Unsigned_32(Root_Dir_Entries_16);
         S1 :    Unsigned_32;                                    -- Available sectors trial 1 value
         C1 :    Unsigned_32;                                    -- Preliminary # of clusters
         F1 :    Unsigned_32;                                    -- Preliminary # of sectors used by FAT
         S2 :    Unsigned_32;                                    -- 2nd trial avail # of sectors
         C2 :    Unsigned_32;                                    -- 2nd trial value for # of clusters
         F2 :    Unsigned_32;                                    -- 2nd # of sectors used by FAT
         S3 :    Unsigned_32;                                    -- 2nd trial avail # of sectors
         C3 :    Unsigned_32;                                    -- 2nd trial value for # of clusters
         H :     Unsigned_32;                                    -- Hidden sectors (unused sectors)
      begin
   
         S1 := T - R - (D + 31) / 32;            -- Sectors ignoring FAT and clusters
         C1 := S1 / SC;                          -- Trial # of clusters
         
         if FS_Kind = FS_FAT16 and then C1 + 2 >= 16#FFF0# then
            FS_Kind := FS_FAT32;
            BF := 4;
            E  := Unsigned_32(Bytes_Per_Sector) / BF;
            D  := 0;                            -- FAT32 puts root dir in a cluster
            S1 := T - R - (D + 31) / 32;        -- Sectors ignoring FAT and clusters
            C1 := S1 / SC;                      -- Trial # of clusters for FAT32
         end if;
      
         F1 := (C1 + E - 1) / E;                 -- First trial # of sectors per FAT
      
         S2 := T - R - (D + 31) / 32 - F1 * N;   -- 2nd improved estimate of avail sectors for clusters
         C2 := S2 / SC;                          -- 2nd trial # for cluster count
         F2 := (C2 + E - 1) / E;                 -- 2nd sector count per FAT table
         
         S3 := T - R - (D + 31) / 32 - F2 * N;   -- 3rd improved estimate of avail sectors for clusters
         C3 := S3 / SC;                          -- 3rd trial # for cluster count
         
         H  := S3 - C3 * SC;                     -- Left over sectors
         
         No_Of_Clusters := C3;                   -- Save local copy of this value
      
         if FS_Kind = FS_FAT16 then
            if Total_Sectors > 16#FFFF# then
               OK := False;
               return;
            end if;
            Boot.Total_Sectors_in_FS := Unsigned_16(Total_Sectors);     -- # of sectors per device
            Boot.Root_Dir_Entries    := Root_Dir_Entries_16;            -- # of root dir entries
            Boot.Total_Sectors_32    := 0;                              -- FAT32 only
            Boot.Root_Dir_First_Cluster := 0;                           -- FAT32 only
            Root_Entries             := Boot.Root_Dir_Entries;          -- Save local copy
            
            Boot.Sectors_Per_FAT    := Unsigned_16(F2);
            Boot.Sectors_Per_FAT_32 := 0;
            Sectors_Per_FAT         := F2;      -- Local copy of value
         else
            Boot.Total_Sectors_in_FS := 0;                              -- Must be zero
            Boot.Root_Dir_Entries    := 0;                              -- ditto
            Boot.Total_Sectors_32    := Unsigned_32(Total_Sectors);     -- # of sectors per device
            Boot.Root_Dir_First_Cluster := 16#0002#;                    -- Start with first cluster
            Root_Entries             := 0;                              -- Using cluster instead
            
            Boot.Sectors_Per_FAT_32 := F2;
            Boot.Sectors_Per_FAT    := 0;
            Sectors_Per_FAT         := F2;      -- Local copy of value
         end if;
         
         Boot.Hidden_Sectors_32      := H;       -- Hidden & unusable
      end;
   
      Boot.Sectors_Per_Cluster    := Sectors_Per_Cluster;
      Boot.Media_Descriptor       := Media_Descriptor;                -- Hard disk (varies)
      Boot.Sectors_Per_Track      := 128;                             -- unimportant
      Boot.No_Of_Heads            := 64;                              -- ditto
      Boot.Mirror_Flags           := 16#00#;                          -- No flags
      Boot.FS_Version_Major       := FS_Version_Major;                -- File system major version
      Boot.FS_Version_Minor       := FS_Version_Minor;                -- FS minor version
      Boot.FS_Info_Sector         := 0;                               -- None??
      Boot.Backup_Boot_Sector     := 0;                               -- None??
      Boot.Signature              := ( 16#55#, 16#AA# );              -- Signature bytes
      
      --------------------------------------------------------------
      -- Write out the boot sector
      --------------------------------------------------------------
      IO_Context.Write(0,Block,OK);
      if not OK then
         return;
      end if;
   
      Root_Entries := Boot.Root_Dir_Entries;
   
      --------------------------------------------------------------
      -- Write out zeroed reserved sectors
      --------------------------------------------------------------
      Block := ( others => 0 );
      
      for X in 1..Reserved_Sectors loop
         IO_Context.Write(Sector_Type(X),Block,OK);
         if not OK then
            return;
         end if;
      end loop;
   
      --------------------------------------------------------------
      -- Write out FAT Table(s)
      --------------------------------------------------------------
      Sector       := Sector_Type(Reserved_Sectors);
      FAT_Start(1) := Sector;
      
      for X in 2..No_Of_FATs loop
         FAT_Start(X) := FAT_Start(X-1) + Sector_Type(Sectors_Per_FAT);
      end loop;

      for X in 1..No_Of_FATs loop
         Block(0) := Media_Descriptor;
         Block(1) := 16#FF#;
         if FS_Kind = FS_FAT16 then
            Block(2) := 16#F8#;
            Block(3) := 16#FF#;
         else
            Block(2) := 16#FF#;
            Block(3) := 16#FF#;
            
            Block(4) := 16#F8#;
            Block(5) := 16#FF#;
            Block(6) := 16#FF#;
            Block(7) := 16#FF#;
            
            Block(8) := 16#F8#;     -- This is for root dir cluster 2
            Block(9) := 16#FF#;
            Block(10) := 16#FF#;
            Block(11) := 16#FF#;
         end if;
   
         for Y in 1..Sectors_Per_FAT loop
            IO_Context.Write(Sector,Block,OK);
            if not OK then
               return;
            end if;
            Sector := Sector + 1;
            if Y = 1 and then X = 1 then
               Block := ( others => 0 );
            end if;
         end loop;
      end loop;
   
      case FS_Kind is
         when FS_FAT16 =>
            FAT_Mod := 256;
         when FS_FAT32 =>
            FAT_Mod := 128;
         when others =>
            null;
      end case;
         
      --------------------------------------------------------------
      -- Write out root directory, if any
      --------------------------------------------------------------
      F_System := FS_Kind;

      if FS_Kind = FS_FAT16 then
         Block := ( others => 0 );
         for X in 1..Unsigned_32( Root_Entries * 32 ) / Unsigned_32(Bytes_Per_Sector) loop
            IO_Context.Write(Sector,Block,OK);
            if not OK then
               return;
            end if;
            Sector := Sector + 1;
         end loop;
      end if;
   
      --------------------------------------------------------------
      -- For FAT32, clear out Root Directory Cluster
      --------------------------------------------------------------
      if FS_Kind = FS_FAT32 then
         Block := ( others => 0 );
         for X in 1..Sectors_Per_Cluster loop
            IO_Context.Write(Sector,Block,OK);
            if not OK then
               return;
            end if;
            Sector := Sector + 1;
         end loop;
      end if;
   
      ----------------------------------------------------------------
      -- Here we mark all 'unavailable clusters' at the end of the
      -- FAT table as 'unavailable' (or 'bad')
      ----------------------------------------------------------------
      declare
         C :   Cluster_Type := Cluster_Type(No_Of_Clusters + 1);           -- 1st unavailable cluster
         E :   Sector_Type := FAT_Start(1) + Sector_Type(Sectors_Per_FAT); -- 1st sector past end of 1st FAT
         S :   Sector_Type := FAT_Sector(C);                               -- Current & Next FAT sector
         L :   Sector_Type := 0;                                           -- Current FAT sector #
      begin

         loop
            exit when S >= E;                                  -- Hit end of FAT?

            if S /= L then                                     -- First or change of sector?
               IO_Context.Read(S,Block,OK);                    -- Read FAT sector
               exit when not OK;
               L := S;                                         -- Make it "current"
            end if;

            Put_FAT_Entry(Block,C,No_Cluster);

            C := C + 1;                                        -- Next cluster #
            S := FAT_Sector(C);                                -- Which FAT sector is the entry in?

            if S /= L then                                     -- Next sector?
               Update_FAT(L,Block,OK);                         -- If so, update current FAT sector
               exit when not OK;
            end if;
         end loop;

      end;

   end Format;
   
end FATFS;
