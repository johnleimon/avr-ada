--
--   interface package for using U. Radig's driver
--

with Net.Buffer;                   use Net.Buffer;

package NIC is
--   pragma Pure;

   procedure Init;

   procedure Send_Packet (Len : Base_Buffer_Range; Buf : MTU_Storage);

   --  return length of received packet
   function Receive_Packet (Size : Base_Buffer_Range; Buf : MTU_Storage)
                           return Base_Buffer_Range;

   procedure Enable_ETH_Interrupt;
   procedure Disable_ETH_Interrupt;

   function Data_Available return Boolean;
private
   procedure Enc28j60_Init;
   pragma Import (C, Enc28j60_Init, "enc28j60_init");
   -- pragma Import (C, Init, "stack_init");
   pragma Import (C, Receive_Packet, "enc28j60_receive_packet");
   pragma Inline (Enable_ETH_Interrupt);
   pragma Inline (Disable_ETH_Interrupt);
   pragma Inline (Data_Available);
end NIC;
