
--with Ada.Unchecked_Conversion;
with Interfaces;                   use Interfaces;

with AVR;                          use AVR;
with AVR.Wait;

with LCD.Wiring;

package body LCD is


   Processor_Speed : constant := LCD.Wiring.Processor_Speed;


   procedure Wait_10ms is new AVR.Wait.Generic_Wait_Usecs
     (Crystal_Hertz => Processor_Speed,
      Micro_Seconds => 10_000);

   procedure Wait_5ms is new AVR.Wait.Generic_Wait_Usecs
     (Crystal_Hertz => Processor_Speed,
      Micro_Seconds => 5_000);

   procedure Wait_1ms is new AVR.Wait.Generic_Wait_Usecs
     (Crystal_Hertz => Processor_Speed,
      Micro_Seconds => 1_000);

   procedure Wait_64us is new AVR.Wait.Generic_Wait_Usecs
     (Crystal_Hertz => Processor_Speed,
      Micro_Seconds => 64);


   -- set Enable high for a very short time to initiate write.
   procedure Toggle_Enable is
      use AVR.Wait;
      use LCD.Wiring;
   begin
      Enable := True;
      Wait_4_Cycles (1);
      Enable := False;
   end Toggle_Enable;


   procedure Output (Cmd : Unsigned_8; Is_Data : Boolean := False) is
      use Wiring;
   begin
      --  control pins
      ReadWrite := False;
      RegisterSelect := Is_Data;

      --  write data
      if Wiring.Bus_Width = Mode_4bit then
         --  high nibble first
         Data0 := (Cmd and 16#10#) /= 0;
         Data1 := (Cmd and 16#20#) /= 0;
         Data2 := (Cmd and 16#40#) /= 0;
         Data3 := (Cmd and 16#80#) /= 0;

         Toggle_Enable;

         --  then low nibble
         Data0 := (Cmd and 16#01#) /= 0;
         Data1 := (Cmd and 16#02#) /= 0;
         Data2 := (Cmd and 16#04#) /= 0;
         Data3 := (Cmd and 16#08#) /= 0;

         Toggle_Enable;
      else --  8 bit mode
         null; -- !!! FIXME
      end if;

      if Is_Data then
         Wait_1ms;
      else
         Wait_10ms;
      end if;
   end Output;


   --  initialize display
   procedure Init is
      use LCD.Wiring;
   begin
      --  set data direction registers for output of control and data pins
      Enable_DD         := DD_Output;
      ReadWrite_DD      := DD_Output;
      RegisterSelect_DD := DD_Output;

      Data0_DD := DD_Output;
      Data1_DD := DD_Output;
      Data2_DD := DD_Output;
      Data3_DD := DD_Output;

      --  wait at least 16ms after power on
      Wait_10ms;
      Wait_10ms;

      --  write 1 into pins 0 and 1
      Data0 := True;
      Data1 := True;
      Toggle_Enable;

      Wait_5ms;
      --  send last command again (is still in register, just toggle E)
      Toggle_Enable;
      Wait_64us;
      --  send last command a third time
      Toggle_Enable;
      Wait_64us;

      --  set 4 bit mode, clear data bit 0
      Data0 := False;

      -- now we can use the standard Command routine for set up
      if Wiring.Bus_Width = Mode_4bit then
         case Display.Height is
            when 1 => Command (Commands.Mode_4bit_1line);
            when 2 => Command (Commands.Mode_4bit_2line);
            when others => null;
         end case;
      else -- mode_8bit
         null;  --  !!! FIXME
      end if;
      Command (Commands.Display_On);
      Clear_Screen;
      Command (Commands.Entry_Inc);
   end Init;


   --  output at the current cursor location
   procedure Put (C : Character) is
   begin
      Output (Character'Pos (C), Is_Data => True);
   end Put;


   --  output at the current cursor location
   procedure Put (S : AVR_String) is
   begin
      for C in S'Range loop
         Put (S(C));
      end loop;
   end Put;


   --  output the command code Cmd to the display
   procedure Command (Cmd : Command_Type) is
   begin
      Output (Unsigned_8 (Cmd), Is_Data => False);
   end Command;

   --  clear display and move cursor to home position
   procedure Clear_Screen is
   begin
      Command (Commands.Clear);
   end Clear_screen;


   --  move cursor to home position
   procedure Home is
   begin
      Command (16#02#);
   end Home;


   --  move cursor into line Y and before character position X.  Lines
   --  are numbered 1 to 2 (or 1 to 4 on big displays).  The left most
   --  character position is Y = 1.  The right most position is
   --  defined by Lcd.Display.Width;
   procedure GotoXY (X : Char_Position; Y : Line_Position)
   is
   begin
      case Y is
         when 1 => Command (16#80# + Command_Type (X) - 1);
         when 2 => Command (16#C0# + Command_Type (X) - 1);
      end case;
   end GotoXY;

end LCD;
