--      RC5-Fernbedienung
-- Eventuell muessen die Codes an die jeweilige
-- Fernbedienung angepasst werden


with RC5.IR;
with RC5.Codes;                    use RC5.Codes;
with Motor;
with Bot_Logic;

package body RC5 is


   --!
   -- Liest ein RC5-Codeword und wertet es aus
   --/
   procedure Control is
      use Bot_Logic;  -- make Target_Speed_? directly visible
      Local_RC5 : constant Unsigned_16 := IR.Read;
   begin
      if Local_RC5 /= 0 then
         -- Alle uninteressanten Bits ausblenden
         Last_Received_Code := Local_RC5 and RC5_MASK;

         case Last_Received_Code is

         when RC5_CODE_PWR =>
            -- clear target Speed
            Target_Speed_L := Motor.BOT_SPEED_STOP;
            Target_Speed_R := Motor.BOT_SPEED_STOP;
            -- Clear goto system
            -- bot_goto(0,0);

         when RC5_CODE_UP =>
            --  accelerate
            Target_Speed_L := Target_Speed_L + 10;
            Target_Speed_R := Target_Speed_R + 10;

         when RC5_CODE_DOWN =>
            --  slow down
            Target_Speed_L := Target_Speed_L - 10;
            Target_Speed_R := Target_Speed_R - 10;

         when RC5_CODE_LEFT =>
            Target_Speed_L := Target_Speed_L - 10;

         when RC5_CODE_RIGHT =>
            Target_Speed_R := Target_Speed_R - 10;

         when RC5_CODE_1 =>
            Target_Speed_L := Motor.BOT_SPEED_SLOW;
            Target_Speed_R := Motor.BOT_SPEED_SLOW;

         when RC5_CODE_3 =>
            Target_Speed_L := Motor.BOT_SPEED_MAX;
            Target_Speed_R := Motor.BOT_SPEED_MAX;

      --         case RC5_CODE_5: bot_goto(0,0); break;
      --         case RC5_CODE_6: bot_goto(20,-20);      break;
      --         case RC5_CODE_4: bot_goto(-20,20);      break;
      --         case RC5_CODE_2: bot_goto(100,100);     break;
      --         case RC5_CODE_8: bot_goto(-100,-100);   break;
      --         case RC5_CODE_7: bot_goto(-40,40);      break;
      --         case RC5_CODE_9: bot_goto(40,-40);      break;

         when others =>
            if Jog_Dial then
               null;
      --             case RC5_CODE_JOG_MID:
      --                             target_speed_l=BOT_SPEED_MAX;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_L1:
      --                             target_speed_l=BOT_SPEED_FAST;
      --                             target_speed_r=BOT_SPEED_MAX;
      --             case RC5_CODE_JOG_L2:
      --                             target_speed_l=BOT_SPEED_NORMAL;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_L3:
      --                             target_speed_l=BOT_SPEED_SLOW;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_L4:
      --                             target_speed_l=BOT_SPEED_STOP;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;

      --             case RC5_CODE_JOG_L5:
      --                             target_speed_l=-BOT_SPEED_NORMAL;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_L6:
      --                             target_speed_l=-BOT_SPEED_FAST;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_L7:
      --                             target_speed_l=-BOT_SPEED_MAX;
      --                             target_speed_r=BOT_SPEED_MAX;
      --                     break;

      --             case RC5_CODE_JOG_R1:
      --                             target_speed_r=BOT_SPEED_FAST;
      --                             target_speed_l=BOT_SPEED_MAX;
      --             case RC5_CODE_JOG_R2:
      --                             target_speed_r=BOT_SPEED_NORMAL;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_R3:
      --                             target_speed_r=BOT_SPEED_SLOW;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_R4:
      --                             target_speed_r=BOT_SPEED_STOP;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;

      --             case RC5_CODE_JOG_R5:
      --                             target_speed_r=-BOT_SPEED_NORMAL;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_R6:
      --                             target_speed_r=-BOT_SPEED_FAST;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;
      --             case RC5_CODE_JOG_R7:
      --                             target_speed_r=-BOT_SPEED_MAX;
      --                             target_speed_l=BOT_SPEED_MAX;
      --                     break;
            end if;
         end case;
      end if;
   end Control;


   procedure Init is
   begin
      RC5.IR.Init;
   end Init;

end RC5;
