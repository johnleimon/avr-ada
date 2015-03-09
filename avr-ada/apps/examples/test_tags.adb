with Family;                       use Family;
with AVR;                          use AVR;
with AVR.UART;

procedure Test_Tags is
   Mother : Family.Parent := Create (3);
   Son    : Family.Child  := Create (5);
begin
   UART.Init (UART.Baud_19200_16MHz);
   Mother.Image;
   Son.Image;
   declare
      Member_1 : Family.Parent'Class := Mother;
      Member_2 : Family.Parent'Class := Son;
   begin
      Member_1.Image;
      Member_2.Image;
   end;
end Test_Tags;
