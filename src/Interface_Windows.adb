------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                             A - A D A I N T                              --
--                                                                          --
--                            $Revision: 1.10$                              --
--                                                                          --
--                               C Body File                                --
--                                                                          --
--   Copyright (C) 1992,1993,1994,1995,1996 Free Software Foundation, Inc.  --
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
-- As a  special  exception,  if you  link  this file  with other  files to --
-- produce an executable,  this file does not by itself cause the resulting --
-- executable to be covered by the GNU General Public License. This except- --
-- ion does not  however invalidate  any other reasons  why the  executable --
-- file might be covered by the  GNU Public License.                        --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- It is now maintained by Ada Core Technologies Inc (http://www.gnat.com). --
--                                                                          --
------------------------------------------------------------------------------
-- Had to rip out the section I needed, change something and rewrite in Ada --

package body Interface_Windows
  is
  -----------
  -- Mutex --
  -----------
    task body Mutex
      is
      Section : Access_Critical_Section := new Critical_Section;
      begin
        Initialize_Critical_Section(Section);
        loop
          delay 0.0;
          select
            accept Enter;
              Enter_Critical_Section(Section);
            or accept Leave;
              Leave_Critical_Section(Section);
              exit; -- loop
            else
              null;
          end select;
        end loop;
      end Mutex;
  ----------------
  -- Add_Handle --
  ----------------
    procedure Add_Handle(
      Process_Handle : in System.Address)
      is
      Task_Critical_Section : Mutex;
      New_Process_For_List  : Access_Process_List := new Process_List;
      begin
        ----------------------------
        Task_Critical_Section.Enter;
        ----------------------------
          New_Process_For_List.Process_Handle := Process_Handle;
          New_Process_For_List.Next := Process_List_Root;
          Process_List_Root := New_Process_For_List;
          Process_List_Length := Process_List_Length + 1;
        ----------------------------
        Task_Critical_Section.Leave;
        ----------------------------
      end Add_Handle;
  -------------------
  -- Remove_Handle --
  -------------------
    procedure Remove_Handle(
      Process_Handle : in System.Address)
      is
      Task_Critical_Section : Mutex;
      Process_To_Remove     : Access_Process_List := null;
      Previous_Process      : Access_Process_List := null;
      procedure Free
        is new Ada.Unchecked_Deallocation(Process_List, Access_Process_List);
      use System;
      begin
        ----------------------------
        Task_Critical_Section.Enter;
        ----------------------------
          Process_To_Remove := Process_List_Root;
          while Process_To_Remove /= null loop
            if Process_To_Remove.Process_Handle = Process_Handle then
              if Process_To_Remove = Process_List_Root then
                Process_List_Root := Process_To_Remove.Next;
              else
                Previous_Process.Next := Process_To_Remove.Next;
              end if;
              Free(Process_To_Remove);
              exit;
            else
              Previous_Process  := Process_To_Remove;
              Process_To_Remove := Process_To_Remove.Next;
            end if;
          end loop;
          Process_List_Length := Process_List_Length - 1;
        ----------------------------
        Task_Critical_Section.Leave;
        ----------------------------
      end Remove_Handle;
  ----------------------------------------
  -- Windows_Non_Blocking_Process_Spawn --
  ----------------------------------------
    function Windows_Non_Blocking_Process_Spawn(
      Command    : in String;
      Parameters : in String)
      return Integer
      is
      function Address_To_Integer
        is new Ada.Unchecked_Conversion(Source => System.Address, Target => Integer);
      use Ada.Strings.Fixed;
      use Interfaces.C.Strings;
      Result              : Interfaces.C.Int           := -1;
      Information_Startup : Access_Startup_Information := new Startup_Information;
      Information_Process : Access_Process_Information := new Process_Information;
      Attributes_Security : Access_Security_Attributes := new Security_Attributes;
      Full_Command        : Chars_Ptr                  := New_String(Trim(Command & " " & Parameters, Ada.Strings.Both));
      begin
        -- Startup Info --
        Information_Startup.all.cb             := Startup_Information'Size;
        Information_Startup.all.Reserved_Char  := Null_Ptr;
        Information_Startup.all.Reserved_Short := 0;
        Information_Startup.all.Desktop        := Null_Ptr;
        Information_Startup.all.Reserved_Byte  := null;
        Information_Startup.all.Title          := Null_Ptr;
        Information_Startup.all.Flags          := 0;
        Information_Startup.all.Show_Window    := SW_HIDE;
        -- Security Attributes --
        Attributes_Security.all.Length              := Security_Attributes'Size;
        Attributes_Security.all.Inherit_Handle      := 1;
        Attributes_Security.all.Security_Descriptor := System.Null_Address;
        -- Create Process --
        Result := Create_Process(
          Null_Ptr,
          Full_Command,
          Attributes_Security,
          System.Null_Address,
          1,
          NORMAL_PRIORITY,
          System.Null_Address,
          Null_Ptr,
          Information_Startup,
          Information_Process);
        if Result = 1 then
          Add_Handle(Information_Process.Process_Handle);
          Result := Close_Handle(Information_Process.Thread_Handle);
          return Address_To_Integer(Information_Process.Process_Handle);
        end if;
        return -1;
      end Windows_Non_Blocking_Process_Spawn;
  end Interface_Windows;
