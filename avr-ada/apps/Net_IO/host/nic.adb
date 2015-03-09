--
--   interface package for using U. Radig's driver
--

with Net.Buffer;                   use Net.Buffer;
with Debug;                        use Debug;

package body NIC is


   procedure Init
   is
   begin
      null;
   end Init;


   procedure Send_Packet (Len : Base_Buffer_Range; Buf : MTU_Storage)
   is
   begin
      Put ("HOST: (send_packet) Len: ");
      Put_String (Len'Img);
      New_Line;
      Net.Buffer.Debug_Put (Buf (1 .. Len));
   end Send_Packet;


   --  return length of received packet
   function Receive_Packet (Size : Base_Buffer_Range; Buf : MTU_Storage)
                           return Base_Buffer_Range
   is
      Result : constant Base_Buffer_Range := 0;
   begin
      return Result;
   end Receive_Packet;


   procedure Enable_ETH_Interrupt
   is
   begin
      null;
   end Enable_ETH_Interrupt;

   procedure Disable_ETH_Interrupt
   is
   begin
      null;
   end Disable_ETH_Interrupt;


   function Data_Available return Boolean
   is
   begin
      return False;
   end Data_Available;


end NIC;
