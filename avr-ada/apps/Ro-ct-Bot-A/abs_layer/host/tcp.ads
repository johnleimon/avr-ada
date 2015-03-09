--   TCP/IP-Kommunikation

with Ada.Streams;


package TCP is


   IP  : constant String := "127.0.0.1";
   --  IP, mit der verbunden werden soll (normalerweise localhost)

   Port : constant := 10001;
   --  Port, mit dem verbunden werden soll

   -- TCP_Sock : GNAT.Sockets.Socket_Type;
   -- Unser TCP-Socket

   -- Channel : Ada.Streams.Stream_IO.Stream_Access;
   --  channel for input/output via Ada's stream facility


   -- Uebertrage Daten per TCP/IP
   -- @param data Zeiger auf die Daten
   -- @param length Anzahl der Bytes
   -- @return Anzahl der uebertragenen Bytes
   procedure Write (-- Socket : GNAT.Sockets.Socket_Type;
        Item   : Ada.Streams.Stream_Element_Array);
--        Last   : out Ada.Streams.Stream_Element_Offset;
--        Flags  : GNAT.Sockets.Request_Flag_Type := GNAT.Sockets.No_Request_Flag)
--       renames GNAT.Sockets.Send_Socket;


   -- Lese Daten von TCP/IP-Verbindung.
   -- Achtung: blockierend!
   -- @param data Zeiger auf die Daten
   -- @param length Anzahl der gewuenschten Bytes
   -- @return Anzahl der uebertragenen Bytes
   procedure Read (Item   : out Ada.Streams.Stream_Element_Array;
                   Last   : out Ada.Streams.Stream_Element_Offset);

   --
   -- Initialisiere TCP/IP Verbindung
   --
   procedure Init;

end TCP;
