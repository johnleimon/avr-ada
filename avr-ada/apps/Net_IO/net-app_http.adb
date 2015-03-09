with Interfaces;                   use Interfaces;
with AVR.Strings;                  use AVR.Strings;
with Net.Buffer;                   use Net.Buffer;

with Net.IP.TCP;
with AVR.PStrings;

with Debug;  with Text;


package body Net.App_HTTP is


   NL : constant Character := ASCII.CR;

   Http_Header1 : AVR.Pstrings.P_String :=
     "HTTP/1.0 200 Document follows Server: Net_IO Content-Type: text/html";
   pragma Linker_Section (Http_Header1, ".progmem");

   Httpd_Header_200 : AVR.Pstrings.P_String :=
     "HTTP/1.1 200 OK\nConnection: close\n";
   pragma Linker_Section (Httpd_Header_200, ".progmem");

   Httpd_Header_Ct_Css : AVR.Pstrings.P_String :=
     "Content-Type: text/css; charset=iso-8859-1\n\n";
   pragma Linker_Section (Httpd_Header_Ct_Css, ".progmem");

   Httpd_Header_Ct_Html : AVR.Pstrings.P_String :=
     "Content-Type: text/html; charset=iso-8859-1\n\n";
   pragma Linker_Section (Httpd_Header_Ct_Html, ".progmem");

   Httpd_Header_Ct_Xhtml : AVR.Pstrings.P_String :=
     "Content-Type: application/xhtml+xml; charset=iso-8859-1\n\n";
   pragma Linker_Section (Httpd_Header_Ct_Xhtml, ".progmem");

   Httpd_Header_400 : AVR.Pstrings.P_String :=
     "HTTP/1.1 400 Bad Request\nConnection: close\nContent-Type: text/plain; charset=iso-8859-1\n";
   pragma Linker_Section (Httpd_Header_400, ".progmem");

   Httpd_Header_Gzip : AVR.Pstrings.P_String :=
     "Content-Encoding: gzip\n";
   pragma Linker_Section (Httpd_Header_Gzip, ".progmem");

   Httpd_Header_401 : AVR.Pstrings.P_String :=
     "HTTP/1.1 401 UNAUTHORIZED\nConnection: close\nWWW-Authenticate: Basic realm=""Secure Area""\nContent-Type: text/plain; charset=iso-8859-1\n";
   pragma Linker_Section (Httpd_Header_401, ".progmem");

   Httpd_Body_401 : AVR.Pstrings.P_String :=
     "Authentification required\n";
   pragma Linker_Section (Httpd_Body_401, ".progmem");

   Httpd_Body_400 : AVR.Pstrings.P_String :=
     "Bad Request\n";
   pragma Linker_Section (Httpd_Body_400, ".progmem");

   Httpd_Header_404 : AVR.Pstrings.P_String :=
     "HTTP/1.1 404 File Not Found\nConnection: close\nContent-Type: text/plain; charset=iso-8859-1\n";
   pragma Linker_Section (Httpd_Header_404, ".progmem");

   Httpd_Body_404 : AVR.Pstrings.P_String :=
     "File Not Found\n";
   pragma Linker_Section (Httpd_Body_404, ".progmem");

   Httpd_Header_Length : AVR.Pstrings.P_String := "Content-Length: ";
   pragma Linker_Section (Httpd_Header_Length, ".progmem");


--     procedure Send_Str_With_NL(void *data);
--     procedure send_str_P(void *data);
--     procedure send_length_P(void *data);
--     procedure send_length_f(void *data);
--     procedure send_length_if(void *data);
--     procedure send_sd_f(void *data);
--     procedure send_file_f(void *data);
--     procedure send_file_if(void *data);

   procedure Init
   is
   begin
      Net.IP.TCP.Register_App (Net.IP.HTTP_Port, httpd'Access);
      Net.IP.TCP.Register_App (Net.IP.Alt_HTTP_Port, httpd'Access);
   end Init;


   procedure Http_Handle (State : Http_Connection_State_Type)
   is
   begin
      null;
   end Http_Handle;


   procedure Httpd_Cleanup (State : Http_Connection_State_Type)
   is
   begin
      null;
   end Httpd_Cleanup;


   procedure Httpd
   is
      use Debug;
      use Text;
      use Net.IP.TCP;

      State : Http_Connection_State_Type;
   begin
      Put_P (In_HTTPD_P); Put_P (Pck_Rcvd_P);
      New_Line;

      if Current_Connection_Is_Aborted or else Current_Connection_Is_Timed_Out then
         Httpd_Cleanup (State);
         Put_P (In_HTTPD_P);
         Put_P (Aborted_P);
         New_Line;
         return;

      elsif Current_Connection_Is_Closed then
         Put_P (In_HTTPD_P);
         Put_P (Closed_P);
         New_Line;

      elsif Current_Connection_Is_Connected then
         Put_P (In_HTTPD_P);
         Put   ("new ");
         Put_P (Conn_P);
         New_Line;

         State.State := Idle;
         State.Timeout := 0;

      end if;

      if Need_Retransmit
        or else Application_Data_Is_Available
        or else Current_Connection_Is_Acked
        or else Current_Connection_Is_Connected
        or else Is_Polled
      then

         if not Is_Polled then
            State.Timeout := 0;
         end if;

         Put_P (In_Httpd_P);
         Put ("action!");

         Http_Handle (State);
      end if;
   end httpd;



end Net.App_HTTP;


