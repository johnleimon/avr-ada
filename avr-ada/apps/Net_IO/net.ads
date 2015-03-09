with System;
with Interfaces;                   use Interfaces;
with Ada.Unchecked_Conversion;
With AVR.Strings;                  use AVR.Strings;

package Net is
   pragma Pure;


   type IP_Addr_Type is array (Unsigned_8 range 1 .. 4) of Unsigned_8;

   Any_IP_Addr       : constant IP_Addr_Type := (0, 0, 0, 0);
   No_IP_Addr        : constant IP_Addr_Type := (0, 0, 0, 0);
   Broadcast_IP_Addr : constant IP_Addr_Type := (16#FF#, 16#FF#, 16#FF#, 16#FF#);

   function IP_Addr (A, B, C, D : Unsigned_8) return IP_Addr_Type;
   function Image (IP : IP_Addr_Type) return AStr15;
   function Are_Equal (Left, Right, Mask : IP_Addr_Type) return Boolean;


   type MAC_Addr_Type is array (Unsigned_8 range 1 .. 6) of Unsigned_8;

   Broadcast_MAC_Addr : constant MAC_Addr_Type := (255, 255, 255, 255, 255, 255);
   No_MAC_Addr        : constant MAC_Addr_Type := (  0,   0,   0,   0,   0,   0);


   function MAC_Addr (A, B, C, D, E, F : Unsigned_8) return MAC_Addr_Type;
   function Image (MAC : MAC_Addr_Type) return AStr17;


   --  NBO = Network Byte Order
   --  HBO = Host Byte Order
   type U16_NBO is private;
   type U32_NBO is private;

   function HtoN_16 (Value : Unsigned_16) return U16_NBO;
   function NtoH_16 (Value : U16_NBO) return Unsigned_16;

   function HtoN_32 (Value : Unsigned_32) return U32_NBO;
   function NtoH_32 (Value : U32_NBO) return Unsigned_32;

private

   pragma Inline (IP_Addr);
   pragma Inline (MAC_Addr);


   type U16_NBO is record
      Hi : Unsigned_8;
      Lo : Unsigned_8;
   end record;
   for U16_NBO'Size use 16;
   for U16_NBO'Bit_Order use System.Low_Order_First;
   for U16_NBO use record
      Hi at 0 range 0 .. 7;
      Lo at 0 range 8 .. 15;
   end record;

   type U16_HBO is new U16_NBO;
   for U16_HBO use record
      Lo at 0 range 0 .. 7;
      Hi at 0 range 8 .. 15;
   end record;

   function To_16HBO is new Ada.Unchecked_Conversion (Source => Unsigned_16,
                                                      Target => U16_HBO);
   function To_U16 is new Ada.Unchecked_Conversion (Source => U16_HBO,
                                                    Target => Unsigned_16);


   type U32_NBO is record
      High : Unsigned_8;
      Hi   : Unsigned_8;
      Lo   : Unsigned_8;
      Low  : Unsigned_8;
   end record;
   for U32_NBO'Size use 32;
   for U32_NBO'Bit_Order use System.Low_Order_First;
   for U32_NBO use record
      High at 0 range  0 ..  7;
      Hi   at 0 range  8 .. 15;
      Lo   at 0 range 16 .. 23;
      Low  at 0 range 24 .. 31;
   end record;

   type U32_HBO is new U32_NBO;
   for U32_HBO use record
      Low  at 0 range  0 .. 7;
      Lo   at 0 range  8 .. 15;
      Hi   at 0 range 16 .. 23;
      High at 0 range 24 .. 31;
   end record;

   function To_32HBO is new Ada.Unchecked_Conversion (Source => Unsigned_32,
                                                      Target => U32_HBO);
   function To_U32 is new Ada.Unchecked_Conversion (Source => U32_HBO,
                                                    Target => Unsigned_32);



   type Port_Type is new U16_NBO;
   Any_Port : constant Port_Type := (0, 0);
   No_Port  : constant Port_Type := (0, 0);



   pragma Inline (HtoN_16);
   pragma Inline (NtoH_16);
   pragma Pure_Function (HtoN_16);
   pragma Pure_Function (NtoH_16);
   pragma Inline (HtoN_32);
   pragma Inline (NtoH_32);
   pragma Pure_Function (HtoN_32);
   pragma Pure_Function (NtoH_32);

end Net;
