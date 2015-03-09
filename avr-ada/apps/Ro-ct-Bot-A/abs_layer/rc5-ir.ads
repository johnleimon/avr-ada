--  low level InfraRed (IR) access for RC5
--  routines for decoding RC5 remote control codes

package RC5.IR is

   --  last completely read RC5 package
   Data : Unsigned_16;
   pragma Volatile (Data);


   procedure Init;

   function Read return Unsigned_16;


end RC5.IR;


