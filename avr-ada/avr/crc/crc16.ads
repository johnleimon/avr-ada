-- crc16.ads - Tue Nov  9 16:03:01 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

with Interfaces;
use Interfaces;

package CRC16 is

    subtype CRC_Type is Unsigned_16;

    -- Initialize CRC-16

    procedure Init(CRC : out CRC_Type);

    -- Compute CRC-16 from Byte

    procedure Update(CRC : in out CRC_Type; Byte : Unsigned_8);

    -- Return High and Low byte of Computed CRC-16

    function CRC_High(CRC : CRC_Type) return Unsigned_8;
    function CRC_Low(CRC : CRC_Type) return Unsigned_8;

    -- Make a CRC-16 from Two Received CRC Bytes for Comparison

    function CRC_Make(High, Low : Unsigned_8) return CRC_Type;

private

    pragma Inline(Init);
    pragma Inline(CRC_High);
    pragma Inline(CRC_Low);
    pragma Inline(CRC_Make);

end CRC16;
