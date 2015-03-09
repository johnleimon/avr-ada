-- with AVR.ATmega169;

with AVR.Real_Time;                use AVR.Real_Time;
with AVR.Real_Time.Clock;
with AVR.Wait;
with AVR.Config;

use AVR;

procedure Atest_Clock is
   Start_T, End_T : Time;
   Delta_T        : Real_Time.Duration;

   procedure Wait_Ms is
      new Wait.Generic_Busy_Wait_Milliseconds (Config.Clock_Frequency);

begin
   Start_T := Clock;
   Wait_Ms (850);
   End_T   := Clock;
   Delta_T := End_T - Start_T;
end Atest_Clock;


