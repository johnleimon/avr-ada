------------------------------------------------------------------------------
--                                                                          --
--                        GNAT RUN-TIME COMPONENTS                          --
--                                                                          --
--                       A D A . I N T E R R U P T S                        --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                                                                          --
--          Copyright (C) 1992-2001 Free Software Foundation, Inc.          --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT. The copyright notice above, and the license provisions that follow --
-- apply solely to the  contents of the part following the private keyword. --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces;
--  with System;

package Ada.Interrupts is

   type Interrupt_ID is new Interfaces.Integer_8 range 0 .. 50;
   --  the mega128 has 34 different interrupts

   type Parameterless_Handler is access protected procedure;

   --     function Is_Reserved (Interrupt : Interrupt_ID) return Boolean;

   --     function Is_Attached (Interrupt : Interrupt_ID) return Boolean;

   --     function Current_Handler
   --       (Interrupt : Interrupt_ID)
   --        return      Parameterless_Handler;

   --     procedure Attach_Handler
   --       (New_Handler : Parameterless_Handler;
   --        Interrupt   : Interrupt_ID);

   --     procedure Exchange_Handler
   --       (Old_Handler : out Parameterless_Handler;
   --        New_Handler : Parameterless_Handler;
   --        Interrupt   : Interrupt_ID);

   --     procedure Detach_Handler (Interrupt : Interrupt_ID);

   --     function Reference (Interrupt : Interrupt_ID) return System.Address;

private
   --
end Ada.Interrupts;
