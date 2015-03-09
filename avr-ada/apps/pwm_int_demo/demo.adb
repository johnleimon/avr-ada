-------------------------------------------------------------------------------
--  "THE BEER-WARE LICENSE" (Revision 42):
--  <joerg@FreeBSD.ORG> wrote this file.  As long as you retain this notice you
--  can do whatever you want with this stuff. If we meet some day, and you
--  think this stuff is worth it, you can buy me a beer in return. Joerg Wunsch
-------------------------------------------------------------------------------
--
--    Simple AVR demonstration.  Controls a LED that can be directly
--    connected from OC1/OC1A to GND.  The brightness of the LED is
--    controlled with the PWM.  After each period of the PWM, the PWM
--    value is either incremented or decremented, that's all.
--
--    $Id: demo.adb 91 2003-11-30 23:06:13Z berndtrog $
--
with Demo_Ada;

procedure Demo is
begin
   Demo_Ada.IOinit;

   loop
      null;
      --  The main loop of the program does nothing.
      --  all the work is done by the interrupt routine!
      --  If this was a real product, we'd probably put a SLEEP instruction
      --  in this loop to conserve power.
   end loop;
end Demo;
