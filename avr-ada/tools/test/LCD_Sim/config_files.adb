--  Abstract:
--
--  see spec.
--
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

with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with GNAT.Directory_Operations;

package body Config_Files is

   type Node_Type is record
      Tag          : GNAT.OS_Lib.String_Access;

      Value        : GNAT.OS_Lib.String_Access;
      --  Null if not a leaf node.

      Line         : Ada.Text_IO.Count;
      Column       : Ada.Text_IO.Count;
      --  Line and column (of start of value) in file; set for leaf
      --  nodes read from a file only (0 otherwise). Used for error
      --  messages.

      Parent       : Node_Access_Type;
      --  Null if root of tree. Used to build full key name from iterator.

      Child        : Node_Access_Type;
      --  Null if a leaf node

      Next_Sibling : Node_Access_Type;
      --  May be non-null for either leaf or non-leaf.
   end record;
   --  The root node of the tree (Config.Data) has the Tag "Config",
   --  and is always present (created by Open if the file does not
   --  exist). The root node has no siblings, and no value.
   --  Eventually, we may store attributes there, like read-only.
   --
   --  Key nodes have the key name as tag, and the value as value.
   --  Note that a Tag value never has dots.

   ----------
   --  Subprogram specs (alphabetical)

   procedure Add_Child
     (Key_Root         : in Node_Access_Type;
      Key              : in String;
      Value            : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean);

   procedure Add_Node
     (Config           : in out Configuration_Type;
      Key              : in     String;
      Value            : in     String;
      Line             : in     Ada.Text_IO.Count;
      Column           : in     Ada.Text_IO.Count;
      Case_Insensitive : in     Boolean);

   procedure Add_Key
     (Key_Root         : in Node_Access_Type;
      Key              : in String;
      Value            : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean);

   procedure Add_Sibling
     (Node   : in Node_Access_Type;
      Tag    : in String;
      Value  : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count);

   function Add_Sibling
     (Node             : in Node_Access_Type;
      Tag              : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean)
     return Node_Access_Type;
   --  Return node with Tag; add if necessary.

   procedure Check_Open (Config : in Configuration_Type);
   --  Raise Ada.IO_Exceptions.Use_Error if Config is not open.

   procedure Error_Line_Column
     (Config : in Configuration_Type;
      Node   : in Node_Access_Type;
      Label  : in String);
   --  Raise Constraint_Error with "file:line:column message" in exception message.
   pragma No_Return (Error_Line_Column);

   function Find_Key
     (Root             : in Node_Access_Type;
      Key              : in String;
      Case_Insensitive : in Boolean)
     return Node_Access_Type;
   --  If Key is not found, return null.

   function Find_Node
     (Config  : in Configuration_Type;
      Key     : in String)
     return Node_Access_Type;

   procedure Flush_Value
     (File : in Ada.Text_IO.File_Type;
      Node : in Node_Access_Type;
      Tag  : in String);
   --  Write Value, Children of Node to File, using Tag as the key name.

   procedure Flush
     (File : in Ada.Text_IO.File_Type;
      Tree : in Node_Access_Type;
      Tag  : in String);
   --  Write all of Tree to File, using Tag as the root key name.

   procedure Free (Tree : in out Node_Access_Type);

   function Format_Line_Column
     (Config : in Configuration_Type;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count)
     return String;

   function Full_Key (Node : in Node_Access_Type; Leaf : in String) return String;
   --  Return full key; prefix is made by tracing Node.Parent to the
   --  tree root, suffix is Leaf.

   function Is_Equal
     (Left, Right      : in String;
      Case_Insensitive : in Boolean)
     return Boolean;
   --  Return Left = Right, but if Config.Case_Insensitive_Keys, use
   --  case insenstive compare.

   procedure Key_Not_Found
     (Config : in Configuration_Type;
      Key    : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count);
   procedure Key_Not_Found
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String);
   procedure Key_Not_Found
     (Config : in Configuration_Type;
      Key    : in String);
   pragma No_Return (Key_Not_Found);
   --  Raise Config_File_Error, with appropriate message.

   procedure Parse
     (File   : in out Ada.Text_IO.File_Type;
      Config : in out Configuration_Type);

   procedure Parse (Config : in out Configuration_Type);

   procedure Set_Value
     (Node   : in Node_Access_Type;
      Value  : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count);

   function String_Fix (Item : in String) return String
   is
      --  WORKAROUND: GNAT 3.15p Raise_Exception can't handle strings
      --  that have 'first /= 1
      Fixed : constant String (1 .. Item'Length) := Item;
   begin
      return Fixed;
   end String_Fix;

   ----------
   --  Private subprogram bodies; alphabetical order.

   procedure Add_Child
     (Key_Root         : in Node_Access_Type;
      Key              : in String;
      Value            : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean)
   is
      Temp_Root   : Node_Access_Type := Key_Root;
      Tag_Last    : Integer          := Ada.Strings.Fixed.Index (Key, ".") - 1;
      Temp_Column : Ada.Text_IO.Count;
   begin
      if Tag_Last = -1 then
         --  This is a leaf key
         Tag_Last    := Key'Last;
         Temp_Column := Column;
      else
         Temp_Column := Ada.Text_IO.Count (Tag_Last);
      end if;

      if Temp_Root.Child = null then
         Temp_Root.Child := new Node_Type'
           (Tag          => new String'(Key (Key'First .. Tag_Last)),
            Value        => null,
            Parent       => Temp_Root,
            Child        => null,
            Next_Sibling => null,
            Line         => Line,
            Column       => Temp_Column);

         Temp_Root := Temp_Root.Child;
      else
         Temp_Root := Add_Sibling
           (Temp_Root.Child,
            Key (Key'First .. Tag_Last),
            Line             => Line,
            Column           => Temp_Column,
            Case_Insensitive => Case_Insensitive);
      end if;

      if Tag_Last = Key'Last then
         Set_Value (Temp_Root, Value, Line, Column);
      else
         --  Add sub key.
         declare
            Sub_Key : constant String := Key (Tag_Last + 2 .. Key'Last);
         begin
            Add_Child (Temp_Root, Sub_Key, Value, Line, Temp_Column, Case_Insensitive);
         end;
      end if;
   end Add_Child;

   procedure Add_Key
     (Key_Root         : in Node_Access_Type;
      Key              : in String;
      Value            : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean)
      --  Key does not exist in tree under Key_Root; add it.
   is
      Dot : constant Integer := Ada.Strings.Fixed.Index (Key, ".");
   begin
      if Dot = 0 then
         Add_Sibling (Key_Root, Key, Value, Line, Column);
      else
         --  Add sub keys.
         declare
            Tag      : constant String  := Key (Key'First .. Dot - 1);
            Sub_Key  : constant String  := Key (Dot + 1 .. Key'Last);
            Tag_Root : Node_Access_Type := Find_Key (Key_Root, Tag, Case_Insensitive);
         begin
            if Tag_Root = null then
               Tag_Root := Add_Sibling (Key_Root, Tag, Line, Column, Case_Insensitive);
            end if;

            Add_Child (Tag_Root, Sub_Key, Value, Line, Column, Case_Insensitive);
         end;
      end if;
   end Add_Key;

   procedure Add_Node
     (Config           : in out Configuration_Type;
      Key              : in     String;
      Value            : in     String;
      Line             : in     Ada.Text_IO.Count;
      Column           : in     Ada.Text_IO.Count;
      Case_Insensitive : in     Boolean)
      --  Key does not exist in Config; add it.
   is begin
      Check_Open (Config);

      if Config.Data.Child = null then
         --  First key in Config.Data tree.
         Add_Child (Config.Data, Key, Value, Line, Column, Case_Insensitive);
      else
         Add_Key (Config.Data.Child, Key, Value, Line, Column, Case_Insensitive);
      end if;
   end Add_Node;

   procedure Add_Sibling
     (Node   : in Node_Access_Type;
      Tag    : in String;
      Value  : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count)
   is begin
      if Node.Next_Sibling /= null then
         Add_Sibling (Node.Next_Sibling, Tag, Value, Line, Column);
      else
         Node.Next_Sibling := new Node_Type'
           (Tag          => new String'(Tag),
            Value        => new String'(Value),
            Line         => Line,
            Column       => Column,
            Parent       => Node.Parent,
            Child        => null,
            Next_Sibling => null);
      end if;
   end Add_Sibling;

   function Add_Sibling
     (Node             : in Node_Access_Type;
      Tag              : in String;
      Line             : in Ada.Text_IO.Count;
      Column           : in Ada.Text_IO.Count;
      Case_Insensitive : in Boolean)
     return Node_Access_Type
   is
      Temp_Node : constant Node_Access_Type := Find_Key (Node, Tag, Case_Insensitive);
   begin
      if Temp_Node /= null then
         return Temp_Node;
      elsif Node.Next_Sibling /= null then
         return Add_Sibling (Node.Next_Sibling, Tag, Line, Column, Case_Insensitive);
      else
         Node.Next_Sibling := new Node_Type'
           (Tag          => new String'(Tag),
            Value        => null,
            Line         => Line,
            Column       => Column,
            Parent       => Node.Parent,
            Child        => null,
            Next_Sibling => null);
         return Node.Next_Sibling;
      end if;
   end Add_Sibling;

   procedure Check_Open (Config : in Configuration_Type)
   is begin
      if Config.Data = null then
         raise Ada.IO_Exceptions.Use_Error;
      end if;
   end Check_Open;

   procedure Error_Line_Column
     (Config : in Configuration_Type;
      Node   : in Node_Access_Type;
      Label  : in String)
   is begin
      Ada.Exceptions.Raise_Exception
        (Constraint_Error'Identity,
         String_Fix (Format_Line_Column (Config, Node.Line, Node.Column) & Label));
   end Error_Line_Column;

   procedure Finalize (Config : in out Configuration_Type)
   is
      use GNAT.OS_Lib;
      procedure Free is new Ada.Unchecked_Deallocation
        (Object => Argument_List, Name => Argument_List_Access);
   begin
      if Config.Writeable_File_Name /= null then
         if not Config.Read_Only then
            begin
               Flush (Config);
            exception
            when others =>
            --  Open failed somehow, or disk full, or something.
               null;
            end;
         end if;

         Free (Config.Writeable_File_Name);
         if Config.Search_Path /= null then
            for I in Config.Search_Path'Range loop
               Free (Config.Search_Path (I));
            end loop;
            Free (Config.Search_Path);
         end if;

         if Config.Default_Names /= null then
            for I in Config.Default_Names'Range loop
               Free (Config.Default_Names (I));
            end loop;
            Free (Config.Default_Names);
         end if;

         Free (Config.Data);
      end if;
   exception
   when E : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "Finalizing Config_File " &
           Config.Writeable_File_Name.all &
           " raised exception " &
           Ada.Exceptions.Exception_Name (E) &
           " : " &
           Ada.Exceptions.Exception_Message (E));
   end Finalize;

   function Find_Key
     (Root             : in Node_Access_Type;
      Key              : in String;
      Case_Insensitive : in Boolean)
     return Node_Access_Type
   is
      Dot : constant Integer := Ada.Strings.Fixed.Index (Key, ".");
   begin
      if Root = null then
         return null;
      end if;

      if Dot = 0 then
         if Is_Equal (Root.Tag.all, Key, Case_Insensitive) then
            return Root;
         else
            return Find_Key (Root.Next_Sibling, Key, Case_Insensitive);
         end if;
      else
         declare
            Tag      : constant String           := Key (Key'First .. Dot - 1);
            Sub_Key  : constant String           := Key (Dot + 1 .. Key'Last);
            Key_Root : constant Node_Access_Type := Find_Key (Root, Tag, Case_Insensitive);
         begin
            if Key_Root = null or else Key_Root.Child = null then
               return null;
            else
               return Find_Key (Key_Root.Child, Sub_Key, Case_Insensitive);
            end if;
         end;
      end if;
   end Find_Key;

   function Find_Node
     (Config  : in Configuration_Type;
      Key     : in String)
     return Node_Access_Type
      --  If Key is not found, null is returned.
   is begin
      Check_Open (Config);
      return Find_Key (Config.Data.Child, Key, Config.Case_Insensitive_Keys);
   end Find_Node;

   procedure Flush_Value
     (File : in Ada.Text_IO.File_Type;
      Node : in Node_Access_Type;
      Tag  : in String)
   is
      use Ada.Text_IO;
   begin
      if Tag = "" then
         Put_Line (File, Node.Tag.all & "=" & Node.Value.all);
      else
         Put_Line (File, Tag & "." & Node.Tag.all & "=" & Node.Value.all);
      end if;
   end Flush_Value;

   procedure Flush
     (File : in Ada.Text_IO.File_Type;
      Tree : in Node_Access_Type;
      Tag  : in String)
   is
      use type GNAT.OS_Lib.String_Access;
   begin
      if Tree.Value /= null then
         Flush_Value (File, Tree, Tag);
      end if;

      if Tree.Child /= null then
         if Tag = "" then
            Flush (File, Tree.Child, Tree.Tag.all);
         else
            Flush (File, Tree.Child, Tag & "." & Tree.Tag.all);
         end if;
      end if;

      if Tree.Next_Sibling /= null then
         Flush (File, Tree.Next_Sibling, Tag);
      end if;
   end Flush;

   function Format_Line_Column
     (Config : in Configuration_Type;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count)
     return String
   is
      use Ada.Text_IO, Ada.Strings;
      Line_Image   : constant String := Fixed.Trim (Count'Image (Line), Both);
      Column_Image : constant String := Fixed.Trim (Count'Image (Column), Both);
   begin
      return Config.Error_File_Name.all & ":" & Line_Image & ":" & Column_Image & ": ";
   end Format_Line_Column;

   procedure Free_Node is new Ada.Unchecked_Deallocation
     (Node_Type, Node_Access_Type);

   procedure Free (Tree : in out Node_Access_Type)
      --  Free tree rooted at Tree.
   is
      use GNAT.OS_Lib;
   begin
      if Tree = null then
         return;
      end if;

      if Tree.Tag /= null then
         Free (Tree.Tag);
      end if;

      if Tree.Value /= null then
         Free (Tree.Value);
      end if;

      if Tree.Child /= null then
         Free (Tree.Child);
      end if;

      if Tree.Next_Sibling /= null then
         Free (Tree.Next_Sibling);
      end if;

      Free_Node (Tree);
   end Free;

   function Full_Key (Node : in Node_Access_Type; Leaf : in String) return String
   is begin
      if Node = null or else Node.Parent = null then
         return Leaf;
      else
         return Full_Key (Node.Parent, Node.Tag.all & "." & Leaf);
      end if;
   end Full_Key;

   function Is_Equal
     (Left, Right      : in String;
      Case_Insensitive : in Boolean)
     return Boolean
   is
      use Ada.Characters.Handling;
   begin
      if Case_Insensitive then
         if Left'Length /= Right'Length then
            return False;
         else
            for I in Left'Range loop
               if To_Lower (Left (I)) /= To_Lower (Right (Right'First + (I - Left'First))) then
                  return False;
               end if;
            end loop;
            return True;
         end if;
      else
         return Left = Right;
      end if;
   end Is_Equal;

   procedure Key_Not_Found
     (Config : in Configuration_Type;
      Key    : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count)
   is begin
      Ada.Exceptions.Raise_Exception
        (Config_File_Error'Identity, String_Fix (Format_Line_Column (Config, Line, Column) & Key & " not found"));
   end Key_Not_Found;

   procedure Key_Not_Found
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
   is begin
      Key_Not_Found (Config, Full_Key (Node_Access_Type (Iterator), Leaf), Iterator.Line, Iterator.Column);
   end Key_Not_Found;

   procedure Key_Not_Found
     (Config : in Configuration_Type;
      Key    : in String)
   is begin
      Ada.Exceptions.Raise_Exception
        (Config_File_Error'Identity, Config.Error_File_Name.all & ":0:0: " & Key & " not found");
   end Key_Not_Found;

   procedure Parse
     (File   : in out Ada.Text_IO.File_Type;
      Config : in out Configuration_Type)
   is
      use Ada.Strings.Fixed;
      use Ada.Strings.Unbounded;
      use Ada.Strings.Unbounded.Text_IO;
      use type Ada.Text_IO.Count;
      Line   : Unbounded_String;
      Equals : Natural;
   begin
      loop
         exit when Ada.Text_IO.End_Of_File (File);

         Line := Get_Line (File);

         --  Handle empty line (or empty file)
         if Length (Line) > 0 then

            --  FIXME: java properties spec says skip whitespace first
            if Element (Line, 1) = '#' or
              Element (Line, 1) = '!'
            then
               null;
            else
               Equals := Index (Line, "=");

               --  Check for bad format; no '='. FIXME: not according to Java Properties spec!
               if Equals = 0 then
                  Ada.Exceptions.Raise_Exception
                    (Config_File_Error'Identity,
                     String_Fix (Format_Line_Column (Config, Ada.Text_IO.Line (File) - 1, 0) & "missing '='"));
               end if;

               declare
                  use type Ada.Text_IO.Count;

                  Key   : constant String := Trim (Slice (Line, 1, Equals - 1), Ada.Strings.Both);
                  Value : constant String := Trim (Slice (Line, Equals + 1, Length (Line)), Ada.Strings.Both);

                  --  Check for duplicate keys in file (possible if user
                  --  edited directly). Use last one found.
                  Node : constant Node_Access_Type := Find_Node (Config, Key);
               begin
                  if Node = null then
                     Add_Node
                       (Config,
                        Key              => Key,
                        Value            => Value,
                        Line             => Ada.Text_IO.Line (File) - 1,
                        Column           => Ada.Text_IO.Count (Equals) + 1,
                        Case_Insensitive => Config.Case_Insensitive_Keys);
                  else
                     Set_Value
                       (Node,
                        Value  => Value,
                        Line   => Ada.Text_IO.Line (File) - 1,
                        Column => Ada.Text_IO.Count (Equals) + 1);
                  end if;
               end;
            end if;
         end if;
      end loop;
   end Parse;

   procedure Parse (Config : in out Configuration_Type)
   is
      OS_File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Open
        (OS_File, Ada.Text_IO.In_File, Config.Writeable_File_Name.all);

      begin
         Parse (OS_File, Config);
      exception
      when others =>
         --  already has a good error message
         Ada.Text_IO.Close (OS_File);
         Free (Config.Data);

         raise;
      end;

      Ada.Text_IO.Close (OS_File);
   end Parse;

   procedure Set_Value
     (Node   : in Node_Access_Type;
      Value  : in String;
      Line   : in Ada.Text_IO.Count;
      Column : in Ada.Text_IO.Count)
   is begin
      GNAT.OS_Lib.Free (Node.Value);
      Node.Value  := new String'(Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both));
      Node.Line   := Line;
      Node.Column := Column;
   end Set_Value;

   ----------
   --  Public subprograms

   function Base_File_Name (Config : in Configuration_Type) return String
   is begin
      return Config.Error_File_Name.all;
   end Base_File_Name;

   procedure Close (Config : in out Configuration_Type)
   is begin
      Finalize (Config);
   end Close;

   procedure Delete
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is
      Node  : Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Raise_Exception =>
            Ada.Exceptions.Raise_Exception
              (Ada.IO_Exceptions.Name_Error'Identity,
               Config.Error_File_Name.all & ":0:0: " & Key & " not found");
         when Ignore =>
            null;
         end case;
      else
         Free (Node);
      end if;
   end Delete;

   procedure Flush (Config : in Configuration_Type)
   is
      use GNAT.OS_Lib;
      File  : Ada.Text_IO.File_Type;
      Found : String_Access;
   begin
      Check_Open (Config);

      Found := Locate_Regular_File (Config.Writeable_File_Name.all, "");

      if Found = null then
         Ada.Text_IO.Create
           (File, Ada.Text_IO.Out_File, Config.Writeable_File_Name.all);
      else
         Ada.Text_IO.Open
           (File, Ada.Text_IO.Out_File, Config.Writeable_File_Name.all);
      end if;

      if Config.Data.Child /= null then
         Flush (File, Config.Data.Child, "");
      end if;

      Ada.Text_IO.Close (File);
   end Flush;

   procedure Free (Item : in out Configuration_Access_Type)
   is
      procedure Deallocate is new Ada.Unchecked_Deallocation (Configuration_Type, Configuration_Access_Type);
   begin
      Deallocate (Item);
   end Free;

   function Is_Open (Config : in Configuration_Type) return Boolean
   is begin
      return Config.Data /= null;
   end Is_Open;

   procedure Open
     (Config                : in out Configuration_Type;
      Name                  : in     String;
      Error_Handling        : in     Error_Handling_Type := Ignore;
      Read_Only             : in     Boolean             := True;
      Case_Insensitive_Keys : in     Boolean             := True)
   is
      use GNAT.OS_Lib;
      Expanded_Name : constant String := Name;

      Found : String_Access := Locate_Regular_File (Expanded_Name, GNAT.Directory_Operations.Get_Current_Dir);
   begin
      Config.Read_Only             := Read_Only;
      Config.Case_Insensitive_Keys := Case_Insensitive_Keys;

      if Found = null and Config.Search_Path /= null then
         for I in Config.Search_Path.all'Range loop
            Found := Locate_Regular_File (Name, Config.Search_Path (I).all);
            if Found /= null then
               exit;
            end if;
         end loop;
      end if;

      if Found = null then
         --  File does not exist; either report an error, or create an
         --  empty config object and file.

         case Error_Handling is
         when Ignore =>

            Free (Config.Data);

            if Config.Search_Path = null then
               Config.Writeable_File_Name := new String'(GNAT.OS_Lib.Normalize_Pathname (Expanded_Name));
            else
               Config.Writeable_File_Name := new String'
               (GNAT.OS_Lib.Normalize_Pathname (Expanded_Name, Config.Search_Path (1).all));
            end if;

            if not Read_Only then
               --  Create an empty file, to ensure it is a valid file
               --  name in a writeable directory.
               declare
                  use Ada.Text_IO;
                  File : File_Type;
               begin
                  Create (File, Ada.Text_IO.Out_File, Config.Writeable_File_Name.all);
                  Close (File);
               exception
               when others =>
                  declare
                     Temp : constant String := Config.Writeable_File_Name.all;
                  begin
                     Config.Writeable_File_Name := null;
                     Ada.Exceptions.Raise_Exception
                       (Ada.IO_Exceptions.Name_Error'Identity,
                        Temp & " not writeable");
                  end;
               end;
            end if;

            Config.Error_File_Name :=
              new String'(GNAT.Directory_Operations.Base_Name (Config.Writeable_File_Name.all));

            Config.Data := new Node_Type'
              (Tag          => new String'("Config"),
               Value        => null,
               Line         => 0,
               Column       => 0,
               Parent       => null,
               Child        => null,
               Next_Sibling => null);

         when Raise_Exception =>
            Ada.Exceptions.Raise_Exception
              (Ada.IO_Exceptions.Name_Error'Identity,
               Name & " not found");
         end case;

      else
         --  File does exist; read it in.

         Free (Config.Data);

         Config.Data := new Node_Type'
           (Tag          => new String'("Config"),
            Value        => null,
            Line         => 0,
            Column       => 0,
            Parent       => null,
            Child        => null,
            Next_Sibling => null);

         Free (Config.Writeable_File_Name);
         Config.Writeable_File_Name := Found;
         Config.Error_File_Name := new String'(GNAT.Directory_Operations.Base_Name (Found.all));

         Parse (Config);

      end if;

   end Open;

   function Read
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in String              := "";
      Error_Handling : in Error_Handling_Type := Ignore)
      return String
   is
      use type GNAT.OS_Lib.String_Access;
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Node.Value.all;
      end if;
   end Read;

   function Read_Enum
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Enum_Type           := Enum_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
      return Enum_Type
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Enum_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid enumeral");
   end Read_Enum;

   function Read_Fixed
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Fixed_Type          := Fixed_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
      return Fixed_Type
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Fixed_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid fixed point syntax or range");
   end Read_Fixed;

   function Read_Float
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Float_Type          := Float_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
      return Float_Type
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Float_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid floating point syntax or range");
   end Read_Float;

   function Read_Integer
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Integer_Type        := Integer_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
      return Integer_Type
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Integer_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid integer syntax or range");
   end Read_Integer;

   function Read_Modular
     (Config         : in Configuration_Type;
      Key            : in String;
      Default        : in Modular_Type        := Modular_Type'First;
      Error_Handling : in Error_Handling_Type := Ignore)
      return Modular_Type
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Node = null then
         case Error_Handling is
         when Ignore =>
            return Default;
         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         return Modular_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid modular integer syntax or range");
   end Read_Modular;

   procedure Read_String
     (Config         : in     Configuration_Type;
      Key            : in     String;
      Result         :    out String;
      Result_Last    :    out Natural;
      Default        : in     String              := "";
      Error_Handling : in     Error_Handling_Type := Ignore)
   is
      Temp : constant String := Read (Config, Key, Default, Error_Handling);
   begin
      if Temp'Length > Result'Length then
         raise Constraint_Error;
      else
         Result_Last := Result'First + Temp'Length - 1;
         Result (Result'First .. Result_Last) := Temp;
      end if;
   end Read_String;

   procedure Write_Enum
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Enum_Type;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is begin
      Write_String (Config, Key, Enum_Type'Image (Value), Error_Handling);
   end Write_Enum;

   procedure Write_Fixed
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Fixed_Type;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is begin
      Write_String (Config, Key, Fixed_Type'Image (Value), Error_Handling);
   end Write_Fixed;

   procedure Write_Float
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Float_Type;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is begin
      Write_String (Config, Key, Float_Type'Image (Value), Error_Handling);
   end Write_Float;

   procedure Write_Integer
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Integer_Type;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is begin
      Write_String (Config, Key, Integer_Type'Image (Value), Error_Handling);
   end Write_Integer;

   procedure Write_Modular
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     Modular_Type;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is begin
      Write_String (Config, Key, Modular_Type'Image (Value), Error_Handling);
   end Write_Modular;

   procedure Write_String
     (Config         : in out Configuration_Type;
      Key            : in     String;
      Value          : in     String;
      Error_Handling : in     Error_Handling_Type := Ignore)
   is
      Node : constant Node_Access_Type := Find_Node (Config, Key);
   begin
      if Config.Read_Only then
         raise Ada.IO_Exceptions.Use_Error;
      end if;

      if Node = null then
         case Error_Handling is
         when Ignore =>

            Add_Node
              (Config,
               Key,
               Value,
               Line             => 0,
               Column           => 0,
               Case_Insensitive => Config.Case_Insensitive_Keys);

         when Raise_Exception =>
            Key_Not_Found (Config, Key);
         end case;
      else
         Set_Value (Node, Value, Line => 0, Column => 0);
      end if;
   end Write_String;

   function Writeable_File_Name (Config : in Configuration_Type) return String
   is begin
      return Config.Writeable_File_Name.all;
   end Writeable_File_Name;

   ----------
   --  Iterators

   function First
     (Config         : in Configuration_Type;
      Root_Key       : in String              := "";
      Error_Handling : in Error_Handling_Type := Raise_Exception)
     return Iterator_Type
   is
      Temp : Node_Access_Type;
   begin
      if Root_Key = "" then
         return Iterator_Type (Config.Data.Child);
      else
         Temp := Find_Key (Config.Data.Child, Root_Key, Config.Case_Insensitive_Keys);
         if Temp = null then
            case Error_Handling is
            when Raise_Exception =>
               Key_Not_Found (Config, Root_Key);
            when Ignore =>
               return null;
            end case;
         else
            loop
               if Temp.Child /= null then
                  return Iterator_Type (Temp.Child);
               elsif Temp.Next_Sibling /= null then
                  Temp := Temp.Next_Sibling;
               else
                  return null;
               end if;
            end loop;
         end if;
      end if;
   end First;

   function Is_Done (Iterator : in Iterator_Type) return Boolean
   is begin
      return Iterator = null;
   end Is_Done;

   procedure Next (Iterator : in out Iterator_Type)
   is begin
      Iterator := Iterator_Type (Iterator.Next_Sibling);
   end Next;

   function Current (Iterator : in Iterator_Type) return String
   is begin
      return Iterator.Tag.all;
   end Current;

   function File_Line_Column (Config : in Configuration_Type; Iterator : in Iterator_Type) return String
   is begin
      return Format_Line_Column (Config, Iterator.Line, Iterator.Column);
   end File_Line_Column;

   function Line_Column (Iterator : in Iterator_Type) return String
   is
      use Ada.Text_IO, Ada.Strings;
      Line_Image   : constant String := Fixed.Trim (Count'Image (Iterator.Line), Both);
      Column_Image : constant String := Fixed.Trim (Count'Image (Iterator.Column), Both);
   begin
      return Line_Image & ":" & Column_Image & ": ";
   end Line_Column;

   function Read (Iterator : in Iterator_Type) return String
   is begin
      return Iterator.Value.all;
   end Read;

   function Read (Config : in Configuration_Type; Iterator : in Iterator_Type; Leaf : in String) return String
   is
      Node : constant Node_Access_Type := Find_Key (Iterator.Child, Leaf, Config.Case_Insensitive_Keys);
   begin
      if Node = null then
         Key_Not_Found (Config, Iterator, Leaf);
      else
         return Node.Value.all;
      end if;
   end Read;

   function Read_Iterator_Enum
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Enum_Type
   is
      Node : constant Node_Access_Type := Find_Key (Iterator.Child, Leaf, Config.Case_Insensitive_Keys);
   begin
      if Node = null then
         Key_Not_Found (Config, Iterator, Leaf);
      else
         return Enum_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid enumeral");
   end Read_Iterator_Enum;

   function Read_Iterator_Float
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Float_Type
   is
      Node : constant Node_Access_Type := Find_Key (Iterator.Child, Leaf, Config.Case_Insensitive_Keys);
   begin
      if Node = null then
         Key_Not_Found (Config, Iterator, Leaf);
      else
         return Float_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid floating point syntax or range");
   end Read_Iterator_Float;

   function Read_Iterator_Integer
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Integer_Type
   is
      Node : constant Node_Access_Type := Find_Key (Iterator.Child, Leaf, Config.Case_Insensitive_Keys);
   begin
      if Node = null then
         Key_Not_Found (Config, Iterator, Leaf);
      else
         return Integer_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid integer syntax or range");
   end Read_Iterator_Integer;

   function Read_Iterator_Modular
     (Config   : in Configuration_Type;
      Iterator : in Iterator_Type;
      Leaf     : in String)
     return Modular_Type
   is
      Node : constant Node_Access_Type := Find_Key (Iterator.Child, Leaf, Config.Case_Insensitive_Keys);
   begin
      if Node = null then
         Key_Not_Found (Config, Iterator, Leaf);
      else
         return Modular_Type'Value (Node.Value.all);
      end if;
   exception
   when Constraint_Error =>
      Error_Line_Column (Config, Node, "invalid modular syntax or range");
   end Read_Iterator_Modular;

end Config_Files;
