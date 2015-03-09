with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;
with Net.Buffer;                   use Net.Buffer;

package Net.App_HTTP is

   type Http_State_Type is (Closed, Idle);
   type Http_Connection_State_Type is record
      State   : Http_State_Type;
      Timeout : Unsigned_8;
      Buffer  : Storage (1 .. 40);
      Name    : AStr16;
   end record;

   procedure Init;

   procedure Httpd;

end Net.App_HTTP;
