package SHT.LL is
   pragma Preelaborate (SHT.LL);

   procedure Clock_Line_High;
   procedure Clock_Line_Low;
   procedure Data_Line_High;
   procedure Data_Line_Low;
   function  Read_Data_Line return Boolean;
   procedure Init;

   pragma Inline_Always (Clock_Line_High);
   pragma Inline_Always (Clock_Line_Low);
   pragma Inline_Always (Data_Line_High);
   pragma Inline_Always (Data_Line_Low);
   pragma Inline_Always (Read_Data_Line);
   pragma Inline_Always (Init);

end SHT.LL;
