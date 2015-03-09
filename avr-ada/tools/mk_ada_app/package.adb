---------------------------------------------------------------------------
--  Put your copyright / version stuff here                              --
---------------------------------------------------------------------------

--  Uncomment the packages you need ..

--  Note that not all packages have been ported to all MCUs!

--  with System;                        --    use System;
--  with Ada.Unchecked_Conversion;      --    use Ada.Unchecked_Conversion;

--  with AVR.EEPROM;                    --    use AVR.EEPROM;
--  with AVR.Int_Img;                   --    use AVR.Int_img;
--  with AVR.Interrupts;                --    use AVR.Interrupts;
--  with AVR.IO;                        --    use AVR.IO;
--  with AVR.MCU;                       --    use AVR.MCU;
--  with AVR.Sleep;                     --    use AVR.Sleep;
--  with AVR.Strings;                   --    use AVR.Strings;
--  with AVR.UART;                      --    use AVR.UART;
--  with AVR.Wait;                      --    use AVR.Wait;
--  with AVR.Watchdog;                  --    use AVR.Watchdog;

--  with AVR; use AVR;

--  .. and delete the packages you don't need.

package body $package is
   --  put your library-level variables here
   procedure Init
   is
   begin
      --  put your init code here
      null;
   end;

   procedure Main
   is
      --  put your local variables here
   begin
      Init;  --  call procedure Init
      loop
         --  put your code here
         null;
      end loop;
   end;
end $package;
