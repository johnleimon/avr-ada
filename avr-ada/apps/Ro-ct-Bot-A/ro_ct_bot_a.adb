
with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;

-- with AVR.Strings;

--  #ifdef MCU
--      with <avr/io.h>
--      with <avr/interrupt.h>
--      with <avr/signal.h>
--  #endif

--with AVR.Strings;
with Debug;

--  #ifdef PC
with Bot_2_Sim;
--  #endif

with Global;

with Sensors;
with RC5;

with LCD;
with LED;
with Motor;

with Bot_Logic;


procedure Ro_Ct_Bot_A is

   pragma Priority (10);


   Next       : Ada.Real_Time.Time;
   Period     : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (10);


   --
   --  Der Mikrocontroller und der PC-Simulator brauchen ein paar
   --  Einstellungen, bevor wir loslegen koennen.
   --
   procedure Init is
   begin
      --  #ifdef PC
      --   start a second thread for communication with the simulator
      Bot_2_Sim.Init;
      --  #else
      --        PORTA=0; DDRA=0;                --Alles Eingang alles Null
      --        PORTB=0; DDRB=0;
      --        PORTC=0; DDRC=0;
      --        PORTD=0; DDRD=0;
      --  #endif

      if Global.DISPLAY_AVAILABLE then
         LCD.Init;
      end if;

      if Global.LED_AVAILABLE then
         LED.Init;
      end if;

      Motor.Init;
      Sensors.Init;
      Bot_Logic.Init;


      RC5.Init;

      --  if Global.UART_AVAILABLE then
      --     UART.uart_init;
      --  end if;

      --  if MAUS_AVAILABLE then
      --     maus_sens_init;
      --  end if;

   end Init;


   -- Zeigt ein paar Informationen auf dem LCD an
   procedure Display is
      use LCD;
      use Sensors;
   begin
      Clear_Screen;
      GotoXY (1, 1);
      Put ("P="); Put (LDR_L); Put (' '); Put (LDR_R);
      Put (' ');
      Put ("D="); Put (Dist_L); Put (' '); Put (Dist_R);

      GotoXY (2,1);
      Put ("B="); Put (Border_L); Put (' '); Put (Border_R);
      Put (' ');
      Put ("L="); Put (Line_L); Put (' '); Put (Line_R);

      GotoXY (3,1);
      Put ("R="); Put (Enc_L); Put (' '); Put (Enc_R);
      Put (' ');
      Put ("F="); Put (Error);
      Put (' ');
      Put ("K="); Put_Std (Door'Img);
      Put (' ');
      Put ("T="); Put_Std (Trans'Img);

      GotoXY (4,1);
      Put ("I="); Put (RC5.Last_Received_Code);
      Put (' ');
      Put ("M="); Put (Mouse_DX); Put (' '); Put (Mouse_DY);
   end Display;


   --
   -- Hauptprogramm des Bots.
   --
begin  --  Ro_ct_Bot_A

   Debug.Put_Line ("Rolf's c't-Robot Ada (host client)");
   Init;

   delay 2.0;

   if Global.WELCOME_AVAILABLE then
      LCD.GotoXY (1, 1);
      LCD.Put ("Rolf's c't-Robot Ada");
      LED.Set (0);
   end if;

   Next := Ada.Real_Time.Clock + Period;
   -- Hauptschleife des Bot
   loop
      Debug.Put (Debug.Timestamp);
      Debug.Put_Line (": new loop");

      Sensors.Bot_Sens;

      Bot_Logic.Bot_Behave;

      Display;

      --#ifdef PC
      --  permit the communication task to exchange data with the simulator
      delay until Next;
      Next := Next + Period;
      --#endif

   end loop;

end Ro_Ct_Bot_A;
