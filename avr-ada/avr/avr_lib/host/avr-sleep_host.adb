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

with Interfaces;
with AVR.Interrupts;

package body AVR.Sleep is


   --  Define internal sleep types for the various devices.  Also define
   --  some internal masks for use in Set_Mode.
   Sleep_Ctrl_Bits : AVR.Bits_In_Byte;
   --  for Sleep_Ctrl_Bits'Address use System.Address (AVR.MCU.SMCR);

   Sleep_Mode_On_Host : Sleep_Mode_T;
   Sleep_Is_Enabled_On_Host : Boolean := False;
   
   
   procedure Sleep_Instr;
   pragma Inline_Always (Sleep_Instr);


   procedure Set_Mode (Mode : Sleep_Mode_T)
   is
   begin
      Sleep_Mode_On_Host := Mode;
   end Set_Mode;


    --  Put the device in sleep mode. How the device is brought out of
    --  sleep mode depends on the specific mode selected with the
    --  set_mode function.  See the data sheet for your device for
    --  more details.


    --  Manipulates the SE (sleep enable) bit.
    procedure Enable
    is
    begin
       Sleep_Is_Enabled_On_Host := True;
    end Enable;


    procedure Disable
    is
    begin
       Sleep_Is_Enabled_On_Host := False;
    end Disable;


    procedure Sleep_Instr
    is
    begin
       null;
    end Sleep_Instr;


    --  Put the device in sleep mode. SE-bit must be set beforehand.
    procedure Go_Sleeping
    is
    begin
       Enable;
       Sleep_Instr;
       Disable;
    end Go_Sleeping;


    --  Put the device in sleep mode if Condition is true.  Condition
    --  is checked and sleep mode entered as one indivisible action.
    procedure Go_Sleeping_If (Condition : Boolean)
    is
       Sreg : Interfaces.Unsigned_8;
    begin
       Sreg := AVR.Interrupts.Save_And_Disable;
       if Condition then Go_Sleeping; end if;
       AVR.Interrupts.Restore (Sreg);
    end Go_Sleeping_If;

end AVR.Sleep;
