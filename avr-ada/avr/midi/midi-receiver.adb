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

with Ada.Unchecked_Conversion;

package body MIDI.Receiver is

   function To_I16 is new Ada.Unchecked_Conversion(Unsigned_16,Integer_16);

   ------------------------------------------------------------------
   -- Convert 2 consecutive midi bytes to an Unsigned_16
   ------------------------------------------------------------------
   function To_U16(Msg : U8_Array) return Unsigned_16 is
   begin
      return Shift_Left(Unsigned_16(Msg(Msg'First+1)),7) or Unsigned_16(Msg(Msg'First));
   end To_U16;

   pragma Inline(To_U16);

   ------------------------------------------------------------------
   -- Reset the State of the MIDI Receive Context
   ------------------------------------------------------------------
   procedure Reset(Obj : in out Recv_Context) is
   begin
      Obj.Running_Status := No_Cmd;
      Obj.Unget_Byte     := No_Cmd;
   end Reset;

   ------------------------------------------------------------------
   -- INTERNAL - Put Back a Byte, Which was Read
   ------------------------------------------------------------------
   procedure Unget(Obj : in out Recv_Context; Byte : Unsigned_8) is
   begin
      Obj.Unget_Byte := Byte;
   end Unget;

   ------------------------------------------------------------------
   -- Return True if there is Input to Process
   ------------------------------------------------------------------
   function Poll(Obj : Recv_Context) return Boolean is
   begin
      if Obj.Unget_Byte /= No_Cmd then
         return True;
      end if;
      return Obj.Poll_Byte.all;
   end Poll;

   ------------------------------------------------------------------
   -- INTERNAL - Read a MIDI Byte (with Unget)
   ------------------------------------------------------------------
   procedure Read(Obj : in out Recv_Context; Byte : out Unsigned_8) is
   begin
      if Obj.Unget_Byte /= No_Cmd then
         Byte := Obj.Unget_Byte;
         Obj.Unget_Byte := No_Cmd;
      else
         Obj.Read_Byte(Byte);
      end if;
   end Read;

   ------------------------------------------------------------------
   -- INTERNAL - Execute one MIDI message :
   --
   -- Note that for SysEx, only the first 2 bytes have been
   -- fetched (status + Manuf-ID).
   ------------------------------------------------------------------
   procedure Event(Obj : in out Recv_Context; Msg : U8_Array) is
      Cmd :       Unsigned_8 := Msg(0) and 16#F0#;
      Channel :   Channel_Type := Channel_Type( Msg(0) and 16#0F# );
   begin

      case Cmd is
         when MC_NOTE_OFF | MC_NOTE_ON =>
            if Msg'Length /= 3 then
               return;
            end if;

            if Obj.Note_On_Off /= null then
               declare
                  Note :      Note_Type := Note_Type(Msg(1));
                  Velocity :  Velocity_Type := Velocity_Type( Msg(2) );
                  Note_On :   Boolean;
               begin
                  if Cmd = MC_Note_On and then Velocity = 0 then
                     Note_On := False;
                  elsif Cmd = MC_Note_On then
                     Note_On := True;
                  else
                     Note_On := False;
                  end if;
                  Obj.Note_On_Off(Channel,Note,Velocity,Note_On);
               end;
            end if;

         when MC_KEY_PRESSURE =>
            if Msg'Length /= 3 then
               return;
            end if;

            if Obj.Pressure /= null then
               declare
                  Note :      Note_Type := Note_Type(Msg(1));
                  Pressure :  Pressure_Type := Pressure_Type( Msg(2) );
               begin
                  Obj.Pressure(Channel,Note,Pressure);
               end;
            end if;

         when MC_CTL_CHG =>
            if Msg'Length /= 3 then
               return;
            end if;

            declare
               Control :   Control_Type := Control_Type( Msg(1) );
               Value :     Value_Type   := Value_Type( Msg(2) );
            begin
               case Control is
                  when MC_CTL_ALLS_OFF =>
                     if Obj.All_Sounds_Off /= null then
                        Obj.All_Sounds_Off(Channel,Value);
                     end if;

                  when MC_CTL_RESET_C =>
                     if Obj.Reset_Controller /= null then
                        Obj.Reset_Controller(Channel,Value);
                     end if;

                  when MC_CTL_LOCAL_C =>
                     if Obj.Local_Controller /= null then
                        Obj.Local_Controller(Channel,Value);
                     end if;

                  when MC_CTL_ALLN_OFF =>
                     if Obj.All_Notes_Off /= null then
                        Obj.All_Notes_Off(Channel,Value);
                     end if;
                  when MC_CTL_OMNI_OFF | MC_CTL_OMNI_ON =>
                     if Obj.Omni /= null then
                        Obj.Omni(Channel,Value,Control=MC_CTL_OMNI_ON);
                     end if;

                  when MC_CTL_MONO_OFF | MC_CTL_MONO_ON =>
                     if Obj.Mono /= null then
                        Obj.Mono(Channel,Value,Control=MC_CTL_MONO_ON);
                     end if;

                  when others =>
                     if Obj.Unsupported_Control /= null then
                        Obj.Unsupported_Control(Channel,Control,Value);
                     end if;
               end case;
            end;

         when MC_PROGRAM_CHG =>
            if Msg'Length /= 2 then
               return;
            end if;

            if Obj.Program /= null then
               declare
                  Program : Program_Type := Program_Type( Msg(1) );
               begin
                  Obj.Program(Channel,Program);
               end;
            end if;

         when MC_CH_PRESSURE =>      -- Channel pressure change
            if Msg'Length /= 2 then
               return;
            end if;

            if Obj.Channel_Pressure /= null then
               declare
                  Pressure :  Pressure_Type := Pressure_Type( Msg(1) );
               begin
                  Obj.Channel_Pressure(Channel,Pressure);
               end;
            end if;

         when MC_BEND =>             -- Bend (pitch) for channel
            if Msg'Length /= 3 then
               return;
            end if;

            if Obj.Bend /= null then
               declare
                  Signed_Bend :   Integer_16;
               begin
                  Signed_Bend := To_I16(To_U16(Msg(1..2))) - 16#1FFF#;
                  Obj.Bend(Channel,Bend_Type(Signed_Bend));
               end;
            end if;

         when MC_SYS =>              -- System messages
            case Channel is
               when MC_SYS_EX =>   -- System Exclusive
                  if Msg'Length /= 2 then -- There will be additional bytes to be read here
                     return;
                  end if;

                  declare
                     Manufacturer_ID :   Manufacturer_Type := Manufacturer_Type( Msg(1) );
                     Sysex :             U8_Array(0..Obj.Max_Sysex-1);
                     X :                 Unsigned_16 := Sysex'First;
                     Byte :              Unsigned_8 := 0;
                     Truncated :         Boolean := False;
                  begin
                     loop
                        while not Poll(Obj) loop
                           if Obj.Idle /= null then
                              Obj.Idle.all;       -- Invoke idle proc
                           end if;
                        end loop;

                        Read(Obj,Byte);

                        if Byte >= MC_SYS_RT then
                           if Obj.Realtime /= null then
                              Obj.Realtime(Status_Type(Byte and 16#0F#));
                           end if;
                           Byte := No_Cmd;
                        elsif ( Byte and 16#80# ) /= 0 then
                           Unget(Obj,Byte);
                        elsif X <= Sysex'Last then
                           Sysex(X) := Byte;
                           X := X + 1;
                        else
                           Truncated := True;
                        end if;

                        exit when ( Byte and 16#80# ) /= 0;
                     end loop;

                     if Obj.Sysex /= null and then X > Sysex'First then
                        Obj.Sysex(Manufacturer_ID,Sysex(0..X-1),Truncated);
                     end if;
                  end;

               when MC_SYS_RES1 | MC_SYS_RES4 | MC_SYS_RES5 | MC_SYS_RES9 | MC_SYS_RESD =>
                  if Obj.Unsupported /= null then
                     Obj.Unsupported(Msg);
                  end if;

               when MC_SYS_SNGPOS =>
                  if Msg'Length /= 3 then
                     return;
                  end if;

                  if Obj.Song_Pos /= null then
                     declare
                        Beats : Unsigned_16 := To_U16(Msg(1..2));
                     begin
                        Obj.Song_Pos(Beats_Type(Beats));
                     end;
                  end if;

               when MC_SYS_SNGSEL =>
                  if Msg'Length /= 2 then
                     return;
                  end if;

                  if Obj.Song_Selection /= null then
                     declare
                        Song :  Song_Selection_Type := Song_Selection_Type( Msg(1) );
                     begin
                        Obj.Song_Selection(Song);
                     end;
                  end if;

               when MC_SYS_TREQ =>
                  if Msg'Length /= 1 then
                     return;
                  end if;

                  if Obj.Tune_Request /= null then
                     Obj.Tune_Request.all;
                  end if;

               when MC_SYS_ENDX =>
                  null;

               when MC_SYS_TCLK | MC_SYS_START | MC_SYS_CONT | MC_SYS_STOP | MC_SYS_ASENSE | MC_SYS_RESET =>
                  if Msg'Length /= 1 then
                     return;
                  end if;

                  if Obj.Realtime /= null then
                     Obj.Realtime(Status_Type(Channel));
                  end if;
            end case;

         when others =>
            if Obj.Unsupported /= null then
               Obj.Unsupported(Msg);
            end if;
      end case;

   end Event;

   ------------------------------------------------------------------
   -- This is used when no Poll procedure is given
   ------------------------------------------------------------------
   function Surrogate_Poll return Boolean is
   begin
      return True;
   end;

   ------------------------------------------------------------------
   -- Receive a MIDI Message
   ------------------------------------------------------------------
   procedure Receive(Obj : in out Recv_Context; IO : IO_Context; Max_Sysex : Unsigned_16 := 32) is
      Byte :      Unsigned_8;
      B3flag :    Boolean := False;
      FIFO :      U8_Array(0..2);
   begin

      Obj.Read_Byte := IO.Receive_Byte;               -- MIDI Read Routine to Use
      Obj.Poll_Byte := IO.Poll_Byte;                  -- Poll function, if any
      Obj.Max_Sysex := Max_Sysex;                     -- Set limit for SysEx buffer size

      if Obj.Poll_Byte = null then
         Obj.Poll_Byte := Surrogate_Poll'Access;
      end if;

      loop
         ----------------------------------------------------------
         -- Execute the idle function while waiting input
         ----------------------------------------------------------
         while not Poll(Obj) loop
            if Obj.Idle /= null then
               Obj.Idle.all;                       -- Invoke idle proc
            end if;
         end loop;

         Read(Obj,Byte);                             -- Receive one byte

         if ( Byte and 16#80# ) /= 0 then            -- Is this a command (status) byte?
            FIFO(0) := Byte;                        -- Yes, save status byte

            if Byte >= MC_SYS_RT or else Byte = ( MC_SYS or MC_SYS_TREQ ) then
               Event(Obj,FIFO(0..0));              -- Real time message
               return;
            else
               Obj.Running_Status := Byte;         -- same as FIFO(0)
               B3flag := False;                    -- clear flag

               if Byte = MC_SYS_TREQ then
                  Event(Obj,FIFO(0..0));
                  return;
               end if;
            end if;
         elsif not B3flag then                       -- Is this msg byte 2?
                                                     ------------------------------------------------------
                                                     -- Message byte 2 (data)
                                                     ------------------------------------------------------
            if Obj.Running_Status = No_Cmd then
               -- No current running status, so ignore this byte
               null;
            elsif Obj.Running_Status < MC_PROGRAM_CHG then
               -- 3 Byte message (one more to follow)
               B3flag := True;
               FIFO(0) := Obj.Running_Status;
               FIFO(1) := Byte;
            elsif Obj.Running_Status < MC_BEND or else Obj.Running_Status = ( MC_SYS or MC_SYS_EX ) then
               -- 2 byte message (complete)
               FIFO(0) := Obj.Running_Status;
               FIFO(1) := Byte;
               Event(Obj,FIFO(0..1));
               return;
            elsif Obj.Running_Status < MC_SYS then
               -- 3 Byte message (one more to follow)
               B3flag := True;
               FIFO(0) := Obj.Running_Status;
               FIFO(1) := Byte;
            elsif Obj.Running_Status = MC_SYS_SPOS then
               -- 3 Byte message (one more to follow)
               B3flag := True;
               FIFO(0) := Obj.Running_Status;
               FIFO(1) := Byte;
               Obj.Running_Status := No_Cmd;
            elsif Obj.Running_Status = MC_SYS_SSEL or else Obj.Running_Status = ( MC_SYS or MC_SYS_RES1 ) then
               -- 2 Byte message
               FIFO(0) := Obj.Running_Status;
               FIFO(1) := Byte;
               Obj.Running_Status := No_Cmd;
               Event(Obj,FIFO(0..1));
               return;
            else
               --------------------------------------------------
               -- Unsupported status (ignore byte)
               --------------------------------------------------
               FIFO(0)            := No_Cmd;
               Obj.Running_Status := No_Cmd;
            end if;
         else
            ------------------------------------------------------
            -- Byte 3 (data)
            ------------------------------------------------------
            FIFO(2) := Byte;
            Event(Obj,FIFO(0..2));
            B3flag := False;
            return;
         end if;
      end loop;

   end Receive;

   ------------------------------------------------------------------
   -- Callback Registration Procedures (inlined)
   ------------------------------------------------------------------

   procedure Register_Note_On_Off(Obj : in out Recv_Context; Callback : Note_On_Off_Proc) is
   begin
      Obj.Note_On_Off := Callback;
   end;

   procedure Register_Pressure(Obj : in out Recv_Context; Callback : Pressure_Proc) is
   begin
      Obj.Pressure := Callback;
   end;

   procedure Register_All_Sounds_Off(Obj : in out Recv_Context; Callback : Control_Proc) is
   begin
      Obj.All_Sounds_Off := Callback;
   end;

   procedure Register_Reset_Controller(Obj : in out Recv_Context; Callback : Control_Proc) is
   begin
      Obj.Reset_Controller := Callback;
   end;

   procedure Register_Local_Controller(Obj : in out Recv_Context; Callback : Control_Proc) is
   begin
      Obj.Local_Controller := Callback;
   end;

   procedure Register_All_Notes_Off(Obj : in out Recv_Context; Callback : Control_Proc) is
   begin
      Obj.All_Notes_Off := Callback;
   end;

   procedure Register_Omni(Obj : in out Recv_Context; Callback : Omni_Proc) is
   begin
      Obj.Omni := Callback;
   end;

   procedure Register_Mono(Obj : in out Recv_Context; Callback : Mono_Proc) is
   begin
      Obj.Mono := Callback;
   end;

   procedure Register_Unsupported_Control(Obj : in out Recv_Context; Callback : Unsupported_Control_Proc) is
   begin
      Obj.Unsupported_Control := Callback;
   end;

   procedure Register_Program(Obj : in out Recv_Context; Callback : Program_Proc) is
   begin
      Obj.Program := Callback;
   end;

   procedure Register_Channel_Pressure(Obj : in out Recv_Context; Callback : Channel_Pressure_Proc) is
   begin
      Obj.Channel_Pressure := Callback;
   end;

   procedure Register_Bend(Obj : in out Recv_Context; Callback : Bend_Proc) is
   begin
      Obj.Bend := Callback;
   end;

   procedure Register_Sysex(Obj : in out Recv_Context; Callback : Sysex_Proc) is
   begin
      Obj.Sysex := Callback;
   end;

   procedure Register_Unsupported(Obj : in out Recv_Context; Callback : Unsupported_Proc) is
   begin
      Obj.Unsupported := Callback;
   end;

   procedure Register_Song_Pos(Obj : in out Recv_Context; Callback : Song_Position_Proc) is
   begin
      Obj.Song_Pos := Callback;
   end;

   procedure Register_Song_Selection(Obj : in out Recv_Context; Callback : Song_Selection_Proc) is
   begin
      Obj.Song_Selection := Callback;
   end;

   procedure Register_Tune_Request(Obj : in out Recv_Context; Callback : Tune_Request_Proc) is
   begin
      Obj.Tune_Request := Callback;
   end;

   procedure Register_Realtime(Obj : in out Recv_Context; Callback : Realtime_Proc) is
   begin
      Obj.Realtime := Callback;
   end;

   ------------------------------------------------------------------
   -- Register the Idle Procedure
   ------------------------------------------------------------------

   procedure Register_Idle(Obj : in out Recv_Context; Callback : Idle_Proc) is
   begin
      Obj.Idle := Callback;
   end;

   ----------------------------------------------------------------------
   -- Notes From http://www.harmony-central.com/MIDI/Doc/primer.txt
   ----------------------------------------------------------------------
   --
   -- status byte   meaning        data bytes
   --
   -- 0x80-0x8f     note off       2 - 1 byte pitch, followed by 1 byte velocity
   -- 0x90-0x9f     note on        2 - 1 byte pitch, followed by 1 byte velocity
   -- 0xa0-0xaf     key pressure   2 - 1 byte pitch, 1 byte pressure (after-touch)
   -- 0xb0-0xbf     parameter      2 - 1 byte parameter number, 1 byte setting
   -- 0xc0-0xcf     program        1 byte program selected
   -- 0xd0-0xdf     chan. pressure 1 byte channel pressure (after-touch)
   -- 0xe0-0xef     pitch wheel    2 bytes gives a 14 bit value, least significant
   --                                7 bits first
   --
   -- For all of these messages, a convention called the "running
   -- status byte" may be used.  If the transmitter wishes to send
   -- another message of the same type on the same channel, thus
   -- the same status byte, the status byte need not be resent.
   --
   -- Also, a "note on" message with a velocity of zero is to be
   -- synonymous with a "note off".  Combined with the previous
   -- feature, this is intended to allow long strings of notes to
   -- be sent without repeating status bytes.
   --
   -- The pitch bytes of notes are simply number of half-steps,
   -- with middle C = 60.
   --
   -- The pitch wheel value is an absolute setting, 0 - 0x3FFF.  The
   -- 1.0 spec. says that the increment is determined by the receiver.
   -- 0x2000 is to correspond to a centered pitch wheel (unmodified notes)
   --
   -- Now, about those parameter messages.
   --
   -- Instruments are so fundamentally different in the various
   -- controls they have that no attempt was made to define a
   -- standard set, like say 9 for "Filter Resonance".  Instead,
   -- it was simply assumed that these messages allow you to set
   -- "controller" dials, whose purposes are left to the given
   -- device, except as noted below.  The first data bytes
   -- correspond to these "controllers" as follows:
   --
   -- data byte
   --
   -- 0 - 31       continuous controllers 0 - 31, most significant byte
   -- 32 - 63      continuous controllers 0 - 31, least significant byte
   -- 64 - 95      on / off switches
   -- 96 - 121     unspecified, reserved for future.
   -- 122 - 127    the "channel mode" messages I alluded to above.  See below.
   --
   -- The second data byte contains the seven bit setting for the
   -- controller. The switches have data byte 0 = OFF, 127 = ON
   -- with 1 - 126 undefined. If a controller only needs seven
   -- bits of resolution, it is supposed to use the most
   -- significant byte.  If both are needed, the order is
   -- specified as most significant followed by least significant.
   -- With a 14 bit controller, it is to be legal to send only
   -- the least significant byte if the most significant doesn't
   -- need to be changed.
   --
   -- >>
   --  This may of, course, wind up stretched a bit by a given manufacturer.
   --  The Six-Trak, for instance, uses only single byte values (LEFT
   --  justified within the 7 bits at that), and recognizes >32 parameters
   -- <<
   --
   -- Controller number 1 IS standardized to be the modulation wheel.
   --
   -- MODE MESSAGES
   --
   -- These are messages with status bytes 0xb0 through 0xbf, and
   -- leading data bytes 122 - 127.  In reality, these data bytes
   -- function as further opcode data for a group of messages
   -- which control the combination of voices and channels to be
   -- accepted by a receiver.
   --
   -- An important point is that there is an implicit "basic"
   -- channel over which a given device is to receive these
   -- messages.  The receiver is to ignore mode messages over any
   -- other channels, no matter what mode it might be in. The
   -- basic channel for a given device may be fixed or set in some
   -- manner outside the scope of the MIDI standard.
   --
   -- The meaning of the values 122 through 127 is as follows:
   --
   -- data byte                   second data byte
   -- 122       local control     0 = local control off, 127 = on
   -- 123       all notes off     0
   -- 124       omni mode off     0
   -- 125       omni mode on      0
   -- 126       monophonic mode   number of monophonic channels, or 0
   --                             for a number equal to receivers voices
   -- 127       polyphonic mode   0
   --
   -- 124 - 127 also turn all notes off.
   --
   -- Local control refers to whether or not notes played on an instruments
   -- keyboard play on the instrument or not.  With local control off, the
   -- host is still supposed to be able to read input data if desired, as
   -- well as sending notes to the instrument.  Very much like "local echo"
   -- on a terminal, or "half duplex" vs. "full duplex".
   --
   -- The mode setting messages control what channels / how many voices the
   -- receiver recognizes.  The "basic channel" must be kept in mind. "Omni"
   -- refers to the ability to receive voice messages on all channels.  "Mono"
   -- and "Poly" refer to whether multiple voices are allowed.  The rub is
   -- that the omni on/off state and the mono/poly state interact with each
   -- other.  We will go over each of the four possible settings, called "modes"
   -- and given numbers in the specification:
   --
   -- mode 1 - Omni on / Poly - voice messages received on all channels and
   -- assigned polyphonically.  Basically, any notes it gets, it
   -- plays, up to the number of voices it's capable of.
   --
   -- mode 2 - Omni on / Mono - monophonic instrument which will receive
   -- notes to play in one voice on all channels.
   --
   -- mode 3 - Omni off / Poly - polyphonic instrument which will receive
   -- voice messages on only the basic channel.
   --
   -- mode 4 - Omni off / Mono - A useful mode, but "mono" is a misnomer.
   -- To operate in this mode a receiver is supposed to receive
   -- one voice per channel.  The number channels recognized will be
   -- given by the second data byte, or the maximum number of possible
   -- voices if this byte is zero.  The set of channels thus defined
   -- is a sequential set, starting with the basic channel.
   --
   -- The spec. states that a receiver may ignore any mode that it cannot
   -- honor, or switch to an alternate - "usually" mode 1.  Receivers are
   -- supposed to default to mode 1 on power up.  It is also stated that
   -- power up conditions are supposed to place a receiver in a state where
   -- it will only respond to note on / note off messages, requiring a
   -- setting of some sort to enable the other message types.
   --
   -- >>
   -- I think this shows the desire to "daisy-chain" devices for
   -- performance from a single master again.  We can set a series
   -- of instruments to different basic channels, tie 'em together,
   -- and let them pass through the stuff they're not supposed to
   -- play to someone down the line.
   --
   -- This suffers greatly from lack of acknowledgement concerning
   -- modes and usable channels by a receiver.  You basically have
   -- to know your device, what it can do, and what channels it can
   -- do it on.
   --
   -- I think most makers have used the "system exclusive" message
   -- (see below) to handle channels in a more sophisticated manner,
   -- as well as changing "basic channel" and enabling receipt of
   -- different message types under host control rather than by
   -- adjustment on the device alone.
   --
   -- The "parameters" may also be usurped by a manufacturer for
   -- mode control, since their purposes are undefined.
   --
   -- Another HUGE problem with the "daisy-chain" mental set of MIDI
   -- is that most devices ALWAYS shovel whatever they play to their
   -- MIDI outs, whether they got it from the keyboard or MIDI in.
   -- This means that you have to cope with the instrument echoing
   -- input back at you if you're trying to do an interactive session
   -- with the synthesizer.  There is DRASTIC need for some MIDI flag
   -- which specifically means that only locally generated data is to
   -- go to MIDI out.  From device to device there are ways of coping
   -- with this, none of them good.
   -- <<
   --
   -- *************************************************************
   --
   -- The system exclusive message is intended for manufacturers
   -- to use to insert any specific messages they want to which
   -- apply to their own product.  The following data bytes are
   -- all to be "data" bytes, that is they are all to be in the
   -- range 0 - 127.  The system exclusive is to be terminated by
   -- the 0xf7 terminator byte.  The first data byte is also
   -- supposed to be a "manufacturer's id", assigned by a MIDI
   -- standards committee.  THE TERMINATOR BYTE IS OPTIONAL - a
   -- system exclusive may also be "terminated" by the status byte
   -- of the next message.
   --
   -- *************************************************************
   --
   -- REAL TIME MESSAGES.
   --
   -- This is the final group of status bytes, 0xf8 - 0xff.  These bytes
   -- are reserved for messages which are called "real-time" messages
   -- because they are allowed to be sent ANYPLACE.  This includes in
   -- between data bytes of other messages.  A receiver is supposed to
   -- be able to receive and process (or ignore) these messages and
   -- resume collection of the remaining data bytes for the message
   -- which was in progress.  Realtime messages do not affect the
   -- "running status byte" which might be in effect.
   --
   -- ?       Do any devices REALLY insert these things in the middle of
   --         other messages?
   --
   -- All of these messages have no data bytes following (or they could
   -- get interrupted themselves, obviously).  The messages:
   --
   -- 0xf8   timing clock
   -- 0xf9   undefined
   -- 0xfa   start
   -- 0xfb   continue
   -- 0xfc   stop
   -- 0xfd   undefined
   -- 0xfe   active sensing
   -- 0xff   system reset
   --
   -- The timing clock message is to be sent at the rate of 24
   -- clocks per quarter note, and is used to sync. devices,
   -- especially drum machines.
   --
   -- Start / continue / stop are for control of sequencers and
   -- drum machines.  The continue message causes a device to pick
   -- up at the next clock mark.
   --
   -- The active sensing byte is to be sent every 300 ms. or more
   -- often, if it is used.  Its purpose is to implement a timeout
   -- mechanism for a receiver to revert to a default state.  A
   -- receiver is to operate normally if it never gets one of
   -- these, activating the timeout mechanism from the receipt of
   -- the first one.
   --
   -- >>
   --   My impression is that active sensing is largely unused.
   -- <<
   --
   -- The system reset initializes to power up conditions.  The
   -- spec. says that it should be used "sparingly" and in
   -- particular not sent automatically on power up.
   --
   -- ...
   --
   -- Well, that's about it.  Good luck with talking to your synthesizer.
   --
   -- Bob McQueer
   -- 22 Bcy, 3151

end MIDI.Receiver;
