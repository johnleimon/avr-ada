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
with AVR;         use AVR;
with AVR.UART;
with AVR.Wait;
with AVR.Strings; use AVR.Strings;
with AVR.Int_Img; use AVR.Int_Img;
with Interfaces;  use Interfaces;

-- PROGRAMMING EXAMPLE:
--
-- Program an ATMega6450 using AVRDude (on Linux) with a DragonISP Programmer over USB:
--  # sudo avrdude -vv -c dragon_isp -Pusb -pm6450 -U flash:w:uart.hex:i

procedure UART is

   procedure Wait_1s is new AVR.Wait.Generic_Wait_Usecs(Crystal_Hertz => 1_000_000,
                                                        Micro_Seconds => 1_000_000);
   N           : Unsigned_8;
   Counter     : Unsigned_16 := 0;
   CounterText : AStr5;

begin
   AVR.UART.Init(AVR.UART.Baud_4800_1MHz);

   -- Start counting --
   loop
      U16_Img(Data   => Counter,
              Target => CounterText,
              Last   => N);
      AVR.UART.Put(CounterText);
      AVR.UART.Put("...");
      AVR.UART.CRLF;
      Wait_1s;
      Counter := Counter + 1;
   end loop;
end UART;
