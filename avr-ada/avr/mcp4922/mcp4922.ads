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
-- Written by Warren W, Gay VE3WWG
---------------------------------------------------------------------------
-- This package is for sending SPI data to the MCP4922 DAC Chip
--
-- Notes:
--
--  (1) Be sure to configure AVR.SPI to send in big-endian mode.
--  (2) The /Shutdown merely tri-states the selected Vout channel
--  (3) Buffer must be at least two bytes in length. The procedure
--      Format silently returns if the length is less. Larger buffers
--      are accepted, but only the first two bytes are estabilished.
---------------------------------------------------------------------------
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

package MCP4922 is

   type Unit_Type is
     (DAC_A,
      DAC_B
     );

   type Value_Type is range 0 .. 2**12-1;

   type Buffering_Type is
     (Buffered,                   -- Requires assertion of /LDAC pin
      Unbuffered                  -- /LDAC tied low
     );

   type Gain_Type is
     (Gain_1X,                    -- 1X (Vout = Vref * D/4096)
      Gain_2X                     -- 2X (Vout = 2 * Vref * D/4096)
     );

   ------------------------------------------------------------------
   -- Create a 2-byte message for the MCP4922 DAC
   ------------------------------------------------------------------
   procedure Format
     (Unit :      in      Unit_Type;                      -- DAC_A or DAC_B
      Value :     in      Value_Type;                     -- Value to xmit
      Buffer :       out  SPI_Data_Type;                  -- Buffer(1..2)
      Buffering : in      Buffering_Type := Unbuffered;   -- /LDAC control
      Gain :      in      Gain_Type := Gain_1X;           -- 1X or 2X Gain
      Shutdown :  in      Boolean := False                -- /Shutdown control
     );

end MCP4922;
