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

--  This is AVR mega169 version implementation of 1-Wire protocol

with Interfaces;                   use Interfaces;

with AVR;                          use AVR;
with AVR.Wait;                     use AVR.Wait;

with AVR.Interrupts;

with One_Wire.AVR_Wiring;          use One_Wire.AVR_Wiring;

package body One_Wire is


   --  these must become generic parameters
   -- Processor_Speed : constant     := 3_686_400; -- STK 500 standard
   Processor_Speed : constant        := 8_000_000; -- Butterfly RC clock
   -- Processor_Speed : constant     := 2_000_000; -- Butterfly RC clock / 4

   --  use internal pull-up resistor.  Set to false if using an
   --  external resistor.  It saves a few instructions.
   Internal_Pull_Up : constant Boolean := True;


   procedure Wait_480us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 480);
   pragma Inline_Always (Wait_480us);

   procedure Wait_410us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 410);
   pragma Inline_Always (Wait_410us);

   procedure Wait_70us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 70);
   pragma Inline_Always (Wait_70us);

   procedure Wait_50us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 50);
   pragma Inline_Always (Wait_50us);

   procedure Wait_10us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 10);
   pragma Inline_Always (Wait_10us);

   procedure Wait_6us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 6);
   pragma Inline_Always (Wait_6us);

   procedure Wait_4us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 4);
   pragma Inline_Always (Wait_4us);


   Standard_Prescaler : Unsigned_8; -- possibly save the current value
   --  of the clock prescaler in ordre to set it back after
   --  communication in Exit_Comm.
   procedure Init_Comm is separate;

   procedure Exit_Comm is
   begin
      AVR.Interrupts.Enable_Interrupts;
   end Exit_Comm;


   procedure Set_Data_Line_High
   is
   begin
      -- make port an output and set it high
      OW_DD := DD_Output;
      OW_Out := High;
   end Set_Data_Line_High;


   function Reset return Boolean is
      Found : Boolean := False;
   begin
      -- Algorithm:
      --    1) drive output line low
      --    2) delay 480 us
      --    3) release output line
      --    4) dealy 70 us
      --    5) read line as input
      --    6) dalay 410 us
      --
      -- If line is low while reading (5) at least one slave is present

      -- make port an output and set it low
      OW_DD := DD_Output;
      OW_Out := Low;

      -- wait 480 us, then release the line and turn it into input
      Wait_480us;

      OW_DD := DD_Input;
      if Internal_Pull_Up then OW_Out := High; end if;

      -- wait 60us < t < 120us and read the line.  If it is low, we
      -- found a 1-Wire device.
      Wait_70us;

      if OW_In = Low then
         Found := True;
      else
         Found := False;
      end if;

      -- complete the reset sequence recovery
      Wait_410us;
      if OW_In = Low then
         --  still at low level, short circuit?
         Found := False;
      end if;

      return  Found;

      --  00000000 <one_wire__reset>:
      --     0:   6c 9a           sbi     0x0d, 4 ; 13
      --     2:   74 98           cbi     0x0e, 4 ; 14

      --     4:   80 ec           ldi     r24, 0xC0       ; 192
      --     6:   93 e0           ldi     r25, 0x03       ; 3 ;
      --  16#03C0# = 10#960#
      --  960 * 4 steps = 3840 instructions
      --  3840 / 8 MHz = 480 us
      --     8:   01 97           sbiw    r24, 0x01       ; 1
      --     a:   f1 f7           brne    .-4             ; 0x8

      --     c:   6c 98           cbi     0x0d, 4 ; 13
      --     e:   74 9a           sbi     0x0e, 4 ; 14

      --    10:   8c e8           ldi     r24, 0x8C       ; 140
      --    12:   90 e0           ldi     r25, 0x00       ; 0
      --    14:   01 97           sbiw    r24, 0x01       ; 1
      --    16:   f1 f7           brne    .-4             ; 0x14

      --    18:   64 99           sbic    0x0c, 4 ; 12
      --    1a:   02 c0           rjmp    .+4             ; 0x20
      --    1c:   81 e0           ldi     r24, 0x01       ; 1
      --    1e:   01 c0           rjmp    .+2             ; 0x22
      --    20:   80 e0           ldi     r24, 0x00       ; 0

      --    22:   e4 e3           ldi     r30, 0x34       ; 52
      --    24:   f3 e0           ldi     r31, 0x03       ; 3
      --    26:   31 97           sbiw    r30, 0x01       ; 1
      --    28:   f1 f7           brne    .-4             ; 0x26

      --    2a:   08 95           ret
   end Reset;


   function Read_Write_Bit (Bit : Unsigned_8) return Unsigned_8 is

      -- Read_Bit Algorithm:
      --    1) drive bus low
      --    2) delay 4us
      --    3) release bus
      --    4) delay 6us
      --    5) read bit (sampling must occur < 15us after pulling bus low)
      --    6) delay 60us

      -- Write_1_Bit algorithm:
      --    1) drive bus low
      --    2) delay 4us
      --    3) release bus
      --    4) delay 66us

      -- Write_0_Bit algorithm:
      --    1) drive bus low
      --    2) delay 60us
      --    3) release bus
      --    4) delay 10us

      -- H  \       |       |                        |    |
      --    |\      ---------------------------------------     read
      -- L  | \____/|       |                        |    |
      --    |       |       |                        |    |
      --    |       | ______________________________ |    |
      -- H  \       |/      |                       \|    |
      --    |\      /       |                        ------     write 1
      -- L  | \____/|       |                        |    |
      --    |       |       |                        |    |
      --    |       |       |                        |    |
      -- H  \       |       |                        |    |
      --    |\      |       |                        ------     write 0
      -- L  | \_____________________________________/|    |
      --    |       |       |                        |    |
      --    |       |       |                        |    |
      --  start    4us    10us                      60us 70us


      --  if the input is 0, write a 0 and return a 0 unconditionally,
      --  as we don't change the DD register.
      --
      --  if the input is 1, write a 1 and sample after 10us, return
      --  the sampled value.
      --
      --  as a result this routine can be used for writing bits and at
      --  the same time can be used for reading, if the input is
      --  set (see Get)-routine).

      Return_Bit : Unsigned_8 := Bit;
   begin
      AVR.Interrupts.Disable_Interrupts;

      -- make port an output and set it low
      OW_DD := DD_Output;
      OW_Out := Low;

      Wait_4us;

      --  release bus if writing 1 or for reading
      if Bit /= 0 then
         OW_DD := DD_Input;
         if Internal_Pull_Up then OW_Out := High; end if;
      end if;

      Wait_6us;

      --  read the bus, Return_Bit was initialised as set, clear it
      --  now if we read a 0.
      if OW_In = Low then
         Return_Bit := 0;
      end if;

      Wait_50us;

      -- the release at the end of the frame
      OW_DD := DD_Input;
      if Internal_Pull_Up then OW_Out := High; end if;

      -- recovery time between frames
      Wait_10us;

      AVR.Interrupts.Enable_Interrupts;

      return Return_Bit;
   end Read_Write_Bit;


   function Touch (Set : Unsigned_8) return Unsigned_8 is
      V : Unsigned_8 := Set;
      R : Unsigned_8 := Set;
   begin
      for I in Bit_Number loop
         R := Read_Write_Bit (V and 16#01#);
         V := Shift_Right (V, 1);
         if R /= 0 then
            V := V or 16#80#;
         end if;
      end loop;
      return V;
   end Touch;


   procedure Send_Command (Command : Command_Code) is
      Dummy : Unsigned_8;
   begin
      Dummy := Touch (Unsigned_8 (Command));
   end Send_Command;


   function Get return Unsigned_8 is
   begin
      return Touch (16#FF#);
   end Get;


end One_Wire;
