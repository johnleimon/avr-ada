------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--              S Y S T E M . S T A N D A R D _ L I B R A R Y               --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--          Copyright (C) 1992-2002 Free Software Foundation, Inc.          --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  This package is included in all programs. It contains declarations that
--  are required to be part of every Ada program. A special mechanism is
--  required to ensure that these are loaded, since it may be the case in
--  some programs that the only references to these required packages are
--  from C code or from code generated directly by Gigi, an in both cases
--  the binder is not aware of such references.

--  System.Standard_Library also includes data that must be present in every
--  program, in particular the definitions of all the standard and also some
--  subprograms that must be present in every program.

--  The binder unconditionally includes s-stalib.ali, which ensures that this
--  package and the packages it references are included in all Ada programs,
--  together with the included data.

--  pragma Polling (Off);
--  We must turn polling off for this unit, because otherwise we get
--  elaboration circularities with Ada.Exceptions if polling is on.

with System;
with Unchecked_Conversion;
with Interfaces;

package System.Standard_Library is

--   pragma Suppress (All_Checks);
   --  Suppress explicitely all the checks to work around the Solaris linker
   --  bug when using gnatmake -f -a (but without -gnatp). This is not needed
   --  with Solaris 2.6, so eventually can be removed ???

   type Big_String_Ptr is access all String (Positive);
   --  A non-fat pointer type for null terminated strings

   function To_Ptr is
     new Unchecked_Conversion (System.Address, Big_String_Ptr);

   ---------------------------------------------
   -- Type For Enumeration Image Index Tables --
   ---------------------------------------------

   --  Note: these types are declared at the start of this unit, since
   --  they must appear before any enumeration types declared in this
   --  unit. Note that the spec of system is already elaborated at
   --  this point (since we are a child of system), which means that
   --  enumeration types in package System cannot use these types.

   type Image_Index_Table_8 is
     array (Integer range <>) of Interfaces.Integer_8;
   type Image_Index_Table_16 is
     array (Integer range <>) of Interfaces.Integer_16;
   type Image_Index_Table_32 is
     array (Integer range <>) of Integer;
   --  These types are used to generate the index vector used for enumeration
   --  type image tables. See spec of Exp_Imgv in the main GNAT sources for a
   --  full description of the data structures that are used here.


   Local_Partition_ID : Natural := 0;
   --  This variable contains the local Partition_ID that will be used when
   --  building exception occurrences. In distributed mode, it will be
   --  set by each partition to the correct value during the elaboration.


   -----------------
   -- Subprograms --
   -----------------

--     procedure Abort_Undefer_Direct;
--     pragma Inline (Abort_Undefer_Direct);
   --  A little procedure that just calls Abort_Undefer.all, for use in
   --  clean up procedures, which only permit a simple subprogram name.

--   procedure Adafinal;
   --  Performs the Ada Runtime finalization the first time it is invoked.
   --  All subsequent calls are ignored.

end System.Standard_Library;
