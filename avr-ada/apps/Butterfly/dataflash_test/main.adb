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

--  simple program to test the dataflash in the Butterfly.  Fill some
--  pages and print their contents to the serial port.

with AVR;                          use AVR;
with AVR.MCU;
with AVR.UART;                     use AVR.UART;

with Dataflash;                    use Dataflash;


procedure Main is

   -- subtype Eight_Bytes is AVR.Nat8_Array (1 .. 8);
   -- Data_8 : Eight_Bytes;
   Data   : AVR.Nat8;
   Data_R : AVR.Nat8;
   -- Offset : Byte_Address;

begin

   MCU.CLKPR := MCU.CLKPCE_Mask; -- set Clock Prescaler Change Enable

   -- set prescaler = 8, Inter RC 8Mhz / 8 = 1Mhz
   -- Set (CLKPR, CLKPS1 or CLKPS0); -- 1MHz
   MCU.CLKPR := 0; -- 8MHz

   AVR.UART.Init (51, True);            -- Baud rate = 9600bps, 1MHZ, u2x=1

   Dataflash.DF_SPI_Init;

   --  init time base
   MCU.TCCR1B := MCU.CS10_Mask;
   MCU.TCNT1 := 16#FFFF#;

   Put_Line ("--- Dataflash Test ---");


   Put ("DF Status = ");
   Put (Read_DF_Status, 16);
   New_Line;

   Put_Line ("fill RAM buffer 1 counting up and buffer 2 counting down");
   for B in Byte_Address loop
      Buffer_Write_Byte (BufferNo => 1,
                         IntPageAdr => B,
                         Data => Nat8 (B mod 256));

      Buffer_Write_Byte (BufferNo => 2,
                         IntPageAdr => Byte_Address'Last - B,
                         Data => Nat8 (B mod 256));
   end loop;


   Put_Line ("read buffer 1 and dump it to the terminal");
   for B in Byte_Address loop
      Data := Buffer_Read_Byte (BufferNo => 1,
                                IntPageAdr => B);

      if (B mod 8) = 0 then
         New_Line;
         Put (Nat8 (B), 16);
         Put (": ");
      end if;
      Put (Data, 16);
      Put (' ');

   end loop;
   New_Line(2);

   Put_Line ("read buffer 2 and dump it to the terminal");
   for B in Byte_Address loop
      Data := Buffer_Read_Byte (BufferNo   => 2,
                                IntPageAdr => B);

      if (B mod 8) = 0 then
         New_Line;
         Put (Nat8 (B), 16);
         Put (": ");
      end if;
      Put (Data, 16);
      Put (' ');

   end loop;
   New_Line(2);

   Put_Line ("Fill pages with pattern from SRAM buffer 1");
   for Page in Page_Address loop
      Put ("writing page ");  Put (Nat16 (Page));  New_Line;

      -- fill RAM buffer 1
      for B in Byte_Address loop
         Data := Nat8 (B);
         if (B mod 8) = 0 then
            Data := Nat8 (Page);
         end if;

         Buffer_Write_Byte (BufferNo   => 1,
                            IntPageAdr => B,
                            Data       => Data);
      end loop;

      Buffer_To_Page (1, Page);
   end loop;


   Put_Line ("verifying pages with pattern from SRAM buffer 1");
   for Page in Page_Address loop
      Put ("reading page ");  Put (Nat16 (Page));  New_Line;

      Page_To_Buffer (Page, 1);

      for B in Byte_Address loop
         Data := Nat8 (B);
         if (B mod 8) = 0 then
            Data := Nat8 (Page);
         end if;

         Data_R := Buffer_Read_Byte (BufferNo   => 1,
                                     IntPageAdr => B);

         if Data /= Data_R then
            Put ("read error at page "); Put (Nat16 (Page));
            Put (" addr "); Put (Nat16 (B));
            New_Line;
         end if;
      end loop;

   end loop;








--     Put_Line ("Fill even pages with pattern from SRAM buffer 1 and odd");
--     Put_Line ("pages with pattern from buffer 2.");
--     for Page in Page_Address'(3) .. 10 loop
--        Buffer_To_Page (Buffer_Index (Page mod 2 + 1), Page);
--     end loop;

--     Put_Line ("dump all flash contents to terminal using array read");
--     for Page in Page_Address'(5) .. 58 loop
--        Page_To_Buffer (Page, 1);
--        New_Line (2);
--        Put ("-----   page "); Put (Nat16 (Page)); Put (" ----");
--        New_Line;
--        for B in 0 .. Byte_Address'Last / 8 loop
--           Offset := B * 8;
--           Buffer_Read_Array (1, Offset, Data_8);

--           Put (Nat16 (Offset), 16);
--           Put (':');
--           for J in Eight_Bytes'Range loop
--              Put (' ');
--              Put (Data_8 (J), 16);
--           end loop;
--           New_Line;
--        end loop;
--     end loop;

--     loop
--        null;
--     end loop;

end Main;
