-- fatfs.ads - Mon Nov  1 10:09:32 2010
--
-- Author: Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

----------------------------------------------------------------------
-- 
-- 
-- This package provides a FAT16/32 file system capability, 
-- targeted for SD/MMC memory cards (although it may also be used
-- in other ways as well).
-- 
-- See "Implementation Notes" at the end of this file for more
-- details.
-- 
----------------------------------------------------------------------

with Interfaces;
use Interfaces;

package FATFS is

   ------------------------------------------------------------------
   -- ARRAY DATA TYPES
   ------------------------------------------------------------------
   
   type U8_Array is array(Unsigned_16 range <>) of Unsigned_8;
   for U8_Array'Component_Size use 8;
   
   type U16_Array is array(Unsigned_16 range <>) of Unsigned_16;
   for U16_Array'Component_Size use 16;
   for U16_Array'alignment use 4;
   
   type U32_Array is array(Unsigned_16 range <>) of Unsigned_32;
   for U32_Array'Component_Size use 32;
   for U32_Array'alignment use 4;
   
   -------------------------------------------------------------------
   -- FILE SYSTEM TYPE
   -------------------------------------------------------------------

   type FS_Type is (
      FS_FAT12,                       -- FAT12 (unsupported)
      FS_FAT16,                       -- FAT16
      FS_FAT32,                       -- FAT32
      FS_Unknown                      -- Unknown or bad media
   );
   
   type FAT_Copies_Type is new Unsigned_8;      -- # of FAT tables
   type Sector_Type is new Unsigned_32;         -- Disk sector #
   type Cluster_Type is new Sector_Type;        -- Cluster #

   type Sector_Array is array(FAT_Copies_Type range <>) of Sector_Type;
   type Block_Type is array(Unsigned_16 range <>) of Unsigned_8;
   for Block_Type'Component_Size use 8;
   for Block_Type'Alignment use 4;
   
   subtype Bytes is Block_Type;
   subtype Block_512 is Block_Type(0..511);

   -------------------------------------------------------------------
   -- DIRECTORY ENTRY TYPES
   -------------------------------------------------------------------

   type DCB_Type is private;           -- Directory control block
   
   type Year_Type is mod 2**7;         -- Year in directory entry (minus 1980)
   type Month_Type is mod 2**4;        -- Month in directory entry
   type Day_Type is mod 2**5;          -- Day in directory entry
   type Hour_Type is mod 2**5;         -- Hour in directory entry
   type Minute_Type is mod 2**6;       -- Minute in directory entry
   type Seconds2_Type is mod 2**5;     -- Seconds / 2 in directory entry
   
   ------------------------------------------------------------------
   -- FAT32 BOOT SECTOR
   ------------------------------------------------------------------
   
   type Boot_Sector_Type is record
      Jump :                  Bytes(0..2);        -- 0-2 :    Jump to bootstrap
      OEM_Name :              String(3..10);      -- 3-10 :   OEM name/version (E.g. "IBM  3.3", "IBM 20.0", "MSDOS5.0")
      Bytes_Per_Sector :      Unsigned_16;        -- 11-12 :  Bytes per sector (512 for FAT12)
      Sectors_Per_Cluster :   Unsigned_8;         -- 13 :     1, 2, 3, 8, 16, 32, 64, 128
      Reserved_Sectors :      Unsigned_16;        -- 14-15 :  For FAT 12/16 = 1, FAT32 = 32
      FAT_Copies :            FAT_Copies_Type;    -- 16 :     2
      Root_Dir_Entries :      Unsigned_16;        -- 17-18 :  FAT12=224, FAT32=0, 512 recommended for FAT16
      Total_Sectors_in_FS :   Unsigned_16;        -- 19-20 :  2880 when not FAT32 and < 32MB
      Media_Descriptor :      Unsigned_8;         -- 21 :     F0 = 1.44MB floppy, F8 = HD
      Sectors_Per_FAT :       Unsigned_16;        -- 22-23 :  9, FAT32 = 0
      Sectors_Per_Track :     Unsigned_16;        -- 24-25 :  12
      No_Of_Heads :           Unsigned_16;        -- 26-27 :  2 for double sided diskette
      Hidden_Sectors_32 :     Unsigned_32;        -- 28-31 :  FAT32
      Total_Sectors_32 :      Unsigned_32;        -- 32-35 :  FAT32
      Sectors_Per_FAT_32 :    Unsigned_32;        -- 36-39 :  FAT32
      Mirror_Flags :          Unsigned_16;        -- 40-41 :  FAT32
      FS_Version_Major :      Unsigned_8;         -- 42-42 :  FAT32
      FS_Version_Minor :      Unsigned_8;         -- 43-43 :  FAT32
      Root_Dir_First_Cluster: Unsigned_32;        -- 44-47 :  FAT32
      FS_Info_Sector :        Unsigned_16;        -- 48-49 :  FAT32
      Backup_Boot_Sector :    Unsigned_16;        -- 50-51 :  FAT32
      Reserved :              Bytes(52..63);      -- 52-63 :  FAT32
      Bootstrap_Code :        Bytes(64..509);
      Signature :             Bytes(0..1);        -- 510-511: 55 AA
   end record;
   
   for Boot_Sector_Type'Alignment use 4;
   
   ------------------------------------------------------------------
   -- DIRECTORY ENTRY
   ------------------------------------------------------------------
   
   type Dir_Entry_Type is record
      Filename :      String(1..8);
      Extension :     String(1..3);
      Reserved_7 :    Boolean;
      Reserved_6 :    Boolean;
      Archive :       Boolean;
      Subdirectory :  Boolean;
      Volume_Name :   Boolean;
      System_File :   Boolean;
      Hidden_File :   Boolean;
      Read_Only :     Boolean;
      Reserved :      String(1..8);
      Cluster_High :  Unsigned_16;        -- FAT32 only
      Hour :          Hour_Type;
      Minute :        Minute_Type;
      Second2 :       Seconds2_Type;
      Year :          Year_Type;
      Month :         Month_Type;
      Day :           Day_Type;
      First_Cluster : Unsigned_16;
      File_Size :     Unsigned_32;
   end record;
   
   ------------------------------------------------------------------
   -- FILE SYSTEM DATE / TIME
   ------------------------------------------------------------------
   
   type FS_Time_Type is record
      Year :          Year_Type;
      Month :         Month_Type;
      Day :           Day_Type;
      Hour :          Hour_Type;
      Minute :        Minute_Type;
      Second2 :       Seconds2_Type;
   end record;
   
   ------------------------------------------------------------------
   -- FILE SYSTEM API
   ------------------------------------------------------------------
   
   procedure Open_FS(OK : out Boolean);
   procedure Read_Boot_Sector(Boot_Sector : out Boot_Sector_Type; OK : out Boolean);
   function File_System return FS_Type;
   function OEM_Name return String;
   function Volume return String;
   procedure Close_FS;
   
   procedure Set_FS_Time(Time : FS_Time_Type);
   procedure Get_FS_Time(Time : out FS_Time_Type);
   
   -------------------------------------------------------------------
   -- FILE SYSTEM INFO ROUTINES (FOR TESTING)
   -------------------------------------------------------------------

   function FS_Root_Entries return Unsigned_16;
   function FS_Sectors_Per_Cluster return Unsigned_16;
   function FS_Clusters return Unsigned_32;

   ------------------------------------------------------------------
   -- FILE/DIRECTORY NAMES
   ------------------------------------------------------------------
   
   function Is_Separator(Ch : Character) return Boolean;
   function Filename_Index(Pathname : String) return Natural;
   procedure Parse_Filename(Base, Ext : out String; Name : String; OK : out Boolean);
   
   ------------------------------------------------------------------
   -- DIRECTORY API
   ------------------------------------------------------------------
   
   procedure Open_Dir(Dir : out DCB_Type; OK : out Boolean);
   procedure Open_Dir(Dir : out DCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean);
   procedure Open_Dir(Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Open_Path(Dir : out DCB_Type; Pathname : String; OK : out Boolean);
   procedure Search_Dir(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; Name : String; OK : out Boolean);
   procedure Get_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean);
   procedure Next_Dir_Entry(Dir : in out DCB_Type; Dir_Entry : out Dir_Entry_Type; OK : out Boolean);
   procedure Rewind_Dir(Dir : in out DCB_Type);
   procedure Close_Dir(Dir : in out DCB_Type);
   
   function Filename(Dir_Entry : Dir_Entry_Type) return String;
   
   procedure Create_Subdir(Dir : in out DCB_Type; Subdir : String; OK : out Boolean);
   procedure Create_Path(Dir : out DCB_Type; Pathname : String; OK : out Boolean);
   procedure Delete_Subdir(Dir : in out DCB_Type; Subdir : String; OK : out Boolean);
   procedure Rename(Dir : in out DCB_Type; Old_Name, New_Name : String; OK : out Boolean);
   procedure Update_Attributes(Dir : in out DCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean);
   
   ------------------------------------------------------------------
   -- USER SUPPLIED FILE SYSTEM SECTOR I/O ROUTINES
   ------------------------------------------------------------------
   
   type Read_Proc is access
      procedure(Sector : Sector_Type; Block : out Block_512; OK : out Boolean);
   
   type Write_Proc is access
      procedure(Sector : Sector_Type; Block : Block_512; OK : out Boolean);
   
   ------------------------------------------------------------------
   -- FILE SYSTEM I/O
   ------------------------------------------------------------------
   
   procedure Register_Read_Proc(Read : Read_Proc);         -- Read one sector
   procedure Register_Write_Proc(Write : Write_Proc);      -- Write one sector
   
   ------------------------------------------------------------------
   -- FILE READ PHYSICAL API
   ------------------------------------------------------------------
   
   type FCB_Type is private;                       -- File control block
   
   procedure Open_File(File : out FCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean);
   procedure Open_File(File : out FCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Rewind_File(File : in out FCB_Type);
   procedure Read_File(File : in out FCB_Type; Block : out Block_512; Count : out Unsigned_16; OK : out Boolean);
   procedure Reread_File(File : in out FCB_Type; Block : out Block_512; Count : out Unsigned_16; OK : out Boolean);
   procedure Close_File(File : in out FCB_Type);
   
   ------------------------------------------------------------------
   -- TEXT FILE READ API
   ------------------------------------------------------------------
   
   type TFCB_Type is private;
   
   procedure Open_File(File : out TFCB_Type; Dir_Entry : Dir_Entry_Type; OK : out Boolean);
   procedure Open_File(File : out TFCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Rewind_File(File : in out TFCB_Type);
   procedure Read_Char(File : in out TFCB_Type; Char : out Character; OK : out Boolean);
   procedure Read_Line(File : in out TFCB_Type; Line : out String; Last : out Natural; OK : out Boolean);
   procedure Read(File : in out TFCB_Type; Buffer : out U8_Array; Count : out Unsigned_16; OK : out Boolean);
   procedure Read(File : in out TFCB_Type; Data : out Unsigned_8; OK : out Boolean);
   procedure Read(File : in out TFCB_Type; Data : out Unsigned_16; OK : out Boolean);
   procedure Read(File : in out TFCB_Type; Data : out Unsigned_32; OK : out Boolean);
   procedure Close_File(File : in out TFCB_Type);
   
   ------------------------------------------------------------------
   -- WRITE PHYSICAL FILE API
   ------------------------------------------------------------------
   
   type WCB_Type is limited private;               -- Writable file control block
   
   function Free_Space return Unsigned_32;         -- Return free space in bytes
   
   procedure Open_File(File : out WCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Create_File(File : out WCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Write_File(File : in out WCB_Type; Block : in out Block_512; Count : Unsigned_16; OK : out Boolean);
   procedure Rewrite_File(File : in out WCB_Type; Block : in out Block_512; Count : Unsigned_16; OK : out Boolean);
   procedure Sync_File(File : in out WCB_Type; OK : out Boolean);
   procedure Close_File(File : in out WCB_Type; OK : out Boolean);
   
   procedure Delete_File(Dir : in out DCB_Type; Name : String; OK : out Boolean);
   
   ------------------------------------------------------------------
   -- TEXT WRITE FILE API
   ------------------------------------------------------------------
   
   type TWCB_Type is limited private;
   
   procedure Open_File(File : out TWCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Create_File(File : out TWCB_Type; Dir : in out DCB_Type; Name : String; OK : out Boolean);
   procedure Put(File : in out TWCB_Type; Char : Character; OK : out Boolean);
   procedure Put(File : in out TWCB_Type; Text : String; OK : out Boolean);
   procedure Put_Line(File : in out TWCB_Type; Text : String; OK : out Boolean);
   procedure Write(File : in out TWCB_Type; Buffer : U8_Array; OK : out Boolean);
   procedure Write(File : in out TWCB_Type; Data : Unsigned_8; OK : out Boolean);
   procedure Write(File : in out TWCB_Type; Data : Unsigned_16; OK : out Boolean);
   procedure Write(File : in out TWCB_Type; Data : Unsigned_32; OK : out Boolean);
   procedure New_Line(File : in out TWCB_Type; OK : out Boolean);
   procedure Sync_File(File : in out TWCB_Type; OK : out Boolean);
   procedure Close_File(File : in out TWCB_Type; OK : out Boolean);
   
   ------------------------------------------------------------------
   -- FILE SYSTEM FORMATTING
   ------------------------------------------------------------------
   
   procedure Format(
      Total_Sectors :         in      Sector_Type;            -- Device # of sectors
      Sectors_Per_Cluster :   in      Unsigned_8;             -- Sectors per cluster
      OK :                       out  Boolean;                -- Result of format
      Root_Dir_Entries_16 :   in      Unsigned_16 := 512;     -- FAT16 Directory entries
      OEM_Name :              in      String := "FATFS";      -- OEM Name to use
      No_Of_FATs :            in      FAT_Copies_Type := 1;   -- # of FATs (4 max)
      Reserved_Sectors :      in      Unsigned_16 := 1        -- Reserved sectors, including boot sector
   );
   
private
   
   ------------------------------------------------------------------
   -- I/O CONTEXT
   ------------------------------------------------------------------
   
   type IO_Context_Type is record
      Read :          Read_Proc;              -- Read I/O procedure
      Write :         Write_Proc;             -- Write I/O procedure
   end record;
   
   ------------------------------------------------------------------
   -- CLUSTER CONTROL BLOCK
   ------------------------------------------------------------------
   
   type CCB_Type is record
      Start_Sector :  Sector_Type;            -- Rewind to here
      Prev_Sector :   Sector_Type;            -- Last sector read/written (else 0)
      First_Cluster : Cluster_Type;           -- or Rewind to this Cluster if >= 2
      Cur_Sector :    Sector_Type;            -- Current sector position
      Sector_Count :  Unsigned_16;            -- How many sectors until end of cluster
      Cluster :       Cluster_Type;           -- Current cluster or zero if no more
      IO_Bytes :      Unsigned_32;            -- Bytes read or written
   end record;
   
   ------------------------------------------------------------------
   -- DIRECTORY CONTROL BLOCK
   ------------------------------------------------------------------
   
   type DCB_Type is record
      CCB :               CCB_Type;           -- Cluster control block
      Cur_Index :         Unsigned_16;        -- Directory entry index
      Dir_Entries :       Unsigned_16;        -- How many dir entries in this block
      Magic :             Unsigned_8;         -- Must be Magic_Dir to be valid
   end record;
   
   type Dir_Entry_Array is array(Unsigned_16 range <>) of Dir_Entry_Type;
   for Dir_Entry_Array'Component_Size use 32 * 8;
   
   ------------------------------------------------------------------
   -- DIRECTORY ENTRY REPRESENTATION
   ------------------------------------------------------------------
   
   for Dir_Entry_Type use record
      Filename        at 0    range 0..63;
      Extension       at 8    range 0..23;
      Reserved_7      at 11   range 7..7;
      Reserved_6      at 11   range 6..6;
      Archive         at 11   range 5..5;
      Subdirectory    at 11   range 4..4;
      Volume_Name     at 11   range 3..3;
      System_File     at 11   range 2..2;
      Hidden_File     at 11   range 1..1;
      Read_Only       at 11   range 0..0;
      Reserved        at 12   range 0..63;
      Cluster_High    at 20   range 0..15;
      Hour            at 22   range 11..15;
      Minute          at 22   range 5..10;
      Second2         at 22   range 0..4;
      Year            at 24   range 9..15;
      Month           at 24   range 5..8;
      Day             at 24   range 0..4;
      First_Cluster   at 26   range 0..15;
      File_Size       at 28   range 0..31;
   end record;
   
   for Dir_Entry_Type'Size use 32 * 8;
   pragma Pack(Boot_Sector_Type);
      
   ------------------------------------------------------------------
   -- FILE CONTROL BLOCK (FOR PHYSICAL READS)
   ------------------------------------------------------------------
   
   type FCB_Type is record
      CCB :          CCB_Type;               -- Cluster control block
      File_Size :    Unsigned_32;            -- File's size in bytes
      Magic :        Unsigned_8;             -- Must be Magic_File to be valid
   end record;
   
   ------------------------------------------------------------------
   -- TEXT FILE CONTROL BLOCK (TEXT READS)
   ------------------------------------------------------------------
   
   type TFCB_Type is record
      FCB :           FATFS.FCB_Type;         -- Underlying physical interface
      Byte_Offset :   Unsigned_16;            -- Offset within the current sector
   end record;
   
   ------------------------------------------------------------------
   -- PHYSICAL WRITE CONTROL BLOCK
   ------------------------------------------------------------------
   
   type WCB_Type is limited record
      CCB :           CCB_Type;               -- Cluster control block
      Dir_Sector :    Sector_Type;            -- Sector containing dir entry
      Dir_Index :     Unsigned_16;            -- Directory entry index (to update later)
      Last_Sector :   Unsigned_16;            -- Last Write/Rewrite count, for Close_File
      Magic :         Unsigned_8;             -- Magic_WCB
   end record;
   
   ------------------------------------------------------------------
   -- TEXT WRITE CONTROL BLOCK
   ------------------------------------------------------------------
   
   type TWCB_Type is limited record
      WCB :           WCB_Type;               -- Underlying physcial file
      Byte_Offset :   Unsigned_16;            -- Byte offset, within current sector
   end record;
   

   pragma Inline(Register_Read_Proc);
   pragma Inline(Register_Write_Proc);
   
   pragma Inline(Set_FS_Time);
   pragma Inline(Get_FS_Time);
   
   pragma Inline(File_System);
   pragma Inline(OEM_Name);
   pragma Inline(Volume);

end FATFS;
   
----------------------------------------------------------------------
-- IMPLEMENTATION NOTES
----------------------------------------------------------------------
-- 
-- This is _not_ an efficient implementation since it is targeted
-- at small RAM footprint architectures.  It is designed to
-- operate with as little as 1K of RAM (targeted for ATmega168).
-- This allows the use of _one_ sector buffer of size 512 bytes,
-- leaving 512 bytes for stack and other program variables.
-- 
-- To successfully operate with one buffer, the application
-- programmer should only create a sector buffer when  required
-- by use of a declare block:
-- 
--    declare
--       Buffer : Block_512;  -- Sector buffer
--    begin
--       ...operation...
--    end;
-- 
-- Sometimes the called operation requires sector buffers, so it
-- too will create them only when required. Write routines will
-- first write your buffer, then use it internally, and finish by
-- restoring the application content to it, prior to returning.
-- In this way, all FAT operations are handled with a maximum of
-- one 512 byte sector buffer (Block_512).
-- 
-- Architectures containing more abundant RAM, need not be
-- concerned about this.

----------------------------------------------------------------------
-- MEDIA DESCRIPTOR BYTE
----------------------------------------------------------------------
-- For 8" floppies:
-- FC, FD, FE - Various interesting formats
-- 
-- For 5.25" floppies:
-- Value  DOS version  Capacity  sides  tracks  sectors/track
-- FF     1.1           320 KB    2      40      8
-- FE     1.0           160 KB    1      40      8
-- FD     2.0           360 KB    2      40      9
-- FC     2.0           180 KB    1      40      9
-- FB                   640 KB    2      80      8
-- FA                   320 KB    1      80      8
-- F9     3.0          1200 KB    2      80     15
-- 
-- For 3.5" floppies:
-- Value  DOS version  Capacity  sides  tracks  sectors/track
-- FB                   640 KB    2      80      8
-- FA                   320 KB    1      80      8
-- F9     3.2           720 KB    2      80      9
-- F0     3.3          1440 KB    2      80     18
-- F0                  2880 KB    2      80     36
-- 
-- For RAMdisks:
-- FA
-- 
-- For hard disks:
-- Value  DOS version
-- F8     2.0
-- 
-- This code is also found in the first byte of the FAT. 

----------------------------------------------------------------------
-- Cluster size
----------------------------------------------------------------------
-- The default number of sectors per cluster for floppies (with FAT12) is
--
-- Drive size Secs/cluster   Cluster size
-- 360 KB       2             1 KiB
-- 720 KB       2             1 KiB
-- 1.2 MB       1           512 bytes
-- 1.44 MB       1           512 bytes
-- 2.88 MB       2             1 KiB
-- 
-- The default number of sectors per cluster for fixed disks is (with FAT12 below 16 MB, FAT16 above):
-- 
-- Drive size Secs/cluster   Cluster size
-- <  16 MB       8             4 KiB
-- < 128 MB       4             2 KiB
-- < 256 MB       8             4 KiB
-- < 512 MB      16             8 KiB
-- <   1 GB      32            16 KiB
-- <   2 GB      64            32 KiB
-- <   4 GB     128            64 KiB   (Windows NT only)
-- <   8 GB     256           128 KiB   (Windows NT 4.0 only)
-- <  16 GB     512           256 KiB   (Windows NT 4.0 only)

-- * If NumberOfClusters<4087 then FAT12 is used.
-- * If 4087<=NumberOfClusters<65,527 then FAT16 is used.
-- * If 65,527<=NumberOfClusters<268,435,457 then FAT32 is used.
-- * Otherwise, none of the above is used.
