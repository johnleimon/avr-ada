--  Title:    Accessing variable stored in flash program memory of AVR
--  Author:   Rolf Ebert <rolf.ebert.gcc@gmx.de>
--  Date:     30-Aug-2008
--  Software: AVR-GCC 4.3
--            AVR-Ada 0.6, gcc-4.3
--  Hardware: AT90S8515 (4Mhz), any AVR device can be used (P.Fleury)
--            AVR-Butterfly (ATmega169) (R. Ebert)
--
--  Program description:
--  This example explains how global constants can be read from
--  program memory.
--

with Interfaces;                   use type Interfaces.Unsigned_8;
with AVR;                          use AVR;
with AVR.MCU;
with AVR.Programspace;             use AVR.Programspace;

with Progmem_Vars;                 use Progmem_Vars;

procedure Test_Progmem is

   State2_Var : Nat16;
   Element    : Nat8;

begin
   MCU.DDRB_Bits := (others => DD_Output); -- use all pins on port B for output
   MCU.PORTB := 16#FF#;

   -- read variable from flash and output inverted value to port B
   MCU.PORTB := not Programspace.Get (State1'Address);

   -- read 16 bit variable from flash
   State2_Var := Programspace.Get (State2'Address);
   -- output lower byte (3) inverted to port B
   MCU.PORTB := not Low_Byte (State2_Var);


   for I in Const_Array'Range loop
      Element := Programspace.Get (Const_Array (I)'Address);
      MCU.PORTB := not Element;
   end loop;

   loop null; end loop;

end Test_Progmem;
