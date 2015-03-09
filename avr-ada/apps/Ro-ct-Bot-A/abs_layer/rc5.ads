with Interfaces;                   use Interfaces;

package RC5 is

   subtype RC5_Code is Unsigned_16;

   Last_Received_Code : RC5_Code;


   --
   -- read a RC5-Codeword and interprete it
   --
   procedure Control;


   procedure Init;

end RC5;
