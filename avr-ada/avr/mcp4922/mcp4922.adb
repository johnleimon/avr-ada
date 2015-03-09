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
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.SPI;


package body MCP4922 is

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
     )
   is
      U16_Value :     Unsigned_16 := Unsigned_16 (Value);
      
      Byte_0 :        Unsigned_8;
      
      Byte_0_Bits :   Bits_In_Byte;
      for Byte_0_Bits'Address use Byte_0'Address;
      
      BV_AB :         Boolean renames Byte_0_Bits(7);     -- DAC_A or DAC_B
      BV_BUF :        Boolean renames Byte_0_Bits(6);     -- Buffered or Unbuffered
      BV_GA :         Boolean renames Byte_0_Bits(5);     -- 1X or 2X Gain
      BV_SHDN :       Boolean renames Byte_0_Bits(4);     -- /Shutdown or not
   begin
      
      if Buffer'Length < 2 then
         return;                 -- Error
      end if;
      
      Byte_0 := Unsigned_8 (Shift_Right(U16_Value, 8) and 16#0F#);
      
      case Unit is
         when DAC_A =>
            BV_AB := False;
         when DAC_B =>
            BV_AB := True;
      end case;
      
      case Buffering is
         when Buffered =>
            BV_BUF := True;
         when Unbuffered =>
            BV_BUF := False;
      end case;

      case Gain is
         when Gain_1X =>
            BV_GA := True;
         when Gain_2X =>
            BV_GA := False;
      end case;

      if Shutdown then
         BV_SHDN := False;
      else
         BV_SHDN := True;
      end if;

      Buffer(Buffer'First+0) := Byte_0;
      Buffer(Buffer'First+1) := Unsigned_8 (U16_Value and 16#FF# );

   end Format;

end MCP4922;
