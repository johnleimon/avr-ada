-- midi.ads - Thu Aug 12 18:55:41 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: midi.ads,v 1.1 2010-08-25 01:09:15 Warren Gray Exp $
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

----------------------------------------------------------------------
-- This module implements Top Level for MIDI I/O
----------------------------------------------------------------------

with Interfaces;                   use Interfaces;

package MIDI is
   pragma Pure;

   ------------------------------------------------------------------
   -- MIDI Data Types
   ------------------------------------------------------------------

   type Note_Type          is new Unsigned_8   range 0..127;
   type Channel_Type       is new Unsigned_8   range 0..15;
   type Velocity_Type      is new Unsigned_8   range 0..127;
   type Pressure_Type      is new Unsigned_8   range 0..127;
   type Control_Type       is new Unsigned_8   range 0..127;
   type Value_Type         is new Unsigned_8   range 0..127;
   type Program_Type       is new Unsigned_8   range 0..127;

   type Bend_Type          is                  range -2**14 .. 2**14;
   for Bend_Type'Size      use 16;

   type Manufacturer_Type  is new Unsigned_8   range 0..127;
   type Beats_Type         is new Unsigned_16  range 0..2**14;
   type Song_Selection_Type is new Unsigned_8  range 0..127;
   type Status_Type        is new Unsigned_8;

   type U8_Array is array (Unsigned_16 range <>) of Unsigned_8;
   for U8_Array'Component_Size use 8;

   ------------------------------------------------------------------
   -- I/O Procedures Used by MIDI
   ------------------------------------------------------------------

   type Read_Byte_Proc    is access
     procedure (Byte : out Unsigned_8);

   type Poll_Byte_Proc    is access
     function return Boolean;            -- Return True when Input available

   type Write_Byte_Proc   is access
     procedure (Byte : in  Unsigned_8);

   type Idle_Proc         is access
     procedure;

   ------------------------------------------------------------------
   -- Initialization for MIDI I/O
   ------------------------------------------------------------------

   type IO_Context is private;

   procedure Initialize(
                        Context :       in out  IO_Context;
                        Receiver :      in      Read_Byte_Proc := null;
                        Transmitter :   in      Write_Byte_Proc := null;
                        Poll :          in      Poll_Byte_Proc := null
                       );

   ------------------------------------------------------------------
   -- Compute a Serial Port Divisor for a MIDI Baud Rate
   ------------------------------------------------------------------

   Standard_Baud_Rate :        constant := 31250;   -- Midi baud rate

   function MIDI_Baud_Rate_Divisor(CPU_Clock_Freq : Unsigned_32) return Unsigned_16;

   ------------------------------------------------------------------
   -- MIDI Commands
   ------------------------------------------------------------------

   MC_NOTE_OFF :       constant := 16#80#;  -- Note off request
   MC_NOTE_ON :        constant := 16#90#;  -- Note on request
   MC_KEY_PRESSURE :   constant := 16#A0#;  -- Key pressure (AfterTouch)
   MC_CTL_CHG :        constant := 16#B0#;  -- Control change
   MC_PROGRAM_CHG :    constant := 16#C0#;  -- Program change
   MC_CH_PRESSURE :    constant := 16#D0#;  -- Channel pressure change
   MC_BEND :           constant := 16#E0#;  -- Bend (for channel)
   MC_SYS :            constant := 16#F0#;  -- System message

   ------------------------------------------------------------------
   -- MC_CTL_CHG Control values :
   ------------------------------------------------------------------

   MC_CTL_ALLS_OFF :   constant := 16#78#;  -- All sounds off (120)
   MC_CTL_RESET_C :    constant := 16#79#;  -- Reset controller
   MC_CTL_LOCAL_C :    constant := 16#7A#;  -- Local on/off
   MC_CTL_ALLN_OFF :   constant := 16#7B#;  -- All notes off
   MC_CTL_OMNI_OFF :   constant := 16#7C#;  -- Omni off request
   MC_CTL_OMNI_ON :    constant := 16#7D#;  -- Omni on request
   MC_CTL_MONO_ON :    constant := 16#7E#;  -- Mono on == POLY OFF
   MC_CTL_MONO_OFF :   constant := 16#7F#;  -- Mono off == POLY ON

   ------------------------------------------------------------------
   -- MC_SYS "channel" op codes :
   ------------------------------------------------------------------

   MC_SYS_EX :         constant := 16#00#;  -- Sys Ex transfer
   MC_SYS_RES1 :       constant := 16#01#;  -- Reserved
   MC_SYS_SNGPOS :     constant := 16#02#;  -- Song position
   MC_SYS_SNGSEL :     constant := 16#03#;  -- Song selection
   MC_SYS_RES4 :       constant := 16#04#;  -- Reserved
   MC_SYS_RES5 :       constant := 16#05#;  -- Reserved
   MC_SYS_TREQ :       constant := 16#06#;  -- Tune Request
   MC_SYS_ENDX :       constant := 16#07#;  -- End SysEx transfer
   MC_SYS_TCLK :       constant := 16#08#;  -- RT - Clock
   MC_SYS_RES9 :       constant := 16#09#;  -- RT - Reserved
   MC_SYS_START :      constant := 16#0A#;  -- RT - Start
   MC_SYS_CONT :       constant := 16#0B#;  -- RT - Continue
   MC_SYS_STOP :       constant := 16#0C#;  -- RT - Stop
   MC_SYS_RESD :       constant := 16#0D#;  -- RT - Reserved
   MC_SYS_ASENSE :     constant := 16#0E#;  -- RT - Active Sense
   MC_SYS_RESET :      constant := 16#0F#;  -- RT - Reset

   ------------------------------------------------------------------
   -- Some Combined MC_SYS values for convenience :
   ------------------------------------------------------------------

   MC_SYS_EX_END :     constant := 16#F7#;  -- (MC_SYS|MC_SYS_ENDX)
   MC_SYS_RT :         constant := 16#F8#;  -- (MC_SYS|MC_SYS_TCLK)
   MC_SYS_SPOS :       constant := 16#F2#;  -- (MC_SYS|MC_SYS_SNGPOS)
   MC_SYS_SSEL :       constant := 16#F3#;  -- (MC_SYS|MC_SYS_SNGSEL)

   ------------------------------------------------------------------
   -- MIDI Note Values
   ------------------------------------------------------------------
   C_0 :           constant := 12;
   C_Sharp_0 :     constant := 13;
   D_Flat_0 :      constant := 13;
   D_0 :           constant := 14;
   D_Sharp_0 :     constant := 15;
   E_Flat_0 :      constant := 15;
   E_0 :           constant := 16;
   F_0 :           constant := 17;
   F_Sharp_0 :     constant := 18;
   G_Flat_0 :      constant := 18;
   G_0 :           constant := 19;
   G_Sharp_0 :     constant := 20;
   A_Flat_0 :      constant := 20;
   A_0 :           constant := 21;
   A_Sharp_0 :     constant := 22;
   B_Flat_0 :      constant := 22;
   B_0 :           constant := 23;
   C_1 :           constant := 24;
   C_Sharp_1 :     constant := 25;
   D_Flat_1 :      constant := 25;
   D_1 :           constant := 26;
   D_Sharp_1 :     constant := 27;
   E_Flat_1 :      constant := 27;
   E_1 :           constant := 28;
   F_1 :           constant := 29;
   F_Sharp_1 :     constant := 30;
   G_Flat_1 :      constant := 30;
   G_1 :           constant := 31;
   G_Sharp_1 :     constant := 32;
   A_Flat_1 :      constant := 32;
   A_1 :           constant := 33;
   A_Sharp_1 :     constant := 34;
   B_Flat_1 :      constant := 34;
   B_1 :           constant := 35;
   C_2 :           constant := 36;
   C_Sharp_2 :     constant := 37;
   D_Flat_2 :      constant := 37;
   D_2 :           constant := 38;
   D_Sharp_2 :     constant := 39;
   E_Flat_2 :      constant := 39;
   E_2 :           constant := 40;
   F_2 :           constant := 41;
   F_Sharp_2 :     constant := 42;
   G_Flat_2 :      constant := 42;
   G_2 :           constant := 43;
   G_Sharp_2 :     constant := 44;
   A_Flat_2 :      constant := 44;
   A_2 :           constant := 45;
   A_Sharp_2 :     constant := 46;
   B_Flat_2 :      constant := 46;
   B_2 :           constant := 47;
   C_3 :           constant := 48;
   C_Sharp_3 :     constant := 49;
   D_Flat_3 :      constant := 49;
   D_3 :           constant := 50;
   D_Sharp_3 :     constant := 51;
   E_Flat_3 :      constant := 51;
   E_3 :           constant := 52;
   F_3 :           constant := 53;
   F_Sharp_3 :     constant := 54;
   G_Flat_3 :      constant := 54;
   G_3 :           constant := 55;
   G_Sharp_3 :     constant := 56;
   A_Flat_3 :      constant := 56;
   A_3 :           constant := 57;
   A_Sharp_3 :     constant := 58;
   B_Flat_3 :      constant := 58;
   B_3 :           constant := 59;
   C_4 :           constant := 60;
   C_Sharp_4 :     constant := 61;
   D_Flat_4 :      constant := 61;
   D_4 :           constant := 62;
   D_Sharp_4 :     constant := 63;
   E_Flat_4 :      constant := 63;
   E_4 :           constant := 64;
   F_4 :           constant := 65;
   F_Sharp_4 :     constant := 66;
   G_Flat_4 :      constant := 66;
   G_4 :           constant := 67;
   G_Sharp_4 :     constant := 68;
   A_Flat_4 :      constant := 68;
   A_4 :           constant := 69;
   A_Sharp_4 :     constant := 70;
   B_Flat_4 :      constant := 70;
   B_4 :           constant := 71;
   C_5 :           constant := 72;
   C_Sharp_5 :     constant := 73;
   D_Flat_5 :      constant := 73;
   D_5 :           constant := 74;
   D_Sharp_5 :     constant := 75;
   E_Flat_5 :      constant := 75;
   E_5 :           constant := 76;
   F_5 :           constant := 77;
   F_Sharp_5 :     constant := 78;
   G_Flat_5 :      constant := 78;
   G_5 :           constant := 79;
   G_Sharp_5 :     constant := 80;
   A_Flat_5 :      constant := 80;
   A_5 :           constant := 81;
   A_Sharp_5 :     constant := 82;
   B_Flat_5 :      constant := 82;
   B_5 :           constant := 83;
   C_6 :           constant := 84;
   C_Sharp_6 :     constant := 85;
   D_Flat_6 :      constant := 85;
   D_6 :           constant := 86;
   D_Sharp_6 :     constant := 87;
   E_Flat_6 :      constant := 87;
   E_6 :           constant := 88;
   F_6 :           constant := 89;
   F_Sharp_6 :     constant := 90;
   G_Flat_6 :      constant := 90;
   G_6 :           constant := 91;
   G_Sharp_6 :     constant := 92;
   A_Flat_6 :      constant := 92;
   A_6 :           constant := 93;
   A_Sharp_6 :     constant := 94;
   B_Flat_6 :      constant := 94;
   B_6 :           constant := 95;
   C_7 :           constant := 96;
   C_Sharp_7 :     constant := 97;
   D_Flat_7 :      constant := 97;
   D_7 :           constant := 98;
   D_Sharp_7 :     constant := 99;
   E_Flat_7 :      constant := 99;
   E_7 :           constant := 100;
   F_7 :           constant := 101;
   F_Sharp_7 :     constant := 102;
   G_Flat_7 :      constant := 102;
   G_7 :           constant := 103;
   G_Sharp_7 :     constant := 104;
   A_Flat_7 :      constant := 104;
   A_7 :           constant := 105;
   A_Sharp_7 :     constant := 106;
   B_Flat_7 :      constant := 106;
   B_7 :           constant := 107;
   C_8 :           constant := 108;
   C_Sharp_8 :     constant := 109;
   D_Flat_8 :      constant := 109;
   D_8 :           constant := 110;
   D_Sharp_8 :     constant := 111;
   E_Flat_8 :      constant := 111;

private

   ------------------------------------------------------------------
   -- I/O Context Object
   ------------------------------------------------------------------
   type IO_Context is
      record
         Receive_Byte :  Read_Byte_Proc;
         Poll_Byte :     Poll_Byte_Proc;
         Transmit_Byte : Write_Byte_Proc;
      end record;

   No_Cmd :            constant := 16#00#; -- Indicates no status byte in running status

end MIDI;
