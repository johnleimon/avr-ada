--  Kommando-Management


with Interfaces;                   use Interfaces;
with AVR.Strings;


package Commands is


   type Direction_T is (Request, Answer);

   subtype Cmd_Code is Unsigned_8 range 0 .. 127;

   --!
   -- Request Teil eines Kommandos
   --/
   type Request_T is record
      Command    : Cmd_Code;
      Subcommand : Cmd_Code;
      Direction  : Direction_T;
   end record;

   --!
   -- Kommando
   --/
   type Command_T is record
      Start_Code : Cmd_Code;       --/< Markiert den Beginn eines Commands
      Request    : Request_T;      --/< Command-ID
      Payload    : Unsigned_8;     --/< Bytes, die dem Kommando noch folgen
      Data_L     : Integer_16;     --/< Daten zum Kommando links
      Data_R     : Integer_16;     --/< Daten zum Kommando rechts
      Seq        : Unsigned_16;    --/< Paket-Sequenznummer
      CRC        : Cmd_Code;       --/< Markiert das Ende des Commands
   end record;


   --
   --  Start/Stop codes
   --

   --/< Anfang eines Kommandos, 62
   CMD_STARTCODE   : constant Cmd_Code := Character'Pos ('>');
   --/< Ende eines Kommandos, 60
   CMD_STOPCODE    : constant Cmd_Code := Character'Pos ('<');


   --
   --  Sensoren
   --

   --/< Abstandssensoren
   CMD_SENS_IR     : constant Cmd_Code := Character'Pos ('I');
   --/< Radencoder
   CMD_SENS_ENC    : constant Cmd_Code := Character'Pos ('E');
   --/< Abgrundsensoren
   CMD_SENS_BORDER : constant Cmd_Code := Character'Pos ('B');
   --/< Liniensensoren
   CMD_SENS_LINE   : constant Cmd_Code := Character'Pos ('L');
   --/< Helligkeitssensoren
   CMD_SENS_LDR    : constant Cmd_Code := Character'Pos ('H');
   --/< Ueberwachung Transportfach
   CMD_SENS_TRANS  : constant Cmd_Code := Character'Pos ('T');
   --/< Ueberwachung Klappe
   CMD_SENS_DOOR   : constant Cmd_Code := Character'Pos ('D');
   --/< Maussensor
   CMD_SENS_MOUSE  : constant Cmd_Code := Character'Pos ('m');
   --/< Motor- oder Batteriefehler
   CMD_SENS_ERROR  : constant Cmd_Code := Character'Pos ('e');
   --/< IR-Fernbedienung, 82
   CMD_SENS_RC5    : constant Cmd_Code := Character'Pos ('R');


   --
   --  Aktuatoren
   --

   --/< Motorgeschwindigkeit, 77
   CMD_AKT_MOT     : constant Cmd_Code := Character'Pos ('M');
   --/< Steuerung Klappe, 100
   CMD_AKT_DOOR    : constant Cmd_Code := Character'Pos ('d');
   --/< Steuerung Servo, 83
   CMD_AKT_SERVO   : constant Cmd_Code := Character'Pos ('S');
   --/< LEDs steuern, 108
   CMD_AKT_LED     : constant Cmd_Code := Character'Pos ('l');
   --/< LCD Anzeige
   CMD_AKT_LCD     : constant Cmd_Code := Character'Pos ('c');


   --
   --  Subcommands
   --

   --/< Standard-Kommando, 78
   SUB_CMD_NORM    : constant Cmd_Code := Character'Pos ('N');
   --/< Kommmando fuer links, 76
   SUB_CMD_LEFT    : constant Cmd_Code := Character'Pos ('L');
   --/< Kommando fuer rechts, 82
   SUB_CMD_RIGHT   : constant Cmd_Code := Character'Pos ('R');

   --/< Subkommando Clear Screen
   SUB_LCD_CLEAR   : constant Cmd_Code := Character'Pos ('c');
   --/< Subkommando Text ohne Cursor
   SUB_LCD_DATA    : constant Cmd_Code := Character'Pos ('D');
   --/< Subkommando Cursorkoordinaten
   SUB_LCD_CURSOR  : constant Cmd_Code := Character'Pos ('C');


   --  make Received_Command a protected object to protect against
   --  uncontrolled access from different threads on the PC.  It is
   --  read only at the HAL in any way
   function Received return Command_T;


   --!
   -- Liest ein Kommando ein, ist blockierend!
   --  succesful reception of a command returns True;
   --/
   function Read return Boolean;


   --!
   -- Wertet das Kommando im Puffer aus
   --/
   procedure Evaluate;

   --
   -- return an explaining name for a  command code
   --
   function Long_Name (C : Cmd_Code) return AVR.Strings.AVR_String;

   --!
   -- Gibt ein Kommando als lesbaren Text für Bildschirmausgabe zurück
   --/
   function Image (Cmd : Command_T) return AVR.Strings.AVR_String;


private

   --
   --  specify layout of the types
   --

   for Request_T use record
      Command     at 0 range 0 ..  7;
      Subcommand  at 1 range 0 ..  6;
      Direction   at 1 range 7 ..  7;
   end record;
   for Request_T'Size use 16;


   for Command_T use record
      Start_Code at  0 range 0 ..  7;
      Request    at  1 range 0 .. 15;
      Payload    at  3 range 0 ..  7;
      Data_L     at  4 range 0 .. 15;
      Data_R     at  6 range 0 .. 15;
      Seq        at  8 range 0 .. 15;
      CRC        at 10 range 0 ..  7;
   end record;
   for Command_T'Size use 88;

end Commands;
