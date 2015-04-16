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

