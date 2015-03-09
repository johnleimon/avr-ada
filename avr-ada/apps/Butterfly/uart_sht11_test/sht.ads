with AVR;                   use AVR;

package SHT is
   pragma Preelaborate (SHT);


   type Mode_Type is (Temperature, Humidity);

   type Error_Code is (OK, No_Ack_Error, Timeout_Error, Error);


   package Commands is
      --                                    adr cmd r/w
      Write_Status_Register : constant := 2#000_0011_0#;
      Read_Status_Register  : constant := 2#000_0011_1#;
      Measure_Temperature   : constant := 2#000_0001_1#;
      Measure_Humidity      : constant := 2#000_0010_1#;
      Soft_Reset            : constant := 2#000_1111_0#;
   end Commands;


   --  initialize all necessary pins
   procedure Init;


   --  writes a byte on the Sensibus and checks the acknowledge
   procedure Write_Byte (Value : in  Nat8;
                         E     : out Error_Code);


   --  reads a byte form the Sensibus and gives an acknowledge in case
   --  of "ack=1"
   function Read_Byte (Send_Ack : Boolean) return Nat8;


   --  generate a transmission start
   --        _____         ________
   --  DATA:      |_______|
   --            ___     ___
   --  SCK : ___|   |___|   |______
   --
   procedure Transmission_Start;


   --  communication reset: DATA-line=1 and at least 9 SCK cycles
   --  followed by Transmission_Start
   --       ____________________________________________________         _____
   -- DATA:                                                     |_______|
   --          _    _    _    _    _    _    _    _    _       ___     ___
   -- SCK : __| |__| |__| |__| |__| |__| |__| |__| |__| |_____|   |___|   |___
   procedure Connection_Reset;


   -- resets the sensor by a softreset
   procedure Soft_Reset (E : out Error_Code);


   -- reads the status register with checksum (8-bit)
   procedure Read_Statusreg (Status   : out Nat8;
                             Checksum : out Nat8;
                             E        : out Error_Code);


   -- Writes the status register with checksum (8-bit)
   procedure Write_Statusreg (Status : in Nat8;
                             E      : out Error_Code);


   -- makes a measurement (humidity/temperature) with checksum
   procedure Measure (Raw_Value : out Nat16;
                      Checksum  : out Nat8;
                      Mode      : in  Mode_Type;
                      E         : out Error_Code);

end SHT;
