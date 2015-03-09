
with Ada.Unchecked_Conversion;
with Interfaces;         use Interfaces;

with AVR;                use AVR;
with AVR.IO;
with AVR.Wait;

with Lcd.Wiring;

package body Lcd is


   function To_Unsigned8 is new Ada.Unchecked_Conversion
     (Source => Character,
      Target => Unsigned_8);

   Processor_Speed : constant := 3_686_400;

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
      use AVR.IO;
      use AVR.Wait;
      use Lcd.Wiring;
   begin
      Set_Bit (Port  => Enable_Port,
	       Bit   => Enable_Pin,
	       Value => True);
      Wait_4_Cycles (1);
      Set_Bit (Port  => Enable_Port,
	       Bit   => Enable_Pin,
	       Value => False);
   end Toggle_Enable;


   procedure Output (Cmd : Unsigned_8; Is_Data : Boolean := False) is
      use AVR.IO;
      use Wiring;
   begin
      --  control pins
      Set_Bit (Port  => ReadWrite_Port,
               Bit   => ReadWrite_Pin,
               Value => False);
      Set_Bit (Port  => RegisterSelect_Port,
               Bit   => RegisterSelect_Pin,
               Value => Is_Data);

      --  write data
      if Wiring.Bus_Width = Mode_4bit then
         --  high nibble first
         Set_Bit (Port  => Data_Port,
		  Bit   => Data0_Pin,
		  Value => (Cmd and 16#10#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data1_Pin,
		  Value => (Cmd and 16#20#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data2_Pin,
		  Value => (Cmd and 16#40#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data3_Pin,
		  Value => (Cmd and 16#80#) /= 0);
         Toggle_Enable;

         --  then low nibble
         Set_Bit (Port  => Data_Port,
		  Bit   => Data0_Pin,
		  Value => (Cmd and 16#01#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data1_Pin,
		  Value => (Cmd and 16#02#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data2_Pin,
		  Value => (Cmd and 16#04#) /= 0);
         Set_Bit (Port  => Data_Port,
		  Bit   => Data3_Pin,
		  Value => (Cmd and 16#08#) /= 0);
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
      use AVR.IO;
      use Lcd.Wiring;
   begin
      --  set data direction registers for output of control and data pins
      Set_Bit (Port  => Enable_DDR,
               Bit   => Enable_Pin,
               Value => True);
      Set_Bit (Port  => ReadWrite_DDR,
	       Bit   => ReadWrite_Pin,
	       Value => True);
      Set_Bit (Port  => RegisterSelect_DDR,
	       Bit   => RegisterSelect_Pin,
	       Value => True);
      Set_Bit (Port  => Data_DDR,
	       Bit   => Data0_Pin,
	       Value => True);
      Set_Bit (Port  => Data_DDR,
	       Bit   => Data1_Pin,
	       Value => True);
      Set_Bit (Port  => Data_DDR,
	       Bit   => Data2_Pin,
	       Value => True);
      Set_Bit (Port  => Data_DDR,
	       Bit   => Data3_Pin,
	       Value => True);

      --  wait at least 16ms after power on
      Wait_10ms;
      Wait_10ms;

      --  write 1 into pins 0 and 1
      declare
         use AVR.IO;
         Tmp : constant Unsigned_8 := Bn (Data0_Pin) or Bn(Data1_Pin);
      begin
         Set (Data_Port, Tmp or Get (Data_Port));
      end;
      Toggle_Enable;

      Wait_5ms;
      --  send last command again (is still in register, just toggle E)
      Toggle_Enable;
      Wait_64us;
      --  send last command a third time
      Toggle_Enable;
      Wait_64us;

      --  set 4 bit mode, clear data bit 0
      Set_Bit (Data_Port, Data0_Pin, False);

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
      Output (To_Unsigned8 (C), Is_Data => True);
   end Put;
   
   
   --  Set digits of absolute value of T, which is zero or
   --  negative. We work with the negative of the value so that
   --  the largest negative number is not a special case.
   procedure Set_Digits (T : Integer_8) is
   begin
      if T <= -10 then
         Set_Digits (T / 10);
         Put (Character'Val (48 - (T rem 10)));
      else
         Put (Character'Val (48 - T));
      end if;
   end Set_Digits;
   
   
   procedure Put (Val : Integer_8) is
   begin
      if Val >= 0 then
         Set_Digits (-Val);
      else
         Put ('-');
         Set_Digits (Val);
      end if;
   end Put;
   
   
   procedure Put (Val : Unsigned_8) is
      pragma Unreferenced (Val);
   begin
      null;
   end Put;


   --  output at the current cursor location
   procedure Put (S : AVR_String) is
   begin
      for C in S'Range loop
         Put (S(C));
      end loop;
   end Put;


   --  output the command code Cmd to the display
   procedure Command (Cmd : Unsigned_8) is
   begin
      Output (Cmd, Is_Data => False);
   end Command;
   
   
   --  clear display and move cursor to home position
   procedure Clear_Screen is
   begin
      Command (Commands.Clear);
   end Clear_screen;


   --  move cursor to home position
   procedure Home is
   begin
      Command (Commands.Home);
   end Home;


   --  move cursor into line Y and before character position X.  Lines
   --  are numbered 1 to 2 (or 1 to 4 on big displays).  The left most
   --  character position is Y = 1.  The right most position is
   --  defined by Lcd.Display.Width;
   procedure Gotoxy (X : Char_Position; Y : Line_Position)
   is
   begin
      case Y is
         when 1 => Command (16#80# + Unsigned_8 (X) - 1);
         when 2 => Command (16#C0# + Unsigned_8 (X) - 1);
      end case;
   end Gotoxy;

end Lcd;
