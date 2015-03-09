-- Test Main Program for fatfs tests.
-- Warren Gay
--
-- This module fakes the I/O to a SD memory card 
-- or hard disk. It is implemented using Ada.Direct_IO.

with FAT_Tests;         use FAT_Tests;
with Ada.Text_IO;       use Ada.Text_IO;
with Interfaces;        use Interfaces;

procedure test_fatfs is
begin

   Put_Line("Starting FAT File System Tests:");
   New_Line;

   Put_Line("- - -   F A T 3 2   T E S T S   - - -");
   New_Line;

   FAT32_Suite(
      Sectors           => 16#FFFFF#,
      Sects_Per_Cluster => 1,
      FATs              => 1,
      Reserved          => 0);

   FAT32_Suite(
      Sectors           => 16#FFFFF#+2,
      Sects_Per_Cluster => 2,
      FATs              => 2,
      Reserved          => 1);

   FAT32_Suite(
      Sectors           => 16#FFFFF#+8,
      Sects_Per_Cluster => 4,
      FATs              => 4,
      Reserved          => 16);

   New_Line;
   Put_Line("- - -   F A T 1 6   T E S T S   - - -");
   New_Line;

   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 4,
      Root_Entries      => 512,
      FATs              => 1,
      Reserved          => 0);

   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 2,
      Root_Entries      => 512,
      FATs              => 2,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 1,
      Root_Entries      => 512,
      FATs              => 3,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 4,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 2,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 1,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 4,
      Root_Entries      => 512,
      FATs              => 1,
      Reserved          => 1);
      
   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 2,
      Root_Entries      => 512,
      FATs              => 1,
      Reserved          => 2);
      
   FAT16_Suite(
      Sectors           => 50000,
      Sects_Per_Cluster => 1,
      Root_Entries      => 512,
      FATs              => 1,
      Reserved          => 3);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 1,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 4,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 0);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 4,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 4);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 2,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 5);
      
   FAT16_Suite(
      Sectors           => 16#FFFF#,
      Sects_Per_Cluster => 1,
      Root_Entries      => 1024,
      FATs              => 1,
      Reserved          => 6);
      
   New_Line;
   Put_Line("End of all tests.");

end test_fatfs;
