---------------------------------------------------------------------------
-- The AVR-Ada Library is free software;  you can redistribute it and/or --
-- modify it under terms of the  GNU General Public License as published --
-- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
-- option) any later version.  The AVR-Ada Library is distributed in the --
-- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
-- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
-- PURPOSE. See the GNU General Public License for more details.         --
--                                                                       --
-- As a special exception, if other files instantiate generics from this --
-- unit,  or  you  link  this  unit  with  other  files  to  produce  an --
-- executable   this  unit  does  not  by  itself  cause  the  resulting --
-- executable to  be  covered by the  GNU General  Public License.  This --
-- exception does  not  however  invalidate  any  other reasons why  the --
-- executable file might be covered by the GNU Public License.           --
---------------------------------------------------------------------------

--  This package provides the interface to monitoring and controlling
--  Dallas 1-Wire devices.  It serves as a 1-Wire bus master.

--  A detailed description of the protocol and the necessary timing is
--  available in the Dallas application note 126, "1-Wire communication
--  through software".

--  The Ada specification file does not depend on any particular hw
--  connection.  It assumes, however, a single 1-wire bus.  It cannot
--  control multiple parallel busses.
--
--  Implementations exist for AVR microcontrollers using a simple I/O
--  port and for Linux using the parallel printer port.

--  For space considerations I choose to provide the necessary port
--  number or wiring information in a separate child package
--  (e.g. One_Wire.AVR_Wiring) instead of subprogram parameters.


--  The transaction sequence for accessing the DS18S20 is as follows:
--
--  Step 1. Initialization
--  Step 2. ROM Command (followed by any required data exchange)
--  Step 3. DS18S20 Function Command (followed by any required data
--          exchange)
--
--  It is very important to follow this sequence every time the
--  DS18S20 is accessed, as the DS18S20 will not respond if any steps
--  in the sequence are missing or out of order.


with Interfaces;                   use Interfaces;

package One_Wire is
   pragma Preelaborate;


   procedure Init_Comm;
   --  On AVR, disable interrupts (which would disturb the exact
   --  timing and set any speed issues (e.g. modify system clock).  On
   --  PCs (Windows/Linux) open the port and initialize it.


   procedure Exit_Comm;
   --  reestablish old status of interrupts, etc.


   -- type Device_Status is (No_Device, Present, Short);
   -- for Device_Status'Size use 8;

   function Reset return Boolean;
   --  reset the bus and start a new communication.  It senses if
   --  devices are connected to the bus (returns True for at least one
   --  device present).


   type Command_Code is new Unsigned_8;
   --  the 1-wire command codes


   procedure Send_Command (Command : Command_Code);
   --  send a command to the 1-wire bus


   function Get return Unsigned_8;
   --  read a byte from the bus.

private

   --  make Touch available to children
   function Touch (Set : Unsigned_8) return Unsigned_8;


   -- needed by child package One_Wire.Search
   function Read_Write_Bit (Bit : Unsigned_8) return Unsigned_8;
   --  write a single bit to the bus, read if a 1 get written.  Only
   --  the bit that is selected through the wiring of the returned
   --  value is valid.  I.e. if AVR_Wiring.OW_Line = 4 then only bit
   --  number 4 contains the answer of the bus.

   procedure Set_Data_Line_High;
   --  set the data line to high voltage Vcc.  This is needed to
   --  provide power to temperature sensores in parasite mode during
   --  sampling.


   --  Send_Command and Get are actually only wrappers around Touch.
   --  Save the extra call and stack usage.
   pragma Inline (Send_Command);
   pragma Inline (Get);
   pragma Inline (Set_Data_Line_High);

end One_Wire;
