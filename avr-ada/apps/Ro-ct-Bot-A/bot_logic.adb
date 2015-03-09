--      High-Level Routinen fuer die Steuerung des c't-Bots.

-- Diese Datei sollte der Einstiegspunkt fuer eigene Experimente sein,
-- den Roboter zu steuern.

with Interfaces;                   use type Interfaces.Integer_16;

with AVR.Strings;                  use type AVR.Strings.AVR_String;

with Debug;

with Motor;                        use type Motor.Ext_Speed_T;
with Sensors;

with RC5;


package body Bot_Logic is


   BORDER_DANGEROUS : constant := 500;  --/< Wert, ab dem wir sicher sind, dass es eine Kante ist

   type Collision_Dist is range 0 .. 2000; -- ???

   COL_CLOSEST : constant :=  100; --/< Abstand in mm, den wir als zu nah betrachten
   COL_NEAR    : constant :=  200; --/< Nahbereich
   COL_FAR     : constant :=  400; --/< Fernbereich


   type Dist_Zone_T is (Closest,   --/< Zone fuer extremen Nahbereich
                        Near,      --/< Zone fuer Nahbereich
                        Far,       --/< Zone fuer Fernbereich
                        Clear);    --/< Zone fuer Freien Bereich


   subtype Scale_Factor is Float range -200.0 .. +200.0;

   function "*" (Left : Motor.Speed_T; Right : Scale_Factor) return Motor.Speed_T;
   pragma Inline ("*");


   subtype Brake_Factor is Scale_Factor range 0.0 .. 10.0;
   --  < 1 ==> bremsen,
   --  > 1 ==> rueckwaerts

   --  type Brake_Zone_T is (Closest, --/< Bremsfaktor fuer extremen Nahbereich
   --                        Near,    --/< Bremsfaktor fuer Nahbereich
   --                        Far);    --/< Bremsfaktor fuer Fernbereich


   type Zone_Brake_Map is array (Dist_Zone_T) of Brake_Factor;

   Zone_Brake_Factor : constant Zone_Brake_Map :=
     (Closest => 2.0,  --/< Bremsfaktor fuer extremen Nahbereich
      Near    => 0.6,  --/< Bremsfaktor fuer Nahbereich
      Far     => 0.2,  --/< Bremsfaktor fuer Fernbereich
      Clear   => 1.0);


   --
   --  globals for behaviour calculation
   --

   Speed_Wish_L   : Motor.Ext_Speed_T := Motor.BOT_SPEED_IGNORE;
   Speed_Wish_R   : Motor.Ext_Speed_T := Motor.BOT_SPEED_IGNORE;

   Factor_Wish_L  : Scale_Factor      := 1.0;
   Factor_Wish_R  : Scale_Factor      := 1.0;

   --/< Kollisionszone, in der sich der linke, bzw. rechte Sensor befindet
   Col_Zone_L     : Dist_Zone_T := Clear;
   Col_Zone_R     : Dist_Zone_T := Clear;


   --
   --  types and globals for the GOTO system
   --

   subtype Motor_Step_T is Interfaces.Integer_16;

   -- MOT_GOTO_MAX : constant :=  3;  --/< Richtungsaenderungen, bis goto erreicht sein muss

--     Mot_L_Goto : Motor_Step_T := 0;    --/< Speichert, wie weit der linke Motor drehen soll
--     Mot_R_Goto : Motor_Step_T := 0;    --/< Speichert, wie weit der rechte Motor drehen soll
--     pragma Volatile (Mot_L_Goto);
--     pragma Volatile (Mot_R_Goto);

--     Mot_Goto_L : Integer_16 := 0;    --/< Muss der linke Motor noch drehen?
--     Mot_Goto_R : Integer_16 := 0;    --/< Muss der rechte Motor noch drehen?
--     pragma Volatile (Mot_Goto_L);
--     pragma Volatile (Mot_Goto_R);


   --
   --  Behaviour_T is used for organizing the combination of different
   --  behaviour routines.
   --
   type Behaviour_T;

   type Behaviour_Proc is access procedure (Data : in out Behaviour_T);

   type Priority_T is range 0 .. 255;
   for Priority_T'Size use 8;

   type Behaviour_T is record
      Work     : Behaviour_Proc;
      Priority : Priority_T := 0;
      Active   : Boolean    := True;
   end record;

   Null_Behaviour : constant Behaviour_T :=
     (Work => null, Priority => 0, Active => False);

   --
   --  using std Ada arrays does not allow dynamic change of behaviour
   --  order.
   --
   subtype Behaviour_Index is Interfaces.Integer_8 range 1 .. Interfaces.Integer_8'Last;

   type Behaviour_Array is array (Behaviour_Index range <>) of Behaviour_T;


   --
   --  behaviour routines
   --
   procedure Bot_Base        (Data : in out Behaviour_T);
   procedure Bot_Simple      (Data : in out Behaviour_T);
   -- procedure Bot_Goto_System (Data : in out Behaviour_T);
   -- procedure Bot_Avoid_Border(Data : in out Behaviour_T);
   -- procedure Bot_Avoid_Col   (Data : in out Behaviour_T);

   function Image (Data : Behaviour_T) return AVR.Strings.AVR_String;

   --
   --  The prioritized list of behaviour routines, important routines
   --  first.  We write the list as a constant array, therefor we cannot
   --  automatically arange the priorities.  It is the programmer's
   --  responsibility to keep them in order.  Highest priority first!
   --
   My_Behaviour : Behaviour_Array :=
     ((Priority => 210, Work => Bot_Simple'Access, Active => True),
      -- New_Behaviour (200, Bot_Avoid_Border'Access),
      -- New_Behaviour (100, Bot_Avoid_Col'Access),
      -- New_Behaviour ( 50, Bot_Goto_System'Access),
      (Priority =>   0, Work => Bot_Base'Access, Active => True));



   -- initialisiere das Verhalten
   procedure Init is
   begin
      null;
      --  everything done at compile time in the static array
   end Init;


   procedure Bot_Base (Data : in out Behaviour_T) is
      pragma Unreferenced (Data);
   begin
      Speed_Wish_L := Target_Speed_L;
      Speed_Wish_R := Target_Speed_R;
   end Bot_Base;


   procedure Bot_Simple (Data : in out Behaviour_T)
   is
      Speed_L_Col : Motor.Speed_T;
      Speed_R_Col : Motor.Speed_T;
   begin
      Speed_Wish_L := Motor.BOT_SPEED_MAX;
      Speed_Wish_R := Motor.BOT_SPEED_MAX;

      if Sensors.Dist_L < COL_NEAR then
         Speed_R_Col := - Motor.Speed_R - Motor.BOT_SPEED_NORMAL;
      else
         Speed_R_Col := 0;
      end if;

      if Sensors.Dist_R < COL_NEAR then
         Speed_L_Col := - Motor.Speed_L - Motor.BOT_SPEED_NORMAL;
      else
         Speed_L_Col := 0;
      end if;

      Speed_Wish_L := Speed_Wish_L + Speed_L_Col;
      Speed_Wish_R := Speed_Wish_R + Speed_R_Col;
   end Bot_Simple;


   --!
   -- Drehe die Raeder um die gegebene Zahl an Encoder-Schritten weiter
   -- @param left Schritte links
   -- @param right Schritte rechts
   --/
--     procedure Bot_Goto (Steps_Left  : Motor_Step_T;
--                         Steps_Right : Motor_Step_T)
--     is
--     begin
--        -- Zielwerte speichern
--        Mot_L_Goto := Steps_Left;
--        Mot_R_Goto := Steps_Right;

--        -- Encoder zuruecksetzen
--        Sensors.Enc_L := 0;
--        Sensors.Enc_R := 0;

--        -- Goto-System aktivieren
--        if Steps_Left /= 0 then
--           Mot_Goto_L := MOT_GOTO_MAX;
--        else
--           Mot_Goto_L := 0;
--        end if;

--        if Steps_Right /= 0 then
--           Mot_Goto_R := MOT_GOTO_MAX;
--        else
--           Mot_Goto_R := 0;
--        end if;

--     end Bot_Goto;


   --!
   -- Kuemmert sich intern um die Ausfuehrung der goto-Kommandos,
   -- veraendert target_speed_l und target_speed_r
   -- @see bot_goto()
   --/
--     procedure Bot_Goto_System (Data : in out Behaviour_T)
--     is
--        Diff_L : Integer_16 := Sensors.Enc_L - Mot_L_Goto; -- Restdistanz links
--        Diff_R : Integer_16 := Sensors.Enc_R - Mot_R_Goto; -- Restdistanz rechts
--     begin

--        -- Motor L hat noch keine MOT_GOTO_MAX Nulldurchgaenge gehabt
--        if Mot_Goto_L > 0 then
--           if abs (Diff_L) <= 2 then   -- 2 Encoderstaende Genauigkeit reicht
--              Speed_Wish_L := Motor.BOT_SPEED_STOP;        --  Stop
--              Mot_Goto_L := Mot_Goto_L - 1;           -- wie Nulldurchgang behandeln
--           elsif (abs(Diff_L) < 4) then
--              Speed_Wish_L := Motor.BOT_SPEED_SLOW;
--           elsif (abs(Diff_L) < 10) then
--              Speed_Wish_L := Motor.BOT_SPEED_NORMAL;
--           elsif (abs(Diff_L) < 40) then
--              Speed_Wish_L := Motor.BOT_SPEED_FAST;
--           else
--              Speed_Wish_L := Motor.BOT_SPEED_MAX;
--           end if;

--           -- Richtung
--           if Diff_L > 0 then         -- Wenn uebersteuert,
--              Speed_Wish_L := -Speed_Wish_L;        -- Richtung umkehren
--           end if;


--           -- Wenn neue Richtung ungleich alter Richtung
--           if (Speed_Wish_L < 0 and then Motor.Speed_L > 0)
--             or else
--              (Speed_Wish_L > 0 and then Motor.Speed_L < 0)
--           then
--              Mot_Goto_L := Mot_Goto_L - 1;      -- Nulldurchgang merken
--           end if;
--        end if;


--        -- Motor R hat noch keine MOT_GOTO_MAX Nulldurchgaenge gehabt
--        if Mot_Goto_R > 0 then
--           if abs (Diff_R) <= 2 then         -- 2 Encoderstaende Genauigkeit reicht
--              Speed_Wish_R := Motor.BOT_SPEED_STOP;      --Stop
--              Mot_Goto_R := Mot_Goto_R - 1;  -- wie Nulldurchgang behandeln
--           elsif (abs(Diff_R) < 4) then
--              Speed_Wish_R := Motor.BOT_SPEED_SLOW;
--           elsif (abs(Diff_R) < 10) then
--              Speed_Wish_R := Motor.BOT_SPEED_NORMAL;
--           elsif (abs(Diff_R) < 40) then
--              Speed_Wish_R := Motor.BOT_SPEED_FAST;
--           else
--              Speed_Wish_R := Motor.BOT_SPEED_MAX;
--           end if;


--           -- Richtung
--           if Diff_R > 0 then         -- Wenn uebersteurt,
--              Target_Speed_R := - Target_Speed_R; --  Richtung umkehren
--           end if;

--           -- Wenn neue Richtung ungleich alter Richtung
--           if (Speed_Wish_R < 0 and then Motor.Speed_R > 0)
--             or else
--               (Speed_Wish_R > 0 and then Motor.Speed_R < 0)
--           then
--              Mot_Goto_R := Mot_Goto_R - 1;           -- Nulldurchgang merken
--           end if;

--        end if;

--     end Bot_Goto_System;



   --!
   --  TODO: Diese Funktion ist nur ein Dummy-Beispiel, wie eine
   --  Kollisionsvermeidung aussehen koennte.  Hier ist ein guter
   --  Einstiegspunkt fuer eigene Experimente und Algorithmen!  Passt
   --  auf, dass keine Kollision mit Hindernissen an der Front des
   --  Roboters geschieht.
   --/
   procedure Bot_Avoid_Col (Data : in out Behaviour_T)
   is

      procedure Determine_Dist_Zone (Dist : in Sensors.IR_Distance_T;
                                     Zone : in out Dist_Zone_T);

      procedure Determine_Dist_Zone (Dist : in Sensors.IR_Distance_T;
                                     Zone : in out Dist_Zone_T)
      is
      begin
         if Dist < COL_CLOSEST then   -- sehr nah
            Zone := Closest;          -- dann auf jeden Fall CLOSEST Zone
         elsif Dist < COL_NEAR and then Zone > Closest then
            -- sind wir naeher als NEAR und nicht in der inneren Zone gewesen
            Zone := NEAR;             -- dann auf in die NEAR-Zone
         elsif Dist < COL_FAR and then Col_Zone_R > Near then
            -- sind wir naeher als FAR und nicht in der NEAR-Zone gewesen
            Zone := Far;              -- dann auf in die FAR-Zone
         elsif Dist * 2 < COL_NEAR then
            -- wir waren in einer engeren Zone und verlassen sie in Richtung NEAR
            Zone := NEAR;             -- dann auf in die NEAR-Zone
         elsif Dist * 2 < COL_FAR then
            Zone := FAR;              -- dann auf in die FAR-Zone
         else
            Zone := CLEAR;            -- dann auf in die CLEAR-Zone
         end if;
      end Determine_Dist_Zone;

   begin

      Determine_Dist_Zone (Sensors.Dist_R, Col_Zone_R);
      Determine_Dist_Zone (Sensors.Dist_L, Col_Zone_L);

      --  set the brake factor of the opposite side
      Factor_Wish_R := Zone_Brake_Factor (Col_Zone_L);
      Factor_Wish_L := Zone_Brake_Factor (Col_Zone_R);

      --  if (sensDistR < COL_CLOSEST)                       --  sehr nah
      --     speed_l_col=-target_speed_l-BOT_SPEED_NORMAL;   --  rueckwaerts fahren
      --  elsif (sensDistR < COL_NEAR)                       --  nah
      --     speed_l_col=-target_speed_l * 0.9;              --  langsamer werden
      --  elsif (sensDistR < COL_FAR)                        --  fern
      --     speed_l_col=-target_speed_r * 0.65;             --  langsamer werden
      --  else
      --     speed_l_col=0;                                  --  nichts tun

      --  if (sensDistL < COL_CLOSEST)                       --  sehr nah
      --     speed_r_col=-target_speed_r-BOT_SPEED_NORMAL;   --  rueckwaerts fahren
      --  elsif (sensDistL < COL_NEAR)                       --  nah
      --     speed_r_col=-target_speed_r  * 0.9;
      --  elsif (sensDistL < COL_FAR)                        --  fern
      --     speed_r_col=-target_speed_r  * 0.65;
      --  else
      --     speed_r_col=0;

      -- if we are very close in both sensors, let's turn
--        if Col_Zone_R = CLOSEST and then Col_Zone_L = CLOSEST then
--           Speed_L_Col := -Target_Speed_L + Motor.BOT_SPEED_MAX;
--           Speed_R_Col := -Target_Speed_R - Motor.BOT_SPEED_MAX;
--        end if;

   end Bot_Avoid_Col;


   --!
   -- Verhindert, dass der Bot in Graeben faellt
   --/
   procedure Bot_Avoid_Border (Data : in out Behaviour_T)
   is
   begin
      if Sensors.Border_L > BORDER_DANGEROUS then
         Speed_Wish_L := - Motor.BOT_SPEED_NORMAL;
      end if;

      if Sensors.Border_R > BORDER_DANGEROUS then
         Speed_Wish_R := - Motor.BOT_SPEED_NORMAL;
      end if;
   end Bot_Avoid_Border;


   --!
   -- Zentrale Verhaltens-Routine,
   -- wird regelmaessig aufgerufen.
   -- Dies ist der richtige Platz fuer eigene Routinen,
   -- um den Bot zu steuern
   --/
   procedure Bot_Behave is
      Global_Factor_L : Scale_Factor      := 1.0;
      Global_Factor_R : Scale_Factor      := 1.0;
      Global_Speed_L  : Motor.Ext_Speed_T;
      Global_Speed_R  : Motor.Ext_Speed_T;

   begin
      --  accept commands from the infrared remote control
      RC5.Control;


      Behaviour_Loop:
      for J in My_Behaviour'Range loop
         declare
            Job : Behaviour_T renames My_Behaviour (J);
         begin

            Debug.New_Line;
            Debug.Put_Line (Image (Job));

            if Job.Active then
               Speed_Wish_L := Motor.Bot_Speed_Ignore;
               Speed_Wish_R := Motor.Bot_Speed_Ignore;

               Job.Work (Job);

               Global_Factor_L := Global_Factor_L * Factor_Wish_L;
               Global_Factor_R := Global_Factor_R * Factor_Wish_R;

               if Speed_Wish_L /= Motor.Bot_Speed_Ignore
                 or else
                 Speed_Wish_R /= Motor.Bot_Speed_Ignore
               then
                  Global_Speed_L := Speed_Wish_L * Global_Factor_L;
                  Global_Speed_R := Speed_Wish_R * Global_Factor_R;


                  Debug.New_Line;
                  Debug.Put ("Motor set left:");
                  Debug.Put (Global_Speed_L);
                  Debug.Put (", right:");
                  Debug.Put (Global_Speed_R);
                  Debug.New_Line;

                  Motor.Set (Left  => Global_Speed_L,
                             Right => Global_Speed_R);

                  exit Behaviour_Loop;
               end if;

            end if;
         end;
      end loop Behaviour_Loop;

   end Bot_Behave;


   function "*" (Left : Motor.Speed_T; Right : Scale_Factor)
                return Motor.Speed_T
   is
   begin
      return Motor.Speed_T (Float (Left) * Float (Right));
   end "*";


   function Image (Data : Behaviour_T) return AVR.Strings.AVR_String
   is
   begin
      return AVR.Strings.AVR_String'("behaviour prio:")
        & AVR.Strings.AVR_String (Data.Priority'Img);
   end Image;

end Bot_Logic;
