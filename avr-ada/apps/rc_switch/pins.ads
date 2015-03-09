--  set the actual wiring here
--

with AVR.MCU;
use AVR;

package Pins is
   pragma Elaborate_Body;

   Port      : Bits_In_Byte renames MCU.PortB_Bits;
   DD        : Bits_In_Byte renames MCU.DDRB_Bits;

   Rx_Signal : Boolean renames Port (0);
   White_Pin : Boolean renames Port (3);
   Blue_Pin  : Boolean renames Port (2);

   Rx_DD     : Boolean renames DD (0);
   White_DD  : Boolean renames DD (3);
   Blue_DD   : Boolean renames DD (2);

end Pins;
