-- midi.adb - Thu Aug 12 19:30:22 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: midi.adb,v 1.1 2010-08-25 01:09:15 Warren Gray Exp $
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

with Interfaces;                   use Interfaces;

package body MIDI is

   ------------------------------------------------------------------
   -- Initialize the MIDI Context
   ------------------------------------------------------------------
   procedure Initialize(
                        Context :       in out  IO_Context;
                        Receiver :      in      Read_Byte_Proc := null;
                        Transmitter :   in      Write_Byte_Proc := null;
                        Poll :          in      Poll_Byte_Proc := null
                       ) is
   begin

      Context.Receive_Byte    := Receiver;
      Context.Transmit_Byte   := Transmitter;
      Context.Poll_Byte       := Poll;

   end Initialize;


   ------------------------------------------------------------------
   -- Compute the MIDI Baud Rate Divisor for 31250 Baud
   ------------------------------------------------------------------
   function MIDI_Baud_Rate_Divisor(CPU_Clock_Freq : Unsigned_32) return Unsigned_16 is
   begin
      return Unsigned_16( Shift_Right(CPU_Clock_Freq,4) / 31250 ) - 1;
   end;

end MIDI;
