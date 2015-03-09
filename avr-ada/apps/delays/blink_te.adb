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


with Blink_TE_Pkg;                 use Blink_TE_Pkg;
with AVR.Real_Time.Timing_Events;  use AVR.Real_Time.Timing_Events;
with AVR.Real_Time.Timing_Events.Process;

procedure Blink_TE is

   E : aliased Timing_Event;

begin
   --  set up the timing event infrastructure
   Init;

   --  set the timing event handler
   Set_Handler (E'Access, 1.0, LED_Off_Handler'Access);

   --  call the Timing_Events.Process in the main loop
   loop
      AVR.Real_Time.Timing_Events.Process;
   end loop;
end Blink_TE;
