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
-- This package implements a midi receiver, with callbacks
-- for identified messages.
--
-- NOTE :
--
--  If receiving the entire SysEx message is important, then specify
--  Max_Sysex to the largest message you need to process. If the
--  received message is larger, it is truncated and given to the
--  callback with the truncated flag set true;
--
--  When using on small memory machines (like AVR) keep the Max_Sysex
--  as small as practical, as this requires stack space for the
--  collecting buffer. The buffer is only allocated on the stack when
--  a Sysex message is received.
----------------------------------------------------------------------
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

package MIDI.Receiver is

   ------------------------------------------------------------------
   -- MIDI Receive Context
   ------------------------------------------------------------------
   type Recv_Context is private;


   ------------------------------------------------------------------
   -- Receive One MIDI Message and issue Callback
   ------------------------------------------------------------------
   procedure Receive(
                     Obj :         in out Recv_Context;          -- MIDI Context
                     IO :          in     IO_Context;            -- I/O Context
                     Max_Sysex :   in     Unsigned_16 := 32);    -- Buffer size max


   ------------------------------------------------------------------
   -- Reset the State of the MIDI Context
   ------------------------------------------------------------------
   procedure Reset(Obj : in out Recv_Context);


   ------------------------------------------------------------------
   --                M I D I   C A L L B A C K S
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Note On/Off
   ------------------------------------------------------------------
   type Note_On_Off_Proc is access
     procedure(Channel :  Channel_Type;
               Note :     Note_Type;
               Velocity : Velocity_Type;
               Note_On :  Boolean);

   ------------------------------------------------------------------
   -- Pressure Change
   ------------------------------------------------------------------
   type Pressure_Proc is access
     procedure(Channel :  Channel_Type;
               Note :     Note_Type;
               Pressure : Pressure_Type);

   ------------------------------------------------------------------
   -- Control Changes Callbacks for:
   --
   --  All_Sounds_Off
   --  Reset_Controller
   --  Local_Controller
   --  All_Notes_Off
   --
   ------------------------------------------------------------------
   type Control_Proc is access
     procedure(Channel : Channel_Type;
               Value :   Value_Type);

   ------------------------------------------------------------------
   -- Unsupported Control Type
   ------------------------------------------------------------------
   type Unsupported_Control_Proc is access
     procedure(Channel : Channel_Type;
               Control : Control_Type;
               Value :   Value_Type);

   ------------------------------------------------------------------
   -- Omni On/Off
   ------------------------------------------------------------------
   type Omni_Proc is access
     procedure(Channel : Channel_Type;
               Value :   Value_Type;
               Omni_On : Boolean);

   ------------------------------------------------------------------
   -- Mono On/Off
   ------------------------------------------------------------------
   type Mono_Proc is access
     procedure(Channel : Channel_Type;
               Value :   Value_Type;
               Mono_On : Boolean);

   ------------------------------------------------------------------
   -- Program Selection
   ------------------------------------------------------------------
   type Program_Proc is access
     procedure(Channel : Channel_Type;
               Program : Program_Type);

   ------------------------------------------------------------------
   -- Channel Pressure
   ------------------------------------------------------------------
   type Channel_Pressure_Proc is access
     procedure(Channel :  Channel_Type;
               Pressure : Pressure_Type);

   ------------------------------------------------------------------
   -- Channel Bend
   ------------------------------------------------------------------
   type Bend_Proc is access
     procedure(Channel : Channel_Type;
               Bend :    Bend_Type);

   ------------------------------------------------------------------
   -- SysEx Message
   ------------------------------------------------------------------
   type Sysex_Proc is access
     procedure(Manufacturer_ID : Manufacturer_Type;
               Sysex :           U8_Array;
               Truncated :       Boolean);

   ------------------------------------------------------------------
   -- Unsupported MIDI Message
   ------------------------------------------------------------------
   type Unsupported_Proc is access
     procedure(Message : U8_Array);

   ------------------------------------------------------------------
   -- Song Position
   ------------------------------------------------------------------
   type Song_Position_Proc is access
     procedure(Beats : Beats_Type);

   ------------------------------------------------------------------
   -- Song Selection
   ------------------------------------------------------------------
   type Song_Selection_Proc is access
     procedure(Selection : Song_Selection_Type);

   ------------------------------------------------------------------
   -- Tune Request
   ------------------------------------------------------------------
   type Tune_Request_Proc is access
     procedure;

   ------------------------------------------------------------------
   -- Realtime Message
   ------------------------------------------------------------------
   type Realtime_Proc is access
     procedure(Cmd : Status_Type);


   ------------------------------------------------------------------
   -- Callback Registrations (all inlined) :
   ------------------------------------------------------------------

   procedure Register_Note_On_Off(Obj : in out Recv_Context; Callback : Note_On_Off_Proc);
   procedure Register_Pressure(Obj : in out Recv_Context; Callback : Pressure_Proc);
   procedure Register_All_Sounds_Off(Obj : in out Recv_Context; Callback : Control_Proc);
   procedure Register_Reset_Controller(Obj : in out Recv_Context; Callback : Control_Proc);
   procedure Register_Local_Controller(Obj : in out Recv_Context; Callback : Control_Proc);
   procedure Register_All_Notes_Off(Obj : in out Recv_Context; Callback : Control_Proc);
   procedure Register_Omni(Obj : in out Recv_Context; Callback : Omni_Proc);
   procedure Register_Mono(Obj : in out Recv_Context; Callback : Mono_Proc);
   procedure Register_Unsupported_Control(Obj : in out Recv_Context; Callback : Unsupported_Control_Proc);
   procedure Register_Program(Obj : in out Recv_Context; Callback : Program_Proc);
   procedure Register_Channel_Pressure(Obj : in out Recv_Context; Callback : Channel_Pressure_Proc);
   procedure Register_Bend(Obj : in out Recv_Context; Callback : Bend_Proc);
   procedure Register_Sysex(Obj : in out Recv_Context; Callback : Sysex_Proc);
   procedure Register_Unsupported(Obj : in out Recv_Context; Callback : Unsupported_Proc);
   procedure Register_Song_Pos(Obj : in out Recv_Context; Callback : Song_Position_Proc);
   procedure Register_Song_Selection(Obj : in out Recv_Context; Callback : Song_Selection_Proc);
   procedure Register_Tune_Request(Obj : in out Recv_Context; Callback : Tune_Request_Proc);
   procedure Register_Realtime(Obj : in out Recv_Context; Callback : Realtime_Proc);

   procedure Register_Idle(Obj : in out Recv_Context; Callback : Idle_Proc);

private

   type Recv_Context is
      record
         Read_Byte :         Read_Byte_Proc;         -- Input Read Proc
         Poll_Byte :         Poll_Byte_Proc;         -- Input poll proc
         Unget_Byte :        Unsigned_8 := 0;        -- Ungot char if /= 0
         Running_Status :    Unsigned_8;             -- Current status (cmd)
         Max_Sysex :         Unsigned_16;            -- Max sysex buffer to allocate

         ----------------------------------------------------------
         -- Registered Callbacks :
         ----------------------------------------------------------
         Note_On_Off :       Note_On_Off_Proc;
         Pressure :          Pressure_Proc;
         All_Sounds_Off :    Control_Proc;
         Reset_Controller :  Control_Proc;
         Local_Controller :  Control_Proc;
         All_Notes_Off :     Control_Proc;
         Omni :              Omni_Proc;
         Mono :              Mono_Proc;
         Unsupported_Control : Unsupported_Control_Proc;
         Program :           Program_Proc;
         Channel_Pressure :  Channel_Pressure_Proc;
         Bend :              Bend_Proc;
         Sysex :             Sysex_Proc;
         Unsupported :       Unsupported_Proc;
         Song_Pos :          Song_Position_Proc;
         Song_Selection :    Song_Selection_Proc;
         Tune_Request :      Tune_Request_Proc;
         Realtime :          Realtime_Proc;
         Idle :              Idle_Proc;

      end record;

   ------------------------------------------------------------------
   -- Registrations are inlined so that the ones you don't use,
   -- won't waste code space in your AVR program memory. They're
   -- all 1-liners anyway.
   ------------------------------------------------------------------
   pragma Inline (Register_Note_On_Off );
   pragma Inline (Register_Pressure );
   pragma Inline (Register_All_Sounds_Off );
   pragma Inline (Register_Reset_Controller );
   pragma Inline (Register_Local_Controller );
   pragma Inline (Register_All_Notes_Off );
   pragma Inline (Register_Omni );
   pragma Inline (Register_Mono );
   pragma Inline (Register_Unsupported_Control );
   pragma Inline (Register_Program );
   pragma Inline (Register_Channel_Pressure );
   pragma Inline (Register_Bend );
   pragma Inline (Register_Sysex );
   pragma Inline (Register_Unsupported );
   pragma Inline (Register_Song_Pos );
   pragma Inline (Register_Song_Selection );
   pragma Inline (Register_Tune_Request );
   pragma Inline (Register_Realtime );
   pragma Inline (Register_Idle );

end MIDI.Receiver;
