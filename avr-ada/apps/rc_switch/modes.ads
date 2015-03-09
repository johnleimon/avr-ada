--
--  The RC switch can be in one of three modes.
--
--  Typically mode 0 is all off, mode 1 is on.
--
--  Some transmitters have a three position switch and the third
--  position is mode 2. Mode 2 is often connected to a second device
--  or applies a different blink pattern to an attached LED.

with Interfaces;                   use Interfaces;
package Modes is

   type Mode_T is new Integer_8 range 0 .. 2;
   Mode : Mode_T;
   pragma Volatile (Mode);
   --
   -- available activities that can be attached to a mode
   -- if no procedure is assigned to a mode, then nothing will be done
   procedure LED_Blue_On;
   procedure LED_White_On;
   procedure LED_White_Flash;


   type Mode_Activity is access procedure;

   Mode_0_Activity : Mode_Activity := null;
   Mode_1_Activity : Mode_Activity := LED_White_On'access;
   Mode_2_Activity : Mode_Activity := LED_Blue_On'access;


   --  manage mode changes
   procedure Manage_Mode;

end Modes;
