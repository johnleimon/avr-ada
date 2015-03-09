with AVR;                          use AVR;
with AVR.UART;
procedure Test_Local_Exception is
   Local : exception;
begin
   UART.Init (UART.Baud_19200_16MHz);
   UART.Put_Line ("test local exceptions");
   raise Local;
   UART.Put_Line ("after raise, unreachable");
exception
   when Local =>
      UART.Put_Line ("exception handled");
end Test_Local_Exception;
