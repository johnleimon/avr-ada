with Interfaces;                   use Interfaces;

package Net.Buffer is

   Buffer_Size : constant := 500;

   subtype Base_Buffer_Range is Unsigned_16 range 0 .. Buffer_Size;
   subtype Buffer_Range is Base_Buffer_Range range 1 .. Buffer_Size;
   type Storage is array (Buffer_Range range <>) of Unsigned_8;
   subtype MTU_Storage is Storage (Buffer_Range);
   type Buffer_Ptr_Type is access all MTU_Storage;

   MTU_Buffer : aliased MTU_Storage;
   -- pragma Import (C, MTU_Buffer, "eth_buffer");
   MTU_Ptr    : constant Buffer_Ptr_Type := MTU_Buffer'Access;

   Used_Len   : Base_Buffer_Range;


   procedure Debug_Put (B : Storage);


end Net.Buffer;


