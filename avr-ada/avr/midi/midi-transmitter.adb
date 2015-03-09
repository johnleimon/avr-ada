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
-- Written by Warren W. Gay VE3WWG
---------------------------------------------------------------------------
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

package body MIDI.Transmitter is

   ------------------------------------------------------------------
   --     I n t e r n a l   S u p p o r t   R o u t i n e s
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- INTERNAL - Put U16 Value into 2 MIDI data bytes
   ------------------------------------------------------------------
   procedure Put_U16(Value : Unsigned_16; Msg : out U8_Array) is
   begin

      Msg(Msg'First+0) := Unsigned_8( Value and 16#007F# );
      Msg(Msg'First+1) := Unsigned_8( Shift_Right(Value,7) and 16#007F# );

   end Put_U16;

   ------------------------------------------------------------------
   -- INTERNAL - Create a MIDI Status Byte
   ------------------------------------------------------------------
   function Cmd(Status : Unsigned_8; Channel : Channel_Type) return Unsigned_8 is
   begin
      return Status or Unsigned_8(Channel);
   end Cmd;

   pragma Inline(Cmd);

   ------------------------------------------------------------------
   -- INTERNAL - Write a MIDI Message
   ------------------------------------------------------------------
   procedure Write(Context : IO_Context; Msg : U8_Array) is
   begin

      for X in Msg'Range loop
         Context.Transmit_Byte(Msg(X));
      end loop;

   end Write;

   ------------------------------------------------------------------
   -- INTERNAL -- 2 byte commands
   ------------------------------------------------------------------
   procedure Cmd2(
                  Context :       IO_Context;             -- I/O Context
                  Status :        Unsigned_8;             -- MIDI Command
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Parameter :     Unsigned_8              -- Parameter value
                 ) is
      Msg : U8_Array(0..1);
   begin

      Msg(0) := Cmd(Status,Channel);
      Msg(1) := Parameter;
      Write(Context,Msg);

   end Cmd2;

   ------------------------------------------------------------------
   -- INTERNAL -- Issue Control Command
   ------------------------------------------------------------------
   procedure Control_Cmd(
                         Context :       IO_Context;             -- I/O Context
                         Channel :       Channel_Type;           -- MIDI Channel Number
                         Control :       Control_Type;           -- MIDI Control Number
                         Value :         Value_Type              -- Value for the Control
                        ) is
      Msg : U8_Array(0..2);
   begin

      Msg(0) := Cmd(MC_CTL_CHG,Channel);
      Msg(1) := Unsigned_8(Control);
      Msg(2) := Unsigned_8(Value);

      Write(Context,Msg);

   end Control_Cmd;

   ------------------------------------------------------------------
   --       M I D I   T r a n s m i t   R o u t i n e s
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Note On/Off
   ------------------------------------------------------------------
   procedure Note_On_Off(
                         Context :       IO_Context;             -- I/O Context
                         Channel :       Channel_Type;           -- MIDI Channel Number
                         Note :          Note_Type;              -- MIDI Note Number
                         Velocity :      Velocity_Type;          -- Note velocity value
                         Note_On :       Boolean                 -- Note on (True) or off (False)
                        ) is
      Msg : U8_Array(0..2);
   begin

      if Note_On then
         Msg(0) := Cmd(MC_NOTE_ON,Channel);
      else
         Msg(0) := Cmd(MC_NOTE_OFF,Channel);
      end if;

      Msg(1) := Unsigned_8(Note);
      Msg(2) := Unsigned_8(Velocity);

      Write(Context,Msg);

   end;

   ------------------------------------------------------------------
   -- Set Pressure
   ------------------------------------------------------------------
   procedure Pressure(
                      Context :       IO_Context;             -- I/O Context
                      Channel :       Channel_Type;           -- MIDI Channel Number
                      Note :          Note_Type;              -- MIDI Note Number
                      Pressure :      Pressure_Type           -- Pressure value
                     ) is
      Msg : U8_Array(0..2);
   begin

      Msg(0) := Cmd(MC_KEY_PRESSURE,Channel);
      Msg(1) := Unsigned_8(Note);
      Msg(2) := Unsigned_8(Pressure);

      Write(Context,Msg);

   end;

   ------------------------------------------------------------------
   -- All Sounds Off
   ------------------------------------------------------------------
   procedure All_Sounds_Off(
                            Context :       IO_Context;             -- I/O Context
                            Channel :       Channel_Type;           -- MIDI Channel Number
                            Value :         Value_Type              -- Value for the Control
                           ) is
   begin
      Control_Cmd(Context,Channel,MC_CTL_ALLS_OFF,Value);
   end;

   ------------------------------------------------------------------
   -- Reset Controller
   ------------------------------------------------------------------
   procedure Reset_Controller(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Value :         Value_Type              -- Value for the Control
                             ) is
   begin
      Control_Cmd(Context,Channel,MC_CTL_RESET_C,Value);
   end;

   ------------------------------------------------------------------
   -- Local Controller
   ------------------------------------------------------------------
   procedure Local_Controller(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Value :         Value_Type              -- Value for the Control
                             ) is
   begin
      Control_Cmd(Context,Channel,MC_CTL_LOCAL_C,Value);
   end;

   ------------------------------------------------------------------
   -- All Notes Off
   ------------------------------------------------------------------
   procedure All_Notes_Off(
                           Context :       IO_Context;             -- I/O Context
                           Channel :       Channel_Type;           -- MIDI Channel Number
                           Value :         Value_Type              -- Value for the Control
                          ) is
   begin
      Control_Cmd(Context,Channel,MC_CTL_ALLN_OFF,Value);
   end;

   ------------------------------------------------------------------
   -- Omni On/Off
   ------------------------------------------------------------------
   procedure Omni(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Value :         Value_Type;             -- Value for the Control
                  Omni_On :       Boolean                 -- On (True) or Off (False)
                 ) is
   begin
      if Omni_On then
         Control_Cmd(Context,Channel,MC_CTL_OMNI_ON,Value);
      else
         Control_Cmd(Context,Channel,MC_CTL_OMNI_OFF,Value);
      end if;
   end;

   ------------------------------------------------------------------
   -- Mono On/Off
   ------------------------------------------------------------------
   procedure Mono(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Value :         Value_Type;             -- Value for the Control
                  Mono_On :       Boolean                 -- On (True) or Off (False)
                 ) is
   begin
      if Mono_On then
         Control_Cmd(Context,Channel,MC_CTL_MONO_ON,Value);
      else
         Control_Cmd(Context,Channel,MC_CTL_MONO_OFF,Value);
      end if;
   end;

   ------------------------------------------------------------------
   -- Set Program
   ------------------------------------------------------------------
   procedure Program(
                     Context :       IO_Context;             -- I/O Context
                     Channel :       Channel_Type;           -- MIDI Channel Number
                     Program :       Program_Type            -- Program Number
                    ) is
   begin
      Cmd2(Context,MC_PROGRAM_CHG,Channel,Unsigned_8(Program));
   end;

   ------------------------------------------------------------------
   -- Set Channel Pressure
   ------------------------------------------------------------------
   procedure Channel_Pressure(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Pressure :      Pressure_Type           -- Pressure Value
                             ) is
   begin
      Cmd2(Context,MC_CH_PRESSURE,Channel,Unsigned_8(Pressure));
   end;

   ------------------------------------------------------------------
   -- Bend
   ------------------------------------------------------------------
   procedure Bend(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Bend :          Bend_Type               -- Bend Value
                 ) is
      Msg :           U8_Array(0..2);
      Signed_Bend :   Integer_16 := Integer_16(Bend) + 16#1FFF#;
   begin

      Msg(0) := Cmd(MC_BEND,Channel);
      Put_U16(Unsigned_16(Signed_Bend),Msg(1..2));
      Write(Context,Msg);

   end;

   ------------------------------------------------------------------
   -- Sysex Message
   ------------------------------------------------------------------
   procedure Sysex(
                   Context :       IO_Context;             -- I/O Context
                   Manufacturer_ID : Manufacturer_Type;    -- Manufacturer ID Value
                   Sysex :         U8_Array                -- Sysex information
                  ) is
      Msg :           U8_Array(0..1);
   begin

      Msg(0) := Cmd(MC_SYS,MC_SYS_EX);
      Msg(1) := Unsigned_8(Manufacturer_ID);
      Write(Context,Msg);

      for X in Sysex'Range loop
         Context.Transmit_Byte(Sysex(X) and 16#7F#);
      end loop;

      Context.Transmit_Byte(MC_SYS_ENDX);

   end;

   ------------------------------------------------------------------
   -- Set Song Position
   ------------------------------------------------------------------
   procedure Song_Pos(
                      Context :       IO_Context;             -- I/O Context
                      Beats :         Beats_Type              -- Number of beats
                     ) is
      Msg :           U8_Array(0..2);
   begin

      Msg(0) := Cmd(MC_SYS,MC_SYS_SNGPOS);
      Put_U16(Unsigned_16(Beats),Msg(1..2));
      Write(Context,Msg);

   end;

   ------------------------------------------------------------------
   -- Set Song Selection
   ------------------------------------------------------------------
   procedure Song_Selection(
                            Context :       IO_Context;             -- I/O Context
                            Selection :     Song_Selection_Type     -- Song selection number
                           ) is
      Msg :           U8_Array(0..1);
   begin

      Msg(0) := Cmd(MC_SYS,MC_SYS_SNGSEL);
      Msg(1) := Unsigned_8(Selection);
      Write(Context,Msg);
   end;

   ------------------------------------------------------------------
   -- Issue Tune Request
   ------------------------------------------------------------------
   procedure Tune_Request(
                          Context :       IO_Context              -- I/O Context
                         ) is
   begin
      Context.Transmit_Byte(Cmd(MC_SYS,MC_SYS_TREQ));
   end;

   ------------------------------------------------------------------
   -- Issue a Realtime Command
   ------------------------------------------------------------------
   procedure Realtime(
                      Context :       IO_Context;             -- I/O Context
                      Realtime_Cmd :  Status_Type             -- MIDI Realtime command byte
                     ) is
   begin

      case Realtime_Cmd is
         when MC_SYS_TCLK | MC_SYS_START | MC_SYS_CONT | MC_SYS_STOP
           | MC_SYS_ASENSE | MC_SYS_RESET =>

            Context.Transmit_Byte(Cmd(MC_SYS,Channel_Type(Realtime_Cmd)));

         when others =>
            null;
      end case;

   end;

end MIDI.Transmitter;
