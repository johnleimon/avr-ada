-- with System;
with AVR;                          use AVR;
with AVR.MCU;
with AVR.Wait;

package body SHT.LL is


   S_Data_Out  : Bits_In_Byte; --   renames MCU.PORTC_Bits;
   for S_Data_Out'Address use MCU.PORTF_Addr;
   pragma Volatile (S_Data_Out);

   S_Data_In   : Bits_In_Byte; --   renames MCU.PINC_Bits;
   for S_Data_In'Address use MCU.PINF_Addr;
   pragma Volatile (S_Data_In);

   S_Data_DD   : Bits_In_Byte; --   renames MCU.DDRC_Bits;
   for S_Data_DD'Address use MCU.DDRF_Addr;
   pragma Volatile (S_Data_DD);

   -- S_Data_Pin  : constant Bit_Number     := 4;

   S_Clock_Out : Bits_In_Byte; --  renames MCU.PORTC_Bits;
   for S_Clock_Out'Address use MCU.PORTF_Addr;
   pragma Volatile (S_Clock_Out);

   S_Clock_DD  : Bits_In_Byte; --  renames MCU.DDRC_Bits;
   for S_Clock_DD'Address use MCU.DDRF_Addr;
   pragma Volatile (S_Clock_DD);

   -- S_Clock_Pin : constant Bit_Number     := 6;

   S_Vcc_Out   : Bits_In_Byte; -- renames MCU.PORTC_Bits;
   for S_Vcc_Out'Address use MCU.PORTF_Addr;
   pragma Volatile (S_Vcc_Out);

   S_Vcc_DD    : Bits_In_Byte; -- renames MCU.DDRC_Bits;
   for S_Vcc_DD'Address use MCU.DDRF_Addr;
   pragma Volatile (S_Vcc_DD);

   -- S_Vcc_Pin   : constant Bit_Number     := 5;

   --------------------------------------------------------------
   -- test, not used
   Data_In   : Boolean renames MCU.PINF_Bits (4);
   Data_Out  : Boolean renames MCU.PORTF_Bits (4);
   Data_DD   : Boolean renames MCU.DDRF_Bits (4);
   Clock_Out : Boolean renames MCU.PORTF_Bits (6);
   Clock_DD  : Boolean renames MCU.DDRF_Bits (6);
   Vcc_DD    : Boolean renames MCU.DDRF_Bits (5);
   Vcc_Out   : Boolean renames MCU.PORTF_Bits (5);

   --  if true configure the clock IO pin as output only once at start-up
   --  if false set the port pin as output at every clock change
   Init_Clock_Line : constant Boolean := True;

   Init_Vcc_Line   : constant Boolean := True;


   Processor_Speed : constant := 8_000_000;

   procedure Wait_5us is
      new AVR.Wait.Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                                       Micro_Seconds => 50);
   pragma Inline_Always (Wait_5us);


   procedure Clock_Line_High
   is
   begin
      if not Init_Clock_Line then
         Clock_DD := DD_Output;
      end if;
      Clock_Out := High;
   end Clock_Line_High;


   procedure Clock_Line_Low
   is
   begin
      if not Init_Clock_Line then
         Clock_DD := DD_Output;
      end if;
      Clock_Out := Low;
   end Clock_Line_Low;


   procedure Data_Line_High
   is
   begin
      --        S_Data_DD (S_Data_Pin) := DD_Output;
      --        S_Data_Out (S_Data_Pin) := High;

      --  from the Sensirion data sheet:
      --
      --  To avoid signal contention the microcontroller should only
      --  drive DATA low. An external pull-up resistor (e.g. 10k) is
      --  required to pull the signal high.

      --  make data pin input
      Data_DD := DD_Input;
      --  activate pull-up resistor
      Data_Out := High;
   end Data_Line_High;


   procedure Data_Line_Low
   is
   begin
      Data_DD  := DD_Output;
      Data_Out := Low;
   end;


   function Read_Data_Line return Boolean
   is
   begin
      --  make data pin input
      Data_DD := DD_Input;
      --  activate pull-up resistor
      Data_Out := High;

      Wait_5us;
      --  read the data pin
      return Data_In;
   end Read_Data_Line;


   procedure Init
   is
   begin
      if Init_Vcc_Line then
         --  provide Vcc
         Vcc_DD := DD_Output;
         Vcc_Out := High;
      end if;

      if Init_Clock_Line then
         Clock_DD := DD_Output;
      end if;
   end Init;


end SHT.LL;
