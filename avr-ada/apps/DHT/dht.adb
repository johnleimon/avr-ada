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

with Interfaces;                   use Interfaces;
with Ada.Unchecked_Conversion;
with AVR;                          use AVR;
with AVR.Wait;                     use AVR.Wait;
--  with AVR.UART;
with AVR.Interrupts;
with DHT.Sensors;

package body DHT is


   Processor_Speed : constant := 16_000_000;


   -- from the data sheet:
   --  Data is comprised of integral and decimal part, the following
   --  is the formula for data.  AM2303 send out higher data bit
   --  firstly!  DATA=8 bit integral RH data+8 bit decimal RH data+8
   --  bit integral T data+8 bit decimal T data+8 bit checksum If the
   --  data transmission is right, check-sum should be the last 8 bit
   --  of "8 bit integral RH data+8 bit decimal RH data+8 bit integral
   --  T data+8 bit decimal T data".


   procedure Start_Measurement (Sensor : Sensor_T)
   is
      pragma Unreferenced (Sensor);
      use DHT.Sensors;
      --  Port_Bits : Bits_In_Byte;
      --  for Port_Bits'Address use Sensor.Port;
      --  DD_Bits   : Bits_In_Byte;
      --  for DD_Bits'Address use Sensor.Port-1;
      --  Pin_Bits : Bits_In_Byte;
      --  for Pin_Bits'Address use Sensor.Port-2;
      --  Data_Out : Boolean renames Port_Bits (Sensor.Pin);
      --  Data_In  : Boolean renames Pin_Bits (Sensor.Pin);
      --  Data_DD  : Boolean renames DD_Bits (Sensor.Pin);
   begin
      S1_DD  := DD_Output;
      S1_Out := High;
   end Start_Measurement;


   procedure Wait_5us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 5);
   pragma Inline_Always (Wait_5us);

   procedure Wait_20us is
      new Generic_Wait_Usecs (Crystal_Hertz => Processor_Speed,
                              Micro_Seconds => 20);
   pragma Inline_Always (Wait_20us);


   procedure Read_Measurement (Sensor : in out Sensor_T)
   is
      use DHT.Sensors;


      function Verify_CRC (Data : Unsigned_32; CRC : Unsigned_8)
                           return Boolean
      is
         D   : Unsigned_32 := Data;
         Sum : Unsigned_8 := 0;
      begin
         for I in 0 .. 3 loop
            Sum := Sum + Unsigned_8 (D and 16#00_00_00_FF#);
            D := Shift_Right (D, 8);
         end loop;
         if Sum = CRC then
            return True;
         else
            return False;
         end if;
      end Verify_CRC;
      pragma Inline (Verify_CRC);

      Data : Unsigned_32;
      CRC  : Unsigned_8;
      Cnt  : Unsigned_8;

      Nr_Trans : constant := 2 + 2*16 + 1*8 - 1;
      subtype Transitions is Unsigned_8 range 0 .. Nr_Trans;

   begin
      Data := 0;
      CRC  := 0;

      AVR.Interrupts.Save_And_Disable;

      S1_DD := DD_Output;
      S1_Out := Low;
      Wait_20us;
      S1_Out := High;
      Wait_20us;
      -- now wait for response
      S1_DD := DD_Input;
      S1_Out := High; -- activate pull-up


      --  bit transmission is started by ~50us low level, a bit '0' is
      --  indicated by 26-28us high level, wheras '1' is indicated by
      --  70us high level.  After switching to high we count the
      --  number of 5us steps.
      --
      --  The first two transistions take about 80us.  They indicate
      --  the start of the communication and must not be interpreted
      --  as data.
      Data_Loop :
      for Tr in Transitions loop
         --  Do not measure the low level.  Detect the error case if
         --  the data line does not raise to high level within 50*5us.
         Cnt := 0;
         while S1_In = Low loop
            Cnt := Cnt + 1;
            exit Data_Loop when Cnt > 50;
            Wait_5us;
         end loop;

         --  Now measure how long the data channel remains high. We
         --  also detect the error case if the data line does not
         --  drop to low level within 30*5us.
         Cnt := 0;
         while S1_In = High loop
            Cnt := Cnt + 1;
            exit Data_Loop when Cnt > 50;
            Wait_5us;
         end loop;

         if Tr > 2 then
            if Tr < 2*16+2 then
               Data := Shift_Left (Data, 1);
               if Cnt > 7 then
                  Data := Data or 16#00_00_00_01#;
               end if;
            else
               CRC := Shift_Left (CRC, 1);
               if Cnt > 7 then
                  CRC := CRC or 16#01#;
               end if;
            end if;
         end if;

      end loop Data_Loop;

      if Cnt < 50 and then Verify_CRC (Data, CRC) then
         --  declare
         --     use UART;
         --  begin
         --     Put("Data: "); Put(Data, 16);
         --     Put(", CRC: "); Put(CRC, 16);
         --     New_Line;
         --  end;

         declare
            function "+" is
               new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                             Target => DHT_Humidity);
            function "+" is
               new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                             Target => DHT_Temperature);
         begin
            Sensor.T := +(Unsigned_16(Data and 16#0000_FFFF#));
            Sensor.H := +(Unsigned_16(Shift_Right(Data, 16) and 16#0000_FFFF#));
         end;
      else
         Sensor.H := Invalid_H;
         Sensor.T := Invalid_T;
      end if;

      AVR.Interrupts.Restore;

      S1_DD := DD_Output;
      S1_Out := High;

   end Read_Measurement;


   function Temperature (Sensor : Sensor_T) return DHT_Temperature is
   begin
      return Sensor.T;
   end Temperature;


   function Humidity (Sensor : Sensor_T) return DHT_Humidity is
   begin
      return Sensor.H;
   end Humidity;

end DHT;
