with Interfaces;                   use Interfaces;
-- with Ada.Unchecked_Conversion;
with AVR.Wait;                     use AVR.Wait;
-- with Temperatures;                 use Temperatures;
with SHT.LL;                       use SHT.LL;


package body SHT is


   Processor_Speed  : constant := 8_000_000;

   procedure Wait_2us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 2);
   pragma Inline_Always (Wait_2us);


   procedure Wait_5us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 5);
   pragma Inline_Always (Wait_5us);


   procedure Init
   is
   begin
      SHT.LL.Init;
   end Init;


   --  writes a byte on the Sensibus and checks the acknowledge
   procedure Write_Byte (Value : in  Nat8;
                         E     : out Error_Code)
   is
      B : Nat8;
   begin
      E := OK;
      --  loop over all bit positions
      B := 16#80#;
      while B > 0 loop
         if (B and Value) /= 0 then
            Data_Line_High;
         else
            Data_Line_Low;
         end if;
         Clock_Line_High;
         Wait_2us;
         Clock_Line_Low;
         Wait_2us;
         B := Shift_Right (B, 1);
      end loop;

      Data_Line_High;
      Wait_2us;
      Clock_Line_High;
      Wait_2us;

      if Read_Data_Line = True then
         E := No_Ack_Error;
      end if;
      Clock_Line_Low;
   end Write_Byte;


   --  reads a byte form the Sensibus and gives an acknowledge in case
   --  of "send_ack=true"
   function Read_Byte (Send_Ack : Boolean) return Nat8
   is
      Value : Nat8 := 0;
      B     : Nat8;
   begin
      B := 16#80#;
      Data_Line_High;
      Wait_2us;
      while B > 0 loop
         Clock_Line_High;
         Wait_2us;
         if Read_Data_Line = High then
            Value := Value or B;
         end if;
         Clock_Line_Low;
         Wait_2us;
         B := Shift_Right (B, 1);
      end loop;

      if Send_ACK then
         Data_Line_Low;
      else
         Data_Line_High;
      end if;
      Clock_Line_High;
      Wait_5us;
      Clock_Line_Low;
      Wait_5us;
      Data_Line_High;
      return Value;
   end Read_Byte;


   -- generate a transmission start
   --       _____         ________
   -- DATA:      |_______|
   --           ___     ___
   -- SCK : ___|   |___|   |______
   --
   procedure Transmission_Start
   is
   begin
      Data_Line_High;
      Clock_Line_Low;
      Wait_2us;
      Clock_Line_High;
      Wait_5us;

      Data_Line_Low;
      Wait_5us;

      Clock_Line_Low;
      Wait_5us;
      Wait_5us;
      Clock_Line_High;
      Wait_5us;
      Data_Line_High;
      Wait_5us;
      Clock_Line_Low;
   end Transmission_Start;


   --  communication reset: DATA-line=1 and at least 9 SCK cycles
   --  followed by transstart
   --       ____________________________________________________         _____
   -- DATA:                                                     |_______|
   --          _    _    _    _    _    _    _    _    _       ___     ___
   -- SCK : __| |__| |__| |__| |__| |__| |__| |__| |__| |_____|   |___|   |___

   procedure Connection_Reset
   is
   begin
      Data_Line_High;
      Wait_2us;
      Clock_Line_Low;
      Wait_2us;
      for I in Nat8 range 1 .. 9 loop
         Clock_Line_High;
         Wait_2us;
         Clock_Line_Low;
         Wait_2us;
      end loop;

      Transmission_Start;
   end Connection_Reset;


   -- resets the sensor by a softreset
   procedure Soft_Reset (E : out Error_Code)
   is
   begin
      Connection_Reset;
      Write_Byte (Commands.Soft_Reset, E);
   end Soft_Reset;


   -- reads the status register with checksum (8-bit)
   procedure Read_Statusreg (Status   : out Nat8;
                             Checksum : out Nat8;
                             E        : out Error_Code)
   is
   begin
      Transmission_Start;
      Write_Byte (Commands.Read_Status_Register, E);
      Status   := Read_Byte (Send_Ack => True);
      Checksum := Read_Byte (Send_Ack => False);
   end Read_StatusReg;


   -- Writes the status register with checksum (8-bit)
   procedure Write_Statusreg (Status : in  Nat8;
                              E      : out Error_Code)
   is
      Err1 : Error_Code;
      Err2 : Error_Code;
   begin
      Transmission_Start;
      Write_Byte (Commands.Write_Status_Register, Err1);
      Write_Byte (Status, Err2);
      if Err1 = OK and then Err2 = OK then
         E := OK;
      else
         E := Error;
      end if;
   end Write_Statusreg;


   -- makes a measurement (humidity/temperature) with checksum
   procedure Measure (Raw_Value : out Nat16;
                      Checksum  : out Nat8;
                      Mode      : in  Mode_Type;
                      E         : out Error_Code)
   is
   begin
      E := OK;
      Transmission_Start;
      case Mode is
      when Humidity =>
         Write_Byte (Commands.Measure_Humidity, E);
      when Temperature =>
         Write_Byte (Commands.Measure_Temperature, E);
      end case;
      if E /= OK then return; end if;

      --  wait until sensor has finished the measurement
      for I in Nat16 loop
         exit when Read_Data_Line = Low;
      end loop;
      --  or timeout
      if Read_Data_Line = High then E := Timeout_Error; return; end if;

      Raw_Value := Nat16 (Read_Byte (Send_ACK => True)) * 256;
      Raw_Value := Raw_Value + Nat16 (Read_Byte (Send_ACK => True));
      Checksum  := Read_Byte (Send_ACK => False);
   end Measure;



end SHT;
