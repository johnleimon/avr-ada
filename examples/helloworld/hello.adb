--
--  Copyright (c) 2015 John Leimon
--
--  Permission to use, copy, modify, and/or distribute this software for any purpose
--  with or without fee is hereby granted, provided that the above copyright notice and
--  this permission notice appear in all copies.
--
--  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD
--  TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN
--  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
--  CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
--  PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
--  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--
with AVR;      use AVR;
with AVR.MCU;
with AVR.Wait;

-- PROGRAMMING EXAMPLE:
--
-- Program an ATMega6450 using AVRDude (on Linux) with a DragonISP Programmer over USB:
--  # sudo avrdude -vv -c dragon_isp -Pusb -pm6450 -U flash:w:hello.hex:i

procedure Hello is
   LED : Boolean renames MCU.PORTA_Bits (0);

   procedure Wait_1s is new AVR.Wait.Generic_Wait_Usecs(Crystal_Hertz => 1_000_000,
                                                        Micro_Seconds => 1_000_000);
begin

   -- Set pin A0 to output --
   MCU.DDRA_Bits := (others => DD_Output);

   -- Blink an LED on and off once per second --
   loop
      LED := High;
      Wait_1s;
      LED := Low;
      Wait_1s;
   end loop;
end Hello;

