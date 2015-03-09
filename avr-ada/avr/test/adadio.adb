-- Support Harness for fatfs test program
-- Warren Gay
--
-- This module fakes the I/O to a SD memory card 
-- or hard disk. It is implemented using Ada.Direct_IO.

with Interfaces;
with Ada.Direct_IO;
with ADA.IO_Exceptions;

package body AdaDIO is

   package DIO is new Ada.Direct_IO(Block_512);

   File : DIO.File_Type;

   -------------------------------------------------------------------
   -- Convert Sector # to Direct_IO Record #
   -------------------------------------------------------------------
   
   function Block_No(Sector : Sector_Type) return DIO.Positive_Count is
   begin
       return DIO.Positive_Count(Sector + 1);
   end Block_No;


   -------------------------------------------------------------------
   -- Open the File System for Read, Read/Write and optionally Create
   -------------------------------------------------------------------
   procedure Open(Pathname : String; For_Write, Create : Boolean := False) is
      Need_Create : Boolean := False;
   begin

      if not For_Write then
         DIO.Open(File,DIO.In_File,Pathname);         -- Open existing file system image
      else
         begin
            DIO.Open(File,DIO.Inout_File,Pathname);   -- Open image for read/write
         exception
            when Ada.IO_Exceptions.Name_Error =>
               Need_Create := True;                   -- Image does not exist yet
         end;

         if Need_Create then
            if not Create then
               raise Ada.IO_Exceptions.Name_Error;          -- Raise an error (no image file to open)
            else
               DIO.Create(File,DIO.Inout_File,Pathname);    -- Create a new image file
            end if;
         end if;
       end if;

       Register_Read_Proc(Read'Access);         -- Tell file system about how to read a sector
       Register_Write_Proc(Write'Access);       -- Tell file system about how to write

   end Open;
    
   -------------------------------------------------------------------
   -- Close the File System Image
   -------------------------------------------------------------------

   procedure Close is
   begin

      DIO.Close(File);

   end Close;

   -------------------------------------------------------------------
   -- Read a sector from the file system
   -------------------------------------------------------------------

   procedure Read(Sector : Sector_Type; Block : out Block_512; OK : out Boolean) is
   begin

       DIO.Read(File,Block,Block_No(Sector));
       OK := True;

   end Read;

   -------------------------------------------------------------------
   -- Write a sector to the file system
   -------------------------------------------------------------------

   procedure Write(Sector : Sector_Type; Block : Block_512; OK : out Boolean) is
   begin

      DIO.Write(File,Block,Block_No(Sector));
      OK := True;

   end Write;

end AdaDIO;
