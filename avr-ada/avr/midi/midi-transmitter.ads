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

package MIDI.Transmitter is

   ------------------------------------------------------------------
   -- Set Note On/Off
   ------------------------------------------------------------------
   procedure Note_On_Off(
                         Context :       IO_Context;             -- I/O Context
                         Channel :       Channel_Type;           -- MIDI Channel Number
                         Note :          Note_Type;              -- MIDI Note Number
                         Velocity :      Velocity_Type;          -- Note velocity value
                         Note_On :       Boolean                 -- Note on (True) or off (False)
                        );

   ------------------------------------------------------------------
   -- Set Pressure
   ------------------------------------------------------------------
   procedure Pressure(
                      Context :       IO_Context;             -- I/O Context
                      Channel :       Channel_Type;           -- MIDI Channel Number
                      Note :          Note_Type;              -- MIDI Note Number
                      Pressure :      Pressure_Type           -- Pressure value
                     );

   ------------------------------------------------------------------
   -- Set All Sounds Off
   ------------------------------------------------------------------
   procedure All_Sounds_Off(
                            Context :       IO_Context;             -- I/O Context
                            Channel :       Channel_Type;           -- MIDI Channel Number
                            Value :         Value_Type              -- Value for the Control
                           );

   ------------------------------------------------------------------
   -- Reset Controller
   ------------------------------------------------------------------
   procedure Reset_Controller(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Value :         Value_Type              -- Value for the Control
                             );

   ------------------------------------------------------------------
   -- Set Local Controller
   ------------------------------------------------------------------
   procedure Local_Controller(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Value :         Value_Type              -- Value for the Control
                             );

   ------------------------------------------------------------------
   -- Set All Notes Off
   ------------------------------------------------------------------
   procedure All_Notes_Off(
                           Context :       IO_Context;             -- I/O Context
                           Channel :       Channel_Type;           -- MIDI Channel Number
                           Value :         Value_Type              -- Value for the Control
                          );

   ------------------------------------------------------------------
   -- Set Omni On/Off
   ------------------------------------------------------------------
   procedure Omni(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Value :         Value_Type;             -- Value for the Control
                  Omni_On :       Boolean                 -- On (True) or Off (False)
                 );

   ------------------------------------------------------------------
   -- Set Mono On/Off
   ------------------------------------------------------------------
   procedure Mono(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Value :         Value_Type;             -- Value for the Control
                  Mono_On :       Boolean                 -- On (True) or Off (False)
                 );

   ------------------------------------------------------------------
   -- Set Program Number
   ------------------------------------------------------------------
   procedure Program(
                     Context :       IO_Context;             -- I/O Context
                     Channel :       Channel_Type;           -- MIDI Channel Number
                     Program :       Program_Type            -- Program Number
                    );

   ------------------------------------------------------------------
   -- Set Channel Pressure
   ------------------------------------------------------------------
   procedure Channel_Pressure(
                              Context :       IO_Context;             -- I/O Context
                              Channel :       Channel_Type;           -- MIDI Channel Number
                              Pressure :      Pressure_Type           -- Pressure Value
                             );

   ------------------------------------------------------------------
   -- Issue Bend Command
   ------------------------------------------------------------------
   procedure Bend(
                  Context :       IO_Context;             -- I/O Context
                  Channel :       Channel_Type;           -- MIDI Channel Number
                  Bend :          Bend_Type               -- Bend Value
                 );

   ------------------------------------------------------------------
   -- Issue Sysex Message
   --
   -- Note: Sysex data bytes are "anded" with 16#07F# to enforce
   --       the MIDI data rule (high bit must be zero).
   ------------------------------------------------------------------
   procedure Sysex(
                   Context :       IO_Context;             -- I/O Context
                   Manufacturer_ID : Manufacturer_Type;    -- Manufacturer ID Value
                   Sysex :         U8_Array                -- Sysex information
                  );

   ------------------------------------------------------------------
   -- Set Song Position
   ------------------------------------------------------------------
   procedure Song_Pos(
                      Context :       IO_Context;             -- I/O Context
                      Beats :         Beats_Type              -- Number of beats
                     );

   ------------------------------------------------------------------
   -- Set Song Selection
   ------------------------------------------------------------------
   procedure Song_Selection(
                            Context :       IO_Context;             -- I/O Context
                            Selection :     Song_Selection_Type     -- Song selection number
                           );

   ------------------------------------------------------------------
   -- Issue Tune Request
   ------------------------------------------------------------------
   procedure Tune_Request(
                          Context :       IO_Context              -- I/O Context
                         );

   ------------------------------------------------------------------
   -- Issue Realtime Command:
   --
   -- Realtime_Cmd must be one of:
   --
   -- MC_SYS_TCLK | MC_SYS_START | MC_SYS_CONT | MC_SYS_STOP
   --             | MC_SYS_ASENSE | MC_SYS_RESET
   ------------------------------------------------------------------
   procedure Realtime(
                      Context :       IO_Context;             -- I/O Context
                      Realtime_Cmd :  Status_Type             -- MIDI Realtime command (see above)
                     );

private

   pragma Inline(All_Sounds_Off);
   pragma Inline(Reset_Controller);
   pragma Inline(Local_Controller);
   pragma Inline(All_Notes_Off);
   pragma Inline(Program);
   pragma Inline(Channel_Pressure);
   pragma Inline(Tune_Request);
   pragma Inline(Realtime);

end MIDI.Transmitter;
