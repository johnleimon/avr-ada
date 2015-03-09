--      Codes for RC5 remote control

-- Eventuell muessen die Codes an die jeweilige
-- Fernbedienung angepasst werden


with Interfaces;                   use Interfaces;

private package RC5.Codes is

   --!
   -- Fernbedienung mit Jog-Dial-Rad,
   -- Achtung: Die Adress-Bits muessen auf die Fernbedienung angepasst werden!
   --/

   JOG_DIAL : constant Boolean := False;


   RC5_TOGGLE     : constant Unsigned_16 := 16#0800#;    --< Das RC5-Toggle-Bit
   RC5_ADDRESS    : constant Unsigned_16 := 16#07C0#;    --< Der Adressbereich
   RC5_COMMAND    : constant Unsigned_16 := 16#103F#;    --< Der Kommandobereich

   RC5_MASK       : constant Unsigned_16 := RC5_COMMAND;
   -- < Welcher Teil des Kommandos wird ausgewertet?


   RC5_CODE_0     : constant Unsigned_16 := 16#3940# and RC5_MASK;   -- Taste 0
   RC5_CODE_1     : constant Unsigned_16 := 16#3941# and RC5_MASK;   -- Taste 1
   RC5_CODE_2     : constant Unsigned_16 := 16#3942# and RC5_MASK;   -- Taste 2
   RC5_CODE_3     : constant Unsigned_16 := 16#3943# and RC5_MASK;   -- Taste 3
   RC5_CODE_4     : constant Unsigned_16 := 16#3944# and RC5_MASK;   -- Taste 4
   RC5_CODE_5     : constant Unsigned_16 := 16#3945# and RC5_MASK;   -- Taste 5
   RC5_CODE_6     : constant Unsigned_16 := 16#3946# and RC5_MASK;   -- Taste 6
   RC5_CODE_7     : constant Unsigned_16 := 16#3947# and RC5_MASK;   -- Taste 7
   RC5_CODE_8     : constant Unsigned_16 := 16#3948# and RC5_MASK;   -- Taste 8
   RC5_CODE_9     : constant Unsigned_16 := 16#3949# and RC5_MASK;   -- Taste 9

   RC5_CODE_UP    : constant Unsigned_16 := 16#2950# and RC5_MASK;   -- Taste Hoch
   RC5_CODE_DOWN  : constant Unsigned_16 := 16#2951# and RC5_MASK;   -- Taste Runter
   RC5_CODE_LEFT  : constant Unsigned_16 := 16#2955# and RC5_MASK;   -- Taste Links
   RC5_CODE_RIGHT : constant Unsigned_16 := 16#2956# and RC5_MASK;   -- Taste Rechts

   RC5_CODE_PWR   : constant Unsigned_16 := 16#394C# and RC5_MASK;   -- Taste An/Aus


   -- Jogdial geht nur inkl. Adresscode
   JD_MASK : constant Unsigned_16 := RC5_COMMAND or RC5_ADDRESS;

   --
   RC5_CODE_JOG_MID : constant Unsigned_16 := 16#3969# and JD_MASK; -- Jd Mitte
   RC5_CODE_JOG_L1  : constant Unsigned_16 := 16#3962# and JD_MASK; -- Jd Links 1
   RC5_CODE_JOG_L2  : constant Unsigned_16 := 16#396F# and JD_MASK; -- Jd Links 2
   RC5_CODE_JOG_L3  : constant Unsigned_16 := 16#395F# and JD_MASK; -- Jd Links 3
   RC5_CODE_JOG_L4  : constant Unsigned_16 := 16#3A6C# and JD_MASK; -- Jd Links 4
   RC5_CODE_JOG_L5  : constant Unsigned_16 := 16#3A6B# and JD_MASK; -- Jd Links 5
   RC5_CODE_JOG_L6  : constant Unsigned_16 := 16#396C# and JD_MASK; -- Jd Links 6
   RC5_CODE_JOG_L7  : constant Unsigned_16 := 16#3A6A# and JD_MASK; -- Jd Links 7

   RC5_CODE_JOG_R1  : constant Unsigned_16 := 16#3968# and JD_MASK; -- Jd Rechts 1
   RC5_CODE_JOG_R2  : constant Unsigned_16 := 16#3975# and JD_MASK; -- Jd Rechts 2
   RC5_CODE_JOG_R3  : constant Unsigned_16 := 16#396A# and JD_MASK; -- Jd Rechts 3
   RC5_CODE_JOG_R4  : constant Unsigned_16 := 16#3A6D# and JD_MASK; -- Jd Rechts 4
   RC5_CODE_JOG_R5  : constant Unsigned_16 := 16#3A6E# and JD_MASK; -- Jd Rechts 5
   RC5_CODE_JOG_R6  : constant Unsigned_16 := 16#396E# and JD_MASK; -- Jd Rechts 6
   RC5_CODE_JOG_R7  : constant Unsigned_16 := 16#3A6F# and JD_MASK; -- Jd Rechts 7

end RC5.Codes;
