with Interfaces;                   use Interfaces;
with AVR;                          use AVR;
with AVR.UART;

package body Family is

   procedure Image (This : Parent) is
   begin
      UART.Put ("Parent (Id:");
      UART.Put (This.Id);
      UART.Put (")");
      UART.New_Line;
   end Image;


   function Create (Id : Unsigned_8) return Parent
   is
      Result : Parent;
   begin
      Parent.Id := Id;
      return Result;
   end Create;


   procedure Image (This : Child) is
   begin
      UART.Put ("Child (Id:");
      UART.Put (This.Id);
      UART.Put (", Data: ");
      UART.Put (This.Data);
      UART.Put (")");
      UART.New_Line;
   end Image;

   function Create (Id : Unsigned_8) return Child
   is
      Result : Child;
   begin
      Child.Id := Id;
      Child.Data := 11;
      return Result;
   end Create;

end Family;
