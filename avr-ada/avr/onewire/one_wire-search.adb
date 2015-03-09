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

--  with Usart; -- debug

with Interfaces;            use Interfaces;
with One_Wire.ROM;
with One_Wire.Commands;
with CRC8;

package body One_Wire.Search is


   Last_Discrepancy        : Unsigned_8 := 0;
   Last_Family_Discrepancy : Unsigned_8 := 0;
   Last_Device_Flag        : Boolean    := False;
   CRC                     : Unsigned_8 := 0;


   -- Perform the 1-Wire Search Algorithm on the 1-Wire bus using the existing
   -- search state.
   -- Return TRUE : device found, ROM number in IDENTIFIER buffer
   -- FALSE : device not found, end of search
   function Search return Boolean is
      Id_Bit_Number    : Unsigned_8 := 1;
      Last_Zero        : Unsigned_8 := 0;
      ROM_Byte_Number  : ROM.Serial_Code_Index := 1;
      Search_Result    : Boolean    := False;
      Id_Bit,
      Cmp_Id_Bit       : Unsigned_8;
      ROM_Byte_Mask    : Unsigned_8 := 16#01#;
      Search_Direction : Unsigned_8;
      Dummy            : Unsigned_8;
   begin
      CRC := 0;

      -- if the last call was not the last one
      if not Last_Device_Flag then

         -- 1-Wire reset
         -- if not (Reset = Present) then
         if not (Reset = True) then
            -- reset the search
            Last_Discrepancy := 0;
            Last_Device_Flag := False;
            Last_Family_Discrepancy := 0;
            return False;
         end if;

         -- issue the search command
         Send_Command (One_Wire.Commands.Search_ROM);   --  16#F0#

     Search_Loop:
         loop
            -- read a bit and its complement
            Id_Bit := Read_Write_Bit (1);
            Cmp_Id_Bit := Read_Write_Bit (1);
            -- check for no devices on 1-wire
            if (Id_Bit = 1) and then (Cmp_Id_Bit = 1) then
               exit Search_Loop;
            else
               -- all devices coupled have 0 or 1
               if Id_Bit /= Cmp_Id_Bit then
                  Search_Direction := Id_Bit; -- bit write value for search
               else
                  --  if this discrepancy if before the Last Discrepancy
                  --  on a previous next then pick the same as last time.
                  if Id_Bit_Number < Last_Discrepancy then
                     if (ROM.Identifier (ROM_Byte_Number) and ROM_Byte_Mask) = 0
                     then
                        Search_Direction := 0;
                     else
                        Search_Direction := 1;
                     end if;
                  else
                     -- if equal to last pick 1, if not then pick 0
                     if Id_Bit_Number = Last_Discrepancy then
                        Search_Direction := 1;
                     else
                        Search_Direction := 0;
                     end if;
                  end if;

                  -- if 0 was picked then record its position in LastZero
                  if Search_Direction = 0 then
                     Last_Zero := Id_Bit_Number;
                     -- check for Last discrepancy in family
                     if Last_Zero < 9 then
                        Last_Family_Discrepancy := Last_Zero;
                     end if;
                  end if;
               end if;

               --  set or clear the bit in the ROM byte ROM_byte_number
               --  with mask ROM_byte_mask
               if Search_Direction = 1 then
                  ROM.Identifier (ROM_Byte_Number) :=
                    ROM.Identifier (ROM_Byte_Number) or ROM_Byte_Mask;
               else
                  ROM.Identifier (ROM_Byte_Number) :=
                    ROM.Identifier (ROM_Byte_Number) and (not ROM_Byte_Mask);
               end if;

               -- serial number search direction write bit
               Dummy := Read_Write_Bit (Search_Direction);

               -- increment the byte counter id_bit_number
               -- and shift the mask ROM_byte_mask
               Id_Bit_Number := Id_Bit_Number + 1;
               ROM_Byte_Mask := Shift_Left (ROM_Byte_Mask, 1);

               -- if the mask is 0 then go to new SerialNum byte
               -- ROM_byte_number and reset mask
               if ROM_Byte_Mask = 0 then
                  -- accumulate the CRC
                  CRC := CRC8 (ROM.Identifier (ROM_Byte_Number), CRC);
                  -- loop until through all ROM bytes 1 .. 8
                  exit Search_Loop when ROM_Byte_Number = 8;
                  ROM_Byte_Number := ROM_Byte_Number + 1;
                  ROM_Byte_Mask := 16#01#;
               end if;
            end if;

         end loop Search_Loop;

         -- if the search was successful then
         -- if not (Id_Bit_Number < 65 or else CRC /= 0) then
         if not (Id_Bit_Number < 65) then
            --  search successful so set Last_Discrepancy,
            --  Last_Device_Flag, search_result
            Last_Discrepancy := Last_Zero;

            -- check for last device
            if Last_Discrepancy = 0 then
               Last_Device_Flag := True;
            end if;

            Search_Result := True;
         end if;
      end if;

      --  if no device found then reset counters so next 'search' will
      --  be like a first.
      if not Search_Result or else ROM.Identifier (1) = 0 then
         Last_Discrepancy := 0;
         Last_Device_Flag := False;
         Last_Family_Discrepancy := 0;
         Search_Result := False;
      end if;
      return Search_Result;
   end Search;


   -- Find the 'first' devices on the 1-Wire bus
   -- Return TRUE : device found, ROM number in IDENTIFIER buffer
   -- FALSE : no device present
   function First return Boolean is
   begin
      -- reset the search state
      Last_Discrepancy := 0;
      Last_Device_Flag := False;
      Last_Family_Discrepancy := 0;
      return Search;
   end First;


   -- Find the 'next' devices on the 1-Wire bus
   -- Return TRUE : device found, ROM number in IDENTIFIER buffer
   -- FALSE : device not found, end of search
   function Next return Boolean is
   begin
      -- leave the search state alone
      return Search;
   end Next;


   --  Setup the search to find the device type 'family_code' on the
   --  next call to Next if it is present.
   procedure Target_Setup (Family_Code : Unsigned_8) is
   begin
      -- set the search state to find SearchFamily type devices
      ROM.Identifier := (1 => Family_Code, others => 0);
      Last_Discrepancy := 64;
      Last_Family_Discrepancy := 0;
      Last_Device_Flag := False;
   end Target_Setup;


   -- Setup the search to skip the current device type on the next call
   -- to Next.
   procedure Family_Skip_Setup is
   begin
      -- set the Last discrepancy to last family discrepancy
      Last_Discrepancy := Last_Family_Discrepancy;
      Last_Family_Discrepancy := 0;
      -- check for end of list
      if Last_Discrepancy = 0 then
         Last_Device_Flag := True;
      end if;
   end;


   --  Verify the device with the ROM number in ROM.Identifier buffer
   --  is present.
   --  Return TRUE : device verified present
   --  FALSE : device not present
   ROM_Backup : ROM.Unique_Serial_Code; --  allocate statically, not on stack

   function Verify return Boolean is
      Ld_Backup, Lfd_Backup : Unsigned_8;
      Rslt, LDF_Backup : Boolean;
      use One_Wire.ROM; --  make "=" visible
   begin
      -- keep a backup copy of the current state
      ROM_Backup := ROM.Identifier;
      LD_Backup  := Last_Discrepancy;
      LDF_Backup := Last_Device_Flag;
      LFD_Backup := Last_Family_Discrepancy;
      -- set search to find the same device
      Last_Discrepancy := 64;
      Last_Device_Flag := False;
      if Search then
         -- check if same device found
         Rslt := (ROM_Backup = ROM.Identifier);
      else
         Rslt := False;
      end if;
      -- restore the search state
      ROM.Identifier := ROM_Backup;
      Last_Discrepancy := Ld_Backup;
      Last_Device_Flag := Ldf_Backup;
      Last_Family_Discrepancy := Lfd_Backup;
      -- return the result of the verify
      return Rslt;
   end Verify;

end One_Wire.Search;
