-- slip.ads - Mon Aug  9 19:32:58 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: slip.ads,v 1.1 2010-08-21 01:19:44 Warren Gray Exp $
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

----------------------------------------------------------------------
-- 
-- This package provides a generalized SLIP interface for a
-- a communication link lacking "packet boundaries". While it
-- was designed primarily for asynchronous serial connections,
-- it has broader application. All you need is one Transmit
-- and Receive byte procedure for this SLIP interface to use.
-- 
-- To support a standard compliant SLIP interface, disable
-- the Compression and CRC-16 features.
-- 
-- The two non-standard optional features, which are set
-- by the Open(Context) call by default, are:
-- 
--  Compression - A simple 1-255 repeat of identical characters
--                using [ESC] [RPT] [Byte] [n] sequence, where
--                RPT = 8#336# (ESC = 8#333#).  This is not
--                a standard SLIP protocol control sequence.
-- 
--  CRC-16      - A CRC-16 value is appended to the packet,
--                and is checked upon receipt.  Note that when
--                this feature is used, your max packet length
--                is reduced by 2 bytes (254 bytes).
-- 
-- NOTES:
-- 
--  1 - Designed for small packets and packet buffers. Max
--      length of Packet_Type is 256 bytes.
-- 
--  2 - Transmission of binary data is supported (like normal
--      SLIP).
-- 
--  3 - When a receiving error is returned, you can use the
--      function Error_Reason to determine the cause (this
--      is useful for debugging).
--
--  4 - Normal design usually layers compression and CRC on
--      top of a simple layer (like SLIP). These features
--      where made available in this SLIP implementation,
--      to save on the limited AVR SRAM resource. This 
--      eliminates additional copies of packet buffers.
--
-- ERROR REASON CODES:
--
--  'T' - Packet truncated (garbled packet, or transmission length error)
--  'R' - Bad repeat count of zero, in compressed mode (garbled pkt)
--  'P' - Protocol error (unsupported control byte followed ESC byte).
--  'L' - Length error (length wasn't long enough for expected CRC-16 bytes)
--  'C' - CRC-16 did not match computed CRC (garbled data)
--
----------------------------------------------------------------------

with Interfaces;
use Interfaces;

package Slip is 

    ------------------------------------------------------------------
    -- SLIP Context Object
    ------------------------------------------------------------------

    type Slip_Context is private;

    ------------------------------------------------------------------
    -- Packet (Buffer) Type & I/O Procedures
    ------------------------------------------------------------------

    type Packet_Type is array(Unsigned_8 range <>) of Unsigned_8;
    for Packet_Type'Component_Size use 8;

    type Transmit_Proc is access    procedure(Byte : in  Unsigned_8);
    type Receive_Proc is access     procedure(Byte : out Unsigned_8);

    ------------------------------------------------------------------
    -- Open a SLIP Context
    ------------------------------------------------------------------

    procedure Open(Context : in out Slip_Context;
                   Receive : in     Receive_Proc;
                   Transmit : in    Transmit_Proc;
                   Compress : in    Boolean := True;
                   CRC16 :    in    Boolean := True);

    ------------------------------------------------------------------
    -- Transmit a SLIP Packet 
    ------------------------------------------------------------------

    procedure Transmit(Context : in out Slip_Context;   -- SLIP Context
                       Packet :  in     Packet_Type);   -- Packet to send

    ------------------------------------------------------------------
    -- Receive a SLIP Packet
    ------------------------------------------------------------------

    procedure Receive(Context : in out Slip_Context;    -- SLIP Context
                      Packet :     out Packet_Type;     -- Packet receiving buffer
                      Length :     out Unsigned_8;      -- Received packet length
                      Error :      out Boolean);        -- False, when received ok

    function Error_Reason(Context : Slip_Context) return Character;

private

    type Slip_Context is 
        record
            Recv :      Receive_Proc;       -- Procedure to receive one byte
            Xmit :      Transmit_Proc;      -- Procedure to transmit one byte
            Compress :  Boolean;            -- Compress data when True
            CRC16 :     Boolean;            -- Compute and include CRC16
            Reason :    Character;          -- Reason for receive error, if any
        end record;

    pragma Inline(Error_Reason);

end Slip;
