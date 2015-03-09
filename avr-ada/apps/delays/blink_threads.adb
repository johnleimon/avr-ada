---------------------------------------------------------------------------
-- The AVR-Ada Library is free software;  you can redistribute it and/or --
-- modify it under terms of the  GNU General Public License as published --
-- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
-- option) any later version.  The AVR-Ada Library is distributed in the --
-- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
-- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
-- PURPOSE. See the GNU General Public License for more details.         --
--                                                                       --
-- As a special exception, if other files instantiate generics from this --
-- unit,  or  you  link  this  unit  with  other  files  to  produce  an --
-- executable   this  unit  does  not  by  itself  cause  the  resulting --
-- executable to  be  covered by the  GNU General  Public License.  This --
-- exception does  not  however  invalidate  any  other reasons why  the --
-- executable file might be covered by the GNU Public License.           --
---------------------------------------------------------------------------


with Blink_Threads_Pkg;            use Blink_Threads_Pkg;
with AVR;                          use AVR;
with AVR.Timer2;
with AVR.Threads;
with LED;

procedure Blink_Threads is
begin
   LED.Init;

   Threads.Set_Timer (Timer2.Scale_By_256, 128);

   Threads.Start (Context_2, Blinky_2'Access);
   Threads.Start (Context_1, Blinky_1'Access);

   loop
      Threads.Yield;
   end loop;

end Blink_Threads;
