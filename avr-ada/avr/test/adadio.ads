-- Support Harness for fatfs test program
-- Warren Gay
--
-- This module fakes the I/O to a SD memory card 
-- or hard disk. It is implemented using Ada.Direct_IO.

with FATFS;
use FATFS;

package AdaDIO is

    procedure Open(Pathname : String; For_Write, Create : Boolean := False);
    procedure Read(Sector : Sector_Type; Block : out Block_512; OK : out Boolean);
    procedure Write(Sector : Sector_Type; Block : Block_512; OK : out Boolean);
    procedure Close;

end AdaDIO;
