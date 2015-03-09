--
--   interface package for using U. Radig's driver
--

with AVR;                          use AVR;
with AVR.MCU;                      use AVR.MCU;

package body NIC is


#if MCU = "atmega32" then
   ETH_Interrupt_Bit : Boolean renames GICR_Bits (INT2_Bit);
#elsif MCU = "atmega644" or else MCU = "atmega644p" then
   ETH_Interrupt_Bit : Boolean renames EIMSK_Bits (INT2_Bit);
#end if;

   procedure C_Send_Packet (Len : Base_Buffer_Range; Buf : MTU_Storage);
   pragma Import (C, C_Send_Packet, "enc28j60_send_packet");

   procedure Send_Packet (Len : Base_Buffer_Range; Buf : MTU_Storage)
   is
   begin
      Net.Buffer.Debug_Put (Buf (1..Len));
      C_Send_Packet (Len, Buf);
   end Send_Packet;


   procedure Enable_ETH_Interrupt
   is
   begin
      ETH_Interrupt_Bit := True;
   end Enable_ETH_Interrupt;


   procedure Disable_ETH_Interrupt
   is
   begin
      ETH_Interrupt_Bit := False;
   end Disable_ETH_Interrupt;


   function Data_Available return Boolean
   is
   begin
      return (PINB_Bits (2) = Low);
   end Data_Available;


   Fake_Buf : constant MTU_Storage := (others => 0);

   procedure Init is
   begin
      ENC28J60_Init;

      Send_Packet (60, Fake_Buf);
      Send_Packet (60, Fake_Buf);
   end Init;

end NIC;
