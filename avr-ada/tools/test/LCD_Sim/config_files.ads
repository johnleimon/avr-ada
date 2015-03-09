--  Abstract:
--
--  Standard interface to configuration files.
--
--  Design:
--
--  See ../Doc/config_files.texinfo
--
--  All Read and Write subprograms raise Ada.IO_Exceptions.Use_Error
--  if Config is not open.
--
--  All Read and Write subprograms have the following behavior if the
--  requested Key does not exist in Config.Data:
--
--     If Error_Handling is Raise_Exception, Config_File_Error is raised.
--
--     If Error_Handling is Ignore, a write creates the key, a read
--     returns the default value.
--
--  All Read and Write subprograms raise Constraint_Error if the
--  string value in the file for Key is not appropriate for the type.
--
--  The visible, non-implementation dependent parts of this package
--  spec are in the public domain. The private, implementation
--  dependent parts are subject to the following copyright and
--  license.

--  Copyright (C) 2002 - 2004 Stephen Leake.  All Rights Reserved.
--
--  This library is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or (at
--  your option) any later version. This library is distributed in the
--  hope that it will be useful, but WITHOUT ANY WARRANTY; without even
--  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
--  PURPOSE. See the GNU General Public License for more details. You
--  should have received a copy of the GNU General Public License
--  distributed with this program; see file COPYING. If not, write to
--  the Free Software Foundation, 59 Temple Place - Suite 330, Boston,
--  MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this  unit  does not  by itself cause  the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file  might be covered by the  GNU Public License.

--  start implementation dependent
with Ada.Finalization;
with GNAT.OS_Lib;
--  end implementation dependent

package Config_Files is
   pragma Elaborate_Body;
   --  Almost any package that does file IO will not be preelaborable.

   type Configuration_Type is limited private;
   --  Limited because it probably contains a file object.

   type Configuration_Access_Type is access all Configuration_Type;
   --  For including a Configuration_Type component in a non-limited
   --  type.

   procedure Free (Item : in out Configuration_Access_Type);

   type Error_Handling_Type is (Raise_Exception, Ignore);
   --  See design comments above.

   procedure Open
     (Config                : in out Configuration_Type;
      Name                  : in     String;
      Error_Handling        : in     Error_Handling_Type := Ignore;
      Read_Only             : in     Boolean             := True;
      Case_Insensitive_Keys : in     Boolean             := True);
   --  Open the first file named Name found on Config.Search_Path.
   --  Read all data into Config.Data, close the file. Save full path
   --  of file found in Config.Writeable_File_Name.
   --
   --  If Read_Only, all Write operations will raise
   --  Ada.Text_IO.Use_Error. In addition, the file is not written.
   --
   --  If Case_Insensitive_Keys, all searches for keys will be case
   --  insensitive (via Ada.Characters.Handling.To_Lower).
   --
   --  If not Read_Only, and Name is an illegal file name on the
   --  current operating system, Ada.IO_Exceptions.Name_Error is
   --  raised.
   --
   --  If Name is not found on Config.Search_Path, and Error_Handling is
   --  Ignore, Config.Data is set to null, and Config.Name is set to first
   --  directory in Config.Search_Path & Name.
   --
   --  If Name is not found on Config.Search_Path, and Error_Handling is
   --  Raise_Exception, Ada.IO_Exceptions.Name_Error is raised.
   --
   --  If Name is found, but cannot be opened,
   --  Ada.IO_Exceptions.Use_Error is raised.
   --
   --  If Name is found, but contains bad syntax, Config_File_Error is
   --  raised, with a message giving the file name, line, and column,
   --  in Gnu format.
   --
   --  If any exception is raised, the config object is not open.

   function Is_Open (Config : in Configuration_Type) return Boolean;
   --  True if Open has been called, and Close has not.

   procedure Flush (Config : in Configuration_Type);
   --  Write Config.Data to Config.Writeable_File_Name.

   procedure Close (Config : in out Configuration_Type);
   --  Flush and close the file.

   function Writeable_File_Name (Config : in Configuration_Type) return String;
   --  Return writeable absolute file path.

   function Base_File_Name (Config : in Configuration_Type) return String;
   --  Return base file name (no directory path).

   procedure Delete
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Delete Key and contained keys or value from Config.Data.

   procedure Read_String
     (Config         : in     Configuration_Type;
      Key            : in     String;
      Result         :    out String;
      Result_Last    :    out Natural;
      Default        : in     String              := "";
      Error_Handling : in     Error_Handling_Type := Ignore);
   procedure Read
     (Config         : in     Configuration_Type;
      Key            : in     String;
      Result         :    out String;
      Result_Last    :    out Natural;
      Default        : in     String              := "";
      Error_Handling : in     Error_Handling_Type := Ignore)
     renames Read_String;
   --  Read the string value associated with Key from Config.Data, store
   --  in Result. Result_Last is set to last character of Result
   --  written.

   function Read
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in String              := "";
      Error_Handling : in Error_Handling_Type := Ignore)
     return String;
   --  Return string value associated with Key from Config.Data.

   procedure Write_String
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     String;
      Error_Handling : in     Error_Handling_Type := Ignore);
   procedure Write
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     String;
      Error_Handling : in     Error_Handling_Type := Ignore)
     renames Write_String;
   --  Write string value Value to Key in Config.Data.

   generic
      type Enum_Type is (<>);
   function Read_Enum
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Enum_Type           := Enum_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
     return Enum_Type;
   --  Return enumeration value associated with Key from Config.Data.

   generic
      type Enum_Type is (<>);
   procedure Write_Enum
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Enum_Type;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Write enumeration value Value to Key in Config.

   generic
      type Integer_Type is range <>;
   function Read_Integer
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Integer_Type        := Integer_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
     return Integer_Type;
   --  Return integer value associated with Key in Config.Data.

   generic
      type Integer_Type is range <>;
   procedure Write_Integer
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Integer_Type;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Write integer value Value to Key in Config.

   generic
      type Modular_Type is mod <>;
   function Read_Modular
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Modular_Type        := Modular_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
     return Modular_Type;
   --  Return modular integer value associated with Key from
   --  Config.Data.

   generic
      type Modular_Type is mod <>;
   procedure Write_Modular
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Modular_Type;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Write modular integer Value to Key in Config.Data.

   generic
      type Float_Type is digits <>;
   function Read_Float
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Float_Type          := Float_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
     return Float_Type;
   --  Return floating point value associated with Key from
   --  Config.Data.

   generic
      type Float_Type is digits <>;
   procedure Write_Float
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Float_Type;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Write float value Value to Key in Config.Data.

   generic
      type Fixed_Type is delta <>;
   function Read_Fixed
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Fixed_Type          := Fixed_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
     return Fixed_Type;
   --  Return fixed point value associated with Key from
   --  Config.Data.

   generic
      type Fixed_Type is delta <>;
   procedure Write_Fixed
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Fixed_Type;
      Error_Handling : in     Error_Handling_Type := Ignore);
   --  Write fixed point value Value to Key in Config.Data.

   ----------
   --  Iterators
   --
   --  Example
   --
   --  Assume Foo.Bar.Size and Foo.Bar.Type are keys in the tree.
   --
   --  After I := First (Config, "Foo.Bar"); I points to Foo.Bar.Size.
   --  Current (I); returns "Size"
   --  After Next (I); I points to Foo.Bar.Type

   type Iterator_Type is private;

   function First
     (Config         : in Configuration_Type;
      Root_Key       : in String              := "";
      Error_Handling : in Error_Handling_Type := Raise_Exception)
     return Iterator_Type;
   --  Return iterator pointing to first child of Root_Key. If
   --  Root_Key is "", this is the first root key.
   --
   --  if Root_Key is not "", and is not found:
   --  case Error_Handling is
   --  when Raise_Exception => Config_File_Error is raised
   --  when Ignore => result iterator is null (Is_Done is true).

   function Is_Done (Iterator : in Iterator_Type) return Boolean;

   procedure Next (Iterator : in out Iterator_Type);

   function Current (Iterator : in Iterator_Type) return String;
   --  Return leaf of child key at Iterator; this may be a leaf key or
   --  the next layer root key.

   function Read (Iterator : in Iterator_Type) return String;
   --  Return Value for Iterator key.

   function Line_Column (Iterator : in Iterator_Type) return String;
   --  Return "line:column: " where the current value was read, for
   --  error messages.

   function File_Line_Column (Config : in Configuration_Type; Iterator : in Iterator_Type) return String;
   --  Return "file:line:column: " where the current value was read, for
   --  error messages.

   function Read (Config : in Configuration_Type; Iterator : in Iterator_Type; Leaf : in String) return String;
   --  Does Read (Current (Iterator) & "." & Leaf, Raise_Exception).
   --  Exception message has the format "file:line:column: <key> not
   --  found", where line, column are from Iterator.

   generic
      type Enum_Type is (<>);
   function Read_Iterator_Enum
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Enum_Type;

   generic
      type Integer_Type is range <>;
   function Read_Iterator_Integer
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Integer_Type;

   generic
      type Float_Type is digits <>;
   function Read_Iterator_Float
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Float_Type;

   generic
      type Modular_Type is mod <>;
   function Read_Iterator_Modular
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Modular_Type;


   Config_File_Error : exception;

private
--  start implementation dependent

   type Node_Type;
   type Node_Access_Type is access all Node_Type;

   type Configuration_Type is new Ada.Finalization.Limited_Controlled with record
      Read_Only             : Boolean;
      Case_Insensitive_Keys : Boolean;
      Writeable_File_Name   : GNAT.OS_Lib.String_Access; --  full path
      Error_File_Name       : GNAT.OS_Lib.String_Access; --  just file name
      Search_Path           : GNAT.OS_Lib.Argument_List_Access;
      Default_Names         : GNAT.OS_Lib.Argument_List_Access;
      Data                  : Node_Access_Type; -- root of tree.
   end record;

   procedure Finalize (Config : in out Configuration_Type);

   ----------
   --  Iterators

   type Iterator_Type is new Node_Access_Type;

--  end implementation dependent

end Config_Files;
