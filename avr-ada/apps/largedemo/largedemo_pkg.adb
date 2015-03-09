-- ----------------------------------------------------------------------------
--  "THE BEER-WARE LICENSE" (Revision 42):
--  <joerg@FreeBSD.ORG> wrote this file.  As long as you retain this notice you
--  can do whatever you want with this stuff. If we meet some day, and you
--  think this stuff is worth it, you can buy me a beer in return. Joerg Wunsch
-- ----------------------------------------------------------------------------

--  More advanced AVR demonstration.  Controls a LED attached to OCR1A.
--  The brightness of the LED is controlled with the PWM.  A number of
--  methods are implemented to control that PWM.

--  This demo was translated from C to Ada by Bernd Trog
--  You can find the C source code in the file avr-libc-1.4.4.tar.bz2
--  This demo was tested on a real ATmega88, compiled with gcc-4.1.0 & 3.4.6

--  It compiles OK for ATmega48/168, but was not tested on these devices.

with Interfaces;     use Interfaces; -- ops of Unsigned_* types

with AVR;            use AVR;
with AVR.MCU;        use AVR.MCU; --  register descriptions

with AVR.Watchdog;                --  on-chip watchdog timer
with AVR.Interrupts;              --  enable/disable interrupts
with AVR.Int_Img;                 --  integer to decimal conversion
with AVR.Strings;    use AVR.Strings;
with AVR.Programspace;            --  read data from on-chip program memory

with AVR.EEprom;                  --  r/w on-chip EEPROM
with AVR.UART;
-- with AVR.Sleep;                   --  power save modes


package body Largedemo_Pkg is

   --  Part 1: constants definitions
   Control_In    : Bits_In_Byte renames PIND_Bits;
   Control_Out   : Bits_In_Byte renames PORTD_Bits;
   Control_DDR   : Bits_In_Byte renames DDRD_Bits;

   Trigger_Down_Bit : constant := PORTD2_Bit;
   Trigger_Up_Bit   : constant := PORTD3_Bit;
   Trigger_ADC_Bit  : constant := PORTD4_Bit;
   Clock_Out_Bit    : constant := PORTD6_Bit;
   Flash_LED_Bit    : constant := PORTD7_Bit;

   Trigger_Down  : Boolean renames Control_In (Trigger_Down_Bit);
   Trigger_Up    : Boolean renames Control_In (Trigger_Up_Bit);
   Trigger_ADC   : Boolean renames Control_In (Trigger_ADC_Bit);
   Clock_Out     : Boolean renames Control_Out (Clock_Out_Bit);
   Flash_LED     : Boolean renames Control_Out (Flash_LED_Bit);

   PWMOUT_Bit    : constant := PORTB1_Bit;
   PWM_Out_DD    : Boolean renames DDRB_Bits (PWMOUT_Bit);


   F_CPU : constant := 1_000_000; --  CPU clock in Hertz

   Softclock_Freq  : constant := 100; --  internal software clock


   --  Timeout to wait after last PWM change till updating the EEPROM.
   --  Measured in internal clock ticks (approx. 100 Hz).

   EE_Update_Time : constant := 3 * Softclock_Freq; --  ca. 3 seconds


   --  Timer1 overflow interrupt will be called with F_CPU / 2048
   --  frequency.  This interrupt routine further divides that value,
   --  resulting in an internal update interval of approx. 10 ms.
   --  (The complicated looking scaling by 10 / addition of 9 is
   --  poor man's fixed-point rounding algorithm...)

   TMR1_Scale : constant :=
     ((F_CPU * 10) / (2048 * Softclock_Freq) + 9) / 10;


   --  Part 2: Variable definitions

   --  Bits that are set inside interrupt routines, and watched outside in
   --  the program's main loop.

   type Intflags_Type is record
      Tmr_Int : Boolean;
      ADC_Int : Boolean;
      Rx_Int  : Boolean;
   end record;
   for Intflags_Type use record
      Tmr_Int at 0 range 0 .. 0;
      ADC_Int at 0 range 1 .. 1;
      Rx_Int  at 0 range 2 .. 2;
   end record;
   for Intflags_Type'Size use 8;
   pragma Volatile (Intflags_Type);

   Intflags : Intflags_Type;


   --  Last character read from the UART.
   Rx_Buff : Character;
   pragma Volatile (Rx_Buff);


   --  Last value read from ADC.
   subtype ADC_Range is Nat16 range 0 .. 1023;
   ADC_Val : ADC_Range;
   pragma Volatile (ADC_Val);


   --  Where to store the PWM value in EEPROM.  This is used in order
   --  to remember the value across a RESET or power cycle.
   subtype PWM_Type is Integer range -10 .. 1010;

   EE_PWM : PWM_Type := 42;
   pragma Linker_Section (EE_PWM, ".eeprom");


   --  Current value of the PWM.
   PWM : PWM_Type;


   --  EEPROM backup timer.  Bumped by the PWM update routine.  If it
   --  expires, the current PWM value will be written to EEPROM.
   PWM_Backup_Tmr : Nat16;


   --  Mirror of the MCUCSR register, taken early during startup.
   MCUCSR_Backup : Nat8;
   pragma Linker_Section (MCUCSR_Backup, ".noinit");


   --  Part 3: Interrupt service routines
   procedure Timer1;
   pragma Export (C, Timer1, Sig_TIMER1_OVF_String);
   pragma Machine_Attribute (Timer1, "signal");


   Timer1_OVF_Scaler : Nat8;

   procedure Timer1 is
   begin
      Timer1_OVF_Scaler := Timer1_OVF_Scaler - 1;
      if Timer1_OVF_Scaler = 0 then
         Timer1_OVF_Scaler := TMR1_Scale;
         Intflags.Tmr_Int := True;
      end if;
   end Timer1;


   --  ADC conversion complete.  Fetch the 10-bit value, and feed the
   --  PWM with it.
   procedure ADC;
   pragma Machine_Attribute (ADC, "signal");
   pragma Export (C, ADC, Sig_ADC_String);
   procedure ADC is
   begin
      ADC_Val := MCU.ADC;
      ADCSRA_Bits (ADIE_Bit) := False;      --  disable ADC interrupt
      Intflags.ADC_Int := True;
   end ADC;


   --  Do all the startup-time peripheral initializations.

   procedure IO_Init
   is
      PWM_From_EEPROM : Nat16;
   begin

      --  Set up the 16-bit timer 1.

      --  Timer 1 will be set up as a 10-bit phase-correct PWM (WGM10 and
      --  WGM11 bits), with OC1A used as PWM output.  OC1A will be set when
      --  up-counting, and cleared when down-counting (COM1A1|COM1A0), this
      --  matches the behaviour needed by the STK500's low-active LEDs.
      --  The timer will runn on full MCU clock (1 MHz, CS10 in TCCR1B).

      TCCR1A := WGM10_Mask or WGM11_Mask or COM1A1_Mask or COM1A0_Mask;
      TCCR1B := CS10_Mask;

      OCR1A := 0;  --  set PWM value to 0


      --  enable pull-ups for pushbuttons
      Control_Out := (Trigger_Down_Bit => True,
                      Trigger_Up_Bit   => True,
                      Trigger_ADC_Bit  => True,
                      others           => False);


      --  Enable Port D outputs: PD6 for the clock output, PD7 for the LED
      --  flasher.  PD1 is UART TxD but not DDRD setting is provided for
      --  that, as enabling the UART transmitter will automatically turn
      --  this pin into an output.
      Control_DDR := (Clock_Out_Bit => DD_Output,
                      Flash_LED_Bit => DD_Output,
                      others        => DD_Input);


      --  As the location of OC1A differs between supported MCU types, we
      --  enable that output separately here. Note that the DDRx register
      --  *might* be the same as CONTROL_DDR above, so make sure to not
      --  clobber it.

      PWM_Out_DD := DD_Output;

      AVR.UART.Init (51);

      --  enable ADC, select ADC clock = F_CPU / 8 (i.e. 125 kHz)
      ADCSRA := ADEN_Mask or ADPS1_Mask or ADPS0_Mask;

      -- TIMSK1 := TOIE1_Mask; -- Atmega169
      TIMSK := TOIE1_Mask;
      Interrupts.Enable;


      --  Enable the watchdog with the largest prescaler.  Will cause a
      --  watchdog reset after approximately 2 s @ Vcc = 5 V
      Watchdog.Enable (Watchdog.WDT_1024K);


      --  Read the value from EEPROM.  If it is not 0xffff (erased cells),
      --  use it as the starting value for the PWM.
      PWM_From_EEPROM := EEprom.Get (EE_PWM'Address);
      if PWM_From_EEPROM /= 16#ffff# then
         PWM := PWM_Type (PWM_From_EEPROM);
         OCR1A := Nat16 (PWM);
      end if;
   end IO_Init;


   --  Some simple UART IO functions.

   --  Send character c down the UART Tx, wait until tx holding register
   --  is empty.
   procedure Putchr (C : Character) renames AVR.UART.Put;

   --  Send a String down the UART Tx.
   procedure Printstr (S : AVR_String) renames AVR.UART.Put;


   --  Same as above, but the string is located in program memory,
   --  so "lpm" instructions are needed to fetch it.
   procedure Printstr_P (S : AVR_String)
   is
      C : Character;
   begin
      for U in S'Range loop
         C := Character'Val (Programspace.Get_Byte (S (U)'Address));
         if C = ASCII.LF then
            Putchr (ASCII.CR);
         end if;
         Putchr (C);
      end loop;
   end Printstr_P;


   --  Update the PWM value.  If it has changed, send the new value down
   --  the serial line.
   procedure Set_PWM (Value : PWM_Type)
   is
      New_Value : PWM_Type;
   begin
      if Value < 0 then
         New_Value := 0;
      elsif Value > 1000 then
         New_Value := 1000;
      else
         New_Value := Value;
      end if;

      if New_Value /= PWM then
         PWM := New_Value;
         OCR1A := Nat16 (PWM);

         --  Calculate a "percentage".  We just divide by 10, as we
         --  limited the max value of the PWM to 1000 above.
         New_Value := New_Value / 10;
         declare
            V_Img : Strings.AStr3;
         begin
            Int_Img.U8_Img_Right (Nat8 (New_Value), V_Img);
            Printstr (V_Img);
            Putchr (' ');
         end;

         PWM_Backup_Tmr := EE_UPDATE_TIME;
      end if;
   end Set_PWM;


   --  Strings stored in flash memory:
   Flash_Ooops : AVR_String := ASCII.LF & "Ooops, the watchdog bit me!";
   pragma Linker_Section (Flash_OOOPS, ".progmem");

   Flash_Hello : AVR_String := ASCII.LF
     & "Hello, this is the AVR-Ada largedemo V1.0 running on an ATmega8";
   pragma Linker_Section (Flash_HELLO, ".progmem");

   Flash_Updated : AVR_String := "[EEPROM updated] ";
   pragma Linker_Section (Flash_UPDATED, ".progmem");

   Flash_Thank_You : AVR_String :=
     ASCII.LF & "Thank you for using serial mode. Good-bye!" & ASCII.LF;
   pragma Linker_Section (Flash_Thank_You, ".progmem");

   Flash_Welcome : AVR_String :=
     ASCII.LF & "Welcome at serial control, "
     & "type +/- to adjust, or 0/1 to turn on/off" & ASCII.LF
     & "the LED, q to quit serial mode, "
     & "r to demonstrate a watchdog reset" & ASCII.LF;
   pragma Linker_Section (Flash_Welcome, ".progmem");

   Flash_ZZZZ : AVR_String := ASCII.LF & "zzzz... zzz....."; -- 17 Byte min.!
   pragma Linker_Section (Flash_ZZZZ, ".progmem");


   --  Part 5: main

   procedure Main
   is
      type Mode_Type is (Mode_Updown, Mode_ADC, Mode_Serial);
      for Mode_Type'Size use 8;
      Mode  : Mode_Type := Mode_Updown;
      Flash : Nat8      := 0;
   begin

      --    Our modus of operation.  MODE_UPDOWN means we watch out for
      --    either PD2 or PD3 being low, and increase or decrease the
      --    PWM value accordingly.  This is the default.
      --    MODE_ADC means the PWM value follows the value of ADC0 (PA0).
      --    This is enabled by applying low level to PD1.
      --    MODE_SERIAL means we get commands via the UART.  This is
      --    enabled by sending a valid V.24 character at 9600 Bd to the
      --    UART.

      IO_Init;

      if (MCUCSR_Backup and WDRF_Mask) /= 0 then
         Printstr_P (Flash_Ooops);
      end if;

      Printstr_P (Flash_Hello);

      loop
         Watchdog.Reset;

         if Intflags.Tmr_Int then
            --  Our periodic 10 ms interrupt happened.  See what we can
            --  do about it.

            Intflags.Tmr_Int := False;

            --  toggle PD6, just to show the internal clock; should
            --  yield ~ 48 Hz on PD6
            Clock_Out := not Clock_Out;

            --  flash LED on PD7, approximately once per second
            Flash := Flash + 1;
            if Flash = 5 then
               Flash_LED := High;
            elsif Flash = 100 then
               Flash := 0;
               Flash_LED := Low;
            end if;

            case Mode is
               when Mode_Serial =>
                  null;
                  --  In serial mode, there's nothing to do anymore here.

               when Mode_Updown =>

                  --  Query the pushbuttons.

                  --  NB: watch out to use PINx for reading, as opposed
                  --  to using PORTx which would be the mirror of the
                  --  _output_ latch register (resp. pullup configuration
                  --  bit for input pins)!

                  if Trigger_Down = Low then
                     Set_PWM (PWM - 10);
                  elsif Trigger_Up = Low then
                     Set_PWM (PWM + 10);
                  elsif Trigger_ADC = Low then
                     Mode := Mode_ADC;
                  end if;

               when Mode_ADC =>
                  if Trigger_ADC = High then
                     Mode := Mode_Updown;
                  else
                     --  Start one conversion.
                     ADCSRA_Bits (ADIE_Bit) := True;
                     ADCSRA_Bits (ADSC_Bit) := True;
                  end if;
            end case;

            if PWM_Backup_Tmr > 0 then
               PWM_Backup_Tmr := PWM_Backup_Tmr - 1;
               if PWM_Backup_Tmr = 0 then

                  --  The EEPROM backup timer expired.  Save the current
                  --  PWM value in EEPROM.  Note that this function might
                  --  block for a few milliseconds (after writing the
                  --  first byte).

                  EEprom.Put (EE_PWM'Address, Nat16 (PWM));
                  Printstr_P (Flash_UPDATED);
               end if;
            end if;

            if Intflags.ADC_Int then
               Intflags.ADC_Int := False;
               Set_PWM (PWM_Type (ADC_Val)); -- none atomic
            end if;

            if Intflags.Rx_Int then
               Intflags.Rx_Int := False;

               if Rx_Buff = 'q' then
                  Printstr_P (Flash_Thank_You);
                  Mode := Mode_Updown;
               else
                  if Mode /= Mode_Serial then
                     Printstr_P (Flash_Welcome);
                     Mode := Mode_Serial;
                  end if;

                  case Rx_Buff is
                     when '+' =>
                        Set_PWM (PWM + 10);

                     when '-' =>
                        Set_PWM (PWM - 10);

                     when '0' =>
                        Set_PWM (0);

                     when '1' =>
                        Set_PWM (1000);

                     when 'r' =>
                        Printstr_P (Flash_ZZZZ);
                        loop
                           null;
                        end loop;

                     when others =>
                        null;
                  end case;
               end if;
            end if;
            -- Sleep.Go_Sleeping;
         end if;
      end loop;
   end Main;
end Largedemo_Pkg;
