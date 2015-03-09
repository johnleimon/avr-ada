-- crc16.adb - Tue Nov  9 16:03:34 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

package body CRC16 is

   ------------------------------------------------------------------
   -- Initialize the CRC-16 Generator
   ------------------------------------------------------------------
   procedure Init(CRC : out CRC_Type) is
   begin
      CRC := 16#FFFF#;
   end;

   ------------------------------------------------------------------
   -- Update the Current CRC-16 with the Current Byte
   ------------------------------------------------------------------
   procedure Update(CRC : in out CRC_Type; Byte : Unsigned_8) is
   begin

      CRC := CRC xor Unsigned_16(Byte);

      for X in 1..8 loop
         if ( CRC and 16#0001# ) /= 0 then
            CRC := Shift_Right(CRC,1) xor 16#A001#;
         else
            CRC := Shift_Right(CRC,1);
         end if;
      end loop;

   end;

   ------------------------------------------------------------------
   -- Return the High Byte of the Computed CRC-16
   ------------------------------------------------------------------
   function CRC_High(CRC : CRC_Type) return Unsigned_8 is
   begin
      return Unsigned_8( Shift_Right(CRC,8) and 16#00FF# );
   end;

   ------------------------------------------------------------------
   -- Return the Low Byte of the Computed CRC-16
   ------------------------------------------------------------------
   function CRC_Low(CRC : CRC_Type) return Unsigned_8 is
   begin
      return Unsigned_8( CRC and 16#00FF# );
   end;

   ------------------------------------------------------------------
   -- Make a CRC-16 from Two Received CRC Bytes High and Low
   ------------------------------------------------------------------
   function CRC_Make(High, Low : Unsigned_8) return CRC_Type is
   begin
      return Shift_Left(Unsigned_16(High),8) or Unsigned_16(Low);
   end;

end CRC16;
