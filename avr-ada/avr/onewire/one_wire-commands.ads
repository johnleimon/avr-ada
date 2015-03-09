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


package One_Wire.Commands is
   pragma Preelaborate;


   --
   -- general ROM commands for all devices
   --

   -- directly read the 64bit ROM code of the single device on the bus
   Read_ROM            : constant Command_Code := 16#33#;

   --  The match ROM command followed by a 64-bit ROM code sequence
   --  allows the bus master to address a specific slave device on a
   --  multidrop or single-drop bus. Only the slave that exactly
   --  matches the 64-bit ROM code sequence will respond to the
   --  function command issued by the master; all other slaves on the
   --  bus will wait for a reset pulse.
   Match_ROM           : constant Command_Code := 16#55#;

   --  The master can use this command to address all devices on the
   --  bus simultaneously without sending out any ROM code information.
   Skip_ROM            : constant Command_Code := 16#CC#;

   --  search for devices
   Search_ROM          : constant Command_Code := 16#F0#;

   --  Skip_ROM and Match_ROM in overdrive mode
   Overdrive_Skip_ROM  : constant Command_Code := 16#3C#;
   Overdrive_Match_ROM : constant Command_Code := 16#69#;

   --  similar to Search_ROM, but only devices with set alarm flag
   --  will respond.
   Alarm_Search        : constant Command_Code := 16#EC#;


   --
   -- DS1820 commands
   --

   --  initiate temparature conversion
   Convert_T           : constant Command_Code := 16#44#;

   --  recalls T_H and T_L from EEPROM to the scratchpad.
   Recall_EEprom       : constant Command_Code := 16#B8#;

   --  signal power supply mode to the master.
   Read_Power_Supply   : constant Command_Code := 16#B4#;

   --  read the entire scratchpad including CRC byte.
   Read_Scratchpad     : constant Command_Code := 16#BE#;

   --  copy data from the scratchpad to the EEPROM.
   Copy_Scratchpad     : constant Command_Code := 16#48#;

   --  write data into scratchpad bytes 2 (T_H) and 3 (T_L)
   Write_Scratchpad    : constant Command_Code := 16#4E#;

end One_Wire.Commands;
