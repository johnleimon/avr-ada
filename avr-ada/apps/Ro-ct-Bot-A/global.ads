

package Global is

   --***********************************************************
   -- Module switches, to make code smaller if features are not needed
   --***********************************************************

   LED_AVAILABLE        : constant Boolean := True;
   -- LEDs for local control

   IR_AVAILABLE         : constant Boolean := True;
   -- Infrared Remote Control

   RC5_AVAILABLE        : constant Boolean := True;
   -- Key-Mapping for IR-RC

   UART_AVAILABLE       : constant Boolean := False;
   -- Serial Communication

   COMMAND_AVAILABLE    : constant Boolean := False;
   -- High-Level Communication over Uart, needs UART

   DISPLAY_AVAILABLE    : constant Boolean := True;
   -- Display for local control

   ADC_AVAILABLE        : constant Boolean := True;
   -- A/D-Converter for sensing Power

   MAUS_AVAILABLE       : constant Boolean := True;
   -- Maus Sensor

   ENA_AVAILABLE        : constant Boolean := True;
   -- Enable-Leitungen

   SHIFT_AVAILABLE      : constant Boolean := True;
   -- Shift Register

   WELCOME_AVAILABLE    : constant Boolean := True;
   -- show welcome message on display at start-up

   --***********************************************************
   --* Some Dependencies!!!
   --************************************************************/

--  #ifndef DISPLAY_AVAILABLE
--      #undef WELCOME_AVAILABLE
--  #endif

--  #ifndef IR_AVAILABLE
--      #undef RC5_AVAILABLE
--  #endif

--  #ifdef PC
--      #undef UART_AVAILABLE
--      #undef MAUS_AVAILABLE
--      #define COMMAND_AVAILABLE
--  #endif

--  #ifdef MCU
--      #ifndef UART_AVAILABLE
--              #undef COMMAND_AVAILABLE
--      #endif
--  #endif


   F_CPU : constant :=  16_000_000;
   -- Crystal frequency in Hz

end Global;
