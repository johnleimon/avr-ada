with AVR;                          use AVR;
with AVR.MCU;

private package LCD.Wiring is
   pragma Preelaborate;

   type Bus_Mode is (Mode_4bit, Mode_8bit);

   Bus_Width         : constant Bus_Mode := Mode_4bit;

   Data_Port         : Nat8 renames MCU.PORTA;
   Data_DD           : Nat8 renames MCU.DDRA;

   Data0             : Boolean renames Data_Port (0);
   Data1             : Boolean renames Data_Port (1);
   Data2             : Boolean renames Data_Port (2);
   Data3             : Boolean renames Data_Port (3);
   Data0_DD          : Boolean renames Data_DD (0);
   Data1_DD          : Boolean renames Data_DD (1);
   Data2_DD          : Boolean renames Data_DD (2);
   Data3_DD          : Boolean renames Data_DD (3);

   RegisterSelect    : Boolean renames MCU.PORTA (5);
   RegisterSelect_DD : Boolean renames MCU.DDRA (5);
   ReadWrite         : Boolean renames MCU.PORTA (6);
   ReadWrite_DD      : Boolean renames MCU.DDRA (6);
   Enable            : Boolean renames MCU.PORTA (7);
   Enable_DD         : Boolean renames MCU.DDRA (7);

   --

   Processor_Speed   : constant := 4_000_000;

end LCD.Wiring;
