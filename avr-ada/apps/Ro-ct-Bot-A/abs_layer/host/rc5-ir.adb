--      Routinen fuer die Dekodierung von RC5-Fernbedienungs-Codes


package body RC5.IR is

   -- !
   -- IR-Daten lesen
   -- @return Wert von Data, loescht anschlieﬂend Data
   -- /
   function Read return Unsigned_16
   is
      Retvalue : Unsigned_16 := data;
   begin
      Data := 0;
      return Retvalue;
   end Read;

   --  !
   --   Init IR-System
   --  /
   procedure Init is
   begin
      null;
   end Init;

end RC5.IR;
