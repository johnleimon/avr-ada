--      TCP/IP-Kommunikation

with Ada.Text_IO;
with Ada.Exceptions;
with GNAT.Sockets;                 use GNAT.Sockets;
with Debug;

package body TCP is


   TCP_Sock : GNAT.Sockets.Socket_Type;


   --  /*!
   --   * Oeffnet eine TCP-Verbindung zum Server
   --  */
   procedure Open_Connection
   is
      use Ada.Exceptions;
      Server_Addr : Sock_Addr_Type;
   begin
      Server_Addr.Addr := Inet_Addr (IP);
      Server_Addr.Port := Port;
      Create_Socket (TCP_Sock);

      Set_Socket_Option
        (TCP_Sock, Socket_Level, (Reuse_Address, True));

      Connect_Socket (TCP_Sock, Server_Addr);

      -- Channel := Ada.Streams.Stream_IO.Stream_Access (Stream (TCP_Sock));

   exception when E : others =>
      Ada.Text_IO.Put_Line
        (Exception_Name (E) & ": " & Exception_Message (E));
   end Open_Connection;


   --  /*!
   --   * Schliesst eine TCP-Connection
   --  */
   procedure Close_Connection is
   begin
      Close_Socket (TCP_Sock);
   end Close_Connection;


   TCP_Write_Error : exception;

   procedure Write (Item : Ada.Streams.Stream_Element_Array)
   is
      use GNAT.Sockets;
      use Ada.Streams;
      Last : Stream_Element_Offset;
   begin
      Debug.Put_Line ("entered TCP.Write");
      Send_Socket (TCP_Sock, Item, Last);
      if Last /= Item'Last then
         raise TCP_Write_Error;
      end if;
   end Write;



   -- Lese Daten von TCP/IP-Verbindung.
   -- Achtung: blockierend!
   procedure Read (Item   : out Ada.Streams.Stream_Element_Array;
                   Last   : out Ada.Streams.Stream_Element_Offset)
   is
      use GNAT.Sockets;
   begin
      --  Debug.Put_Line ("entered TCP.Read");
      Receive_Socket (TCP_Sock, Item, Last);
      null;
   end Read;



   --  /*!
   --   * Initialisiere TCP/IP Verbindung
   --   */
   procedure Init
   is
   begin
      GNAT.Sockets.Initialize;
      Open_Connection;
      Debug.Put_Line ("connection established");
   end Init;

end TCP;
