--      Kommando-Management


with Ada.Unchecked_Conversion;
with Ada.Streams;

with AVR.Int_Img;
with Debug;

with LED;
--  #include "uart.h"
--  #include "adc.h"

--  #include "display.h"

with Sensors;
--  #include "motor.h"
with RC5.IR;
--  #include "bot-logik.h"

--  #if PC
with TCP;
--  #end if


package body Commands is


   function To_Cmd_Code is new Ada.Unchecked_Conversion
     (Source => Ada.Streams.Stream_Element,
      Target => Commands.Cmd_Code);



   --  protection of the local command buffer against simultaneous
   --  access.
   protected Prot_Cmd is
      function Get return Command_T;
      procedure Set (New_Cmd : Command_T);
   private
      Inner_Cmd : Command_T;
   end Prot_Cmd;


   protected body Prot_Cmd is

      function Get return Command_T is
      begin
         return Inner_Cmd;
      end Get;

      procedure Set (New_Cmd : Command_T) is
      begin
         Inner_Cmd := New_Cmd;
      end Set;

   end Prot_Cmd;


   function Received return Command_T
   is
   begin
      return Prot_Cmd.Get;
   end Received;



   --!
   -- Wertet das Kommando im Puffer aus
   -- return 1, wenn Kommando schon bearbeitet wurde, 0 sonst
   --/
   procedure Evaluate
   is
      Cmd : constant Command_T := Prot_Cmd.Get;
   begin
      case Cmd.Request.Command is

      when CMD_AKT_LED =>       -- LED-Steuerung
         LED.Set (Unsigned_8 (Cmd.Data_L));

      when CMD_SENS_IR =>
         Sensors.Dist_L := Cmd.Data_L;
         Sensors.Dist_R := Cmd.Data_R;

      when CMD_SENS_ENC =>
         Sensors.Enc_L := Sensors.Enc_L + Cmd.Data_L;
         Sensors.Enc_R := Sensors.Enc_R + Cmd.Data_R;

      when CMD_SENS_BORDER =>
         Sensors.Border_L := Cmd.Data_L;
         Sensors.Border_R := Cmd.Data_R;

      when CMD_SENS_LINE =>
         Sensors.Line_L := Cmd.Data_L;
         Sensors.Line_R := Cmd.Data_R;

      when CMD_SENS_LDR =>
         Sensors.Ldr_L := Cmd.Data_L;
         Sensors.Ldr_R := Cmd.Data_R;

      when CMD_SENS_TRANS =>
         if Cmd.Data_L = 0 then
            Sensors.Trans := Sensors.Open;
         else
            Sensors.Trans := Sensors.Closed;
         end if;

      when CMD_SENS_ERROR =>
         Sensors.Error := Integer_8 (Cmd.Data_L);

      when CMD_SENS_RC5 =>
         RC5.IR.Data := Unsigned_16 (Cmd.Data_L);

      when others =>
         null;
      end case;
   end Evaluate;


   --!
   -- Liest ein Kommando ein, ist blockierend!
   --/
   function Read return Boolean
   is
      --  the input channel is either a TCP socket on the host
      --  for simulation, on the target board it might be a serial
      --  connection during development
      -- Channel : Ada.Streams.Stream_IO.Stream_Access renames
        --  #if PC
 --        TCP.Channel;
      --  #else
      --     UART.Channel;
      --  #endif

      Cmd : Command_T;

      subtype Cmd_Stream_Elems_Array is Ada.Streams.Stream_Element_Array (1 .. 11);
      Cmd_As_U8 : Cmd_Stream_Elems_Array;
      for Cmd_As_U8'Address use Cmd'Address;

      Start : Ada.Streams.Stream_Element_Array renames Cmd_As_U8 (1 .. 1);

      Last : Ada.Streams.Stream_Element_Offset;

   begin  -- Read

      --  Debug.Put_Line ("entered Commands.Read");

      --  read until the first start code is found
      loop
         TCP.Read (Start, Last);
         exit when To_Cmd_Code (Start (1)) = CMD_STARTCODE;
         Debug.Put (".");
      end loop;


      --  read the remaining bytes of the command structure
      TCP.Read (Cmd_As_U8 (2 .. 11), Last);

      Debug.Put ("rec: ");
      --  for I in Cmd_As_U8'Range loop
      --     Debug.Put (Cmd_As_U8 (I)); Debug.Put (' ');
      --  end loop;
      --  Debug.New_Line;

      Debug.Put_Line (Image (Cmd));

      --  validate (startcode is already ok, or we won't be here)
      if Cmd.CRC /= CMD_STOPCODE then
         return False;
      end if;

      --  store the received command in the buffer
      Prot_Cmd.Set (Cmd);

      return True;

   end Read;


   --
   -- return an explaining name for a  command code
   --
   function Long_Name (C : Cmd_Code) return AVR.Strings.AVR_String
   is
   begin
      case C is
      --
      --  Start/Stop codes
      --
      when CMD_STARTCODE =>
         return "Startcode";
      when CMD_STOPCODE =>
         return "Stopcode";
      --
      --  Sensoren
      --
      when CMD_SENS_IR =>
         return "S_Distance";
      when CMD_SENS_ENC =>
         return "S_Encoder";
      when CMD_SENS_BORDER =>
         return "S_Border";
      when CMD_SENS_LINE =>
         return "S_Line";
      when CMD_SENS_LDR =>
         return "S_LDR";
      when CMD_SENS_TRANS =>
         return "S_Transport_Box";
      when CMD_SENS_DOOR =>
         return "S_Door";
      when CMD_SENS_MOUSE =>
         return "S_Mouse";
      when CMD_SENS_ERROR =>
         return "S_Error";
      when CMD_SENS_RC5 =>
         return "S_Remote_Control";
      --
      --  Aktuatoren
      --
      when CMD_AKT_MOT =>
         return "A_Motor";
      when CMD_AKT_DOOR =>
         return "A_Door";
      when CMD_AKT_SERVO =>
         return "A_Servo";
      when CMD_AKT_LED =>
         return "A_LED";
      when CMD_AKT_LCD =>
         return "A_LCD";
      when others =>
         return " ";
      end case;
   end Long_Name;


   --!
   --  format a command as human readable text for screen display
   --/
   function Image (Cmd : Command_T) return AVR.Strings.AVR_String
   is
      use AVR.Strings;

      Seq_Str    : AStr5;
      Data_L_Str : AStr5;
      -- Data_R_Str : AStr5;
      Tmp : Unsigned_16;

      Start_T  : constant AVR_String := "Start:" & Character'Val (Cmd.Start_Code);
      Cmd_T    : constant AVR_String := "Cmd:"   & Character'Val (Cmd.Request.Command)
                                        & " " & Long_Name (Cmd.Request.Command);
      SCmd_T   : constant AVR_String := "SCmd:"  & Character'Val (Cmd.Request.Subcommand);
      Data_L_T : constant AVR_String := "Data_L:";
      -- Data_R_T : constant AVR_String := "Data_R:";
      Seq_T    : constant AVR_String := "Seq:";
      CRC_t    : constant AVR_String := "CRC:"   & Character'Val (Cmd.CRC);

   begin
      AVR.Int_Img.U16_Img (Cmd.Seq, Seq_Str);

      if Cmd.Data_L < 0 then
         Tmp := Unsigned_16 (- Cmd.Data_L);
      else
         Tmp := Unsigned_16 (Cmd.Data_L);
      end if;
      AVR.Int_Img.U16_Img (Tmp, Data_L_Str);

      AVR.Int_Img.U16_Img (Cmd.Seq, Seq_Str);


      return Start_T & ' ' & Cmd_T & ' ' & SCmd_T & ' '
        & Data_L_T & Data_L_Str & ' ' & Seq_T & Seq_Str & ' ' & CRC_T;

      --  short form, only command, data, and seq
      --  return  Cmd_T & ' ' & Data_L_T & Data_L_Str & ' ' & Seq_T & Seq_Str;
   end Image;


end Commands;
