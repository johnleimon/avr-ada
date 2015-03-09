with AVR;                          use AVR;
with AVR.MCU;
with AVR.UART;


procedure Main is
   C : Character;
begin

   -- OSCCAL_calibration;       -- calibrate the OSCCAL byte

   -- CLKPR := CLKPCE_Mask; -- set Clock Prescaler Change Enable

   -- set prescaler = 8, Inter RC 8Mhz / 8 = 1Mhz
   -- CLKPR := CLKPS1_Mask or CLKPS0_Mask; -- 1MHz
   -- CLKPR := 0; -- 8MHz

   -- 51 -->  1200Bd @ 1MHz
   -- 51 -->  4800Bd @ 4MHz
   -- 51 -->  9600Bd @ 8MHz
   -- 25 --> 19200Bd @ 8MHz
   -- 15 --> 31250Bd @ 8MHz
   -- 12 -->  4800Bd @ 1MHz
   -- 12 --> 19200Bd @ 4MHz

   AVR.UART.Init(51);            -- Baud rate = 9600bps, 1MHZ, u2x=1
   loop
      -- C := AVR.UART.Get;
      -- AVR.UART.Put (C);
      AVR.UART.Put_Line ("Hallo");
   end loop;

end Main;

