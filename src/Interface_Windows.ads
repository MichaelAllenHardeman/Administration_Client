------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                             A - A D A I N T                              --
--                                                                          --
--                            $Revision: 1.10$                              --
--                                                                          --
--                              C Header File                               --
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

with
  System,
  Interfaces.C,
  Interfaces.C.Strings,
  Ada.Strings.Fixed,
  Ada.Unchecked_Conversion,
  Ada.Unchecked_Deallocation;
use
  Interfaces.C;
package Interface_Windows
  is
  -----------
  -- Types --
  -----------
    type Process_List;
    type List_Entry;
    type Critical_Section;
    type Critical_Section_Debug;
    type Startup_Information;
    type Process_Information;
    type Security_Attributes;
    type Byte
      is new Interfaces.C.Unsigned_Char;
    type Void_Array
      is array(Natural range <>) of aliased System.Address;
  ------------------
  -- Access_Types --
  ------------------
    type Access_Process_List
      is access all Process_List;
    type Access_List_Entry
      is access all List_Entry;
    type Access_Critical_Section
      is access all Critical_Section;
    type Access_Critical_Section_Debug
      is access all Critical_Section_Debug;
    type Access_Startup_Information
      is access all Startup_Information;
    type Access_Process_Information
      is access all Process_Information;
    type Access_Security_Attributes
      is access all Security_Attributes;
    type Access_Byte
      is access all Byte;
    type Access_Word
      is access all Interfaces.C.Unsigned_Short;
    type Access_Int
      is access all Interfaces.C.Int;
    type Access_Dword
      is access all Interfaces.C.Unsigned_Long;
    type Access_Void_Array
      is access all Void_Array;
  -------------
  -- Records --
  -------------
  --winuser.LIST_ENTRY    
    type List_Entry
      is record
        Forward  : Access_List_Entry;
        Backward : Access_List_Entry;
      end record;
  --wininit.RTL_CRITICAL_SECTION
    type Critical_Section
      is record
        Debug_Info      : Access_Critical_Section_Debug;
        Lock_Count      : Interfaces.C.Long;
        Recursion_Count : Interfaces.C.Long;
        Owning_Thread   : System.Address;
        Lock_Semaphore  : System.Address;
        Reserved        : Interfaces.C.Unsigned_Long;
      end record;
  --wininit.RTL_CRITICAL_SECTION_DEBUG
    type Critical_Section_Debug
      is record
        C_Type                   : Interfaces.C.Unsigned_Short;
        Creator_Back_Trace_Index : Interfaces.C.Unsigned_Short;
        Critical_Section         : Access_Critical_Section;
        Process_Locks_List       : List_Entry;
        Entry_Count              : Interfaces.C.Unsigned_Long;
        Contention_Count         : Interfaces.C.Unsigned_Long;
        Depth                    : Interfaces.C.Unsigned_Long;
        Owner_Back_Trace         : Access_Void_Array(0..4);
      end record;
  --winbase.STARTUPINFOA
    type Startup_Information
      is record
        cb              : Interfaces.C.Unsigned_Long;
        Reserved_Char   : Interfaces.C.Strings.Chars_Ptr;
        Desktop         : Interfaces.C.Strings.Chars_Ptr;
        Title           : Interfaces.C.Strings.Chars_Ptr;
        X               : Interfaces.C.Unsigned_Long;
        Y               : Interfaces.C.Unsigned_Long;
        X_Size          : Interfaces.C.Unsigned_Long;
        Y_Size          : Interfaces.C.Unsigned_Long;
        X_Count_Chars   : Interfaces.C.Unsigned_Long;
        Y_Count_Chars   : Interfaces.C.Unsigned_Long;
        Fill_Attribute  : Interfaces.C.Unsigned_Long;
        Flags           : Interfaces.C.Unsigned_Long;
        Show_Window     : Interfaces.C.Unsigned_Short;
        Reserved_Short  : Interfaces.C.Unsigned_Short;
        Reserved_Byte   : Access_Byte;
        Standard_Input  : System.Address;
        Standard_Output : System.Address;
        Standard_Error  : System.Address;
      end record;
  --winbase. PROCESS_INFORMATION
    type Process_Information
      is record
        Process_Handle : System.Address;
        Thread_Handle  : System.Address;
        Process_ID     : Interfaces.C.Unsigned_Long;
        Thread_ID      : Interfaces.C.Unsigned_Long;
      end record;
  --winbase.SECURITY_ATTRIBUTES
    type Security_Attributes
      is record
        Length              : Interfaces.C.Unsigned_Long;
        Security_Descriptor : System.Address;
        Inherit_Handle      : Interfaces.C.Int;
      end record;  
  --Gnat.adaint._process_list
    type Process_List
      is record
        Process_Handle : System.Address;
        Next           : Access_Process_List;
      end record;
  ---------------
  -- Constants --
  ---------------
  --winuser.SW_HIDE
  --winbase.NORMAL_PRIORITY_CLASS  
  --winbase.INFINITE  
  --wininit.STATUS_WAIT_0
    SW_HIDE         : constant Interfaces.C.Unsigned_Short := 0;
    NORMAL_PRIORITY : constant Interfaces.C.Unsigned_Long  := 16#20#;
    INFINITE        : constant Interfaces.C.Unsigned_Long  := 16#ffffffff#;
    STATUS_WAIT_0   : constant Interfaces.C.Unsigned_Long  := 16#0#;
  -----------------
  -- Subprograms --
  -----------------
  --winbase.InitializeCriticalSection
    procedure Initialize_Critical_Section(
      Pointer_Critical_Section : in Access_Critical_Section);
  --winbase.EnterCriticalSection
    procedure Enter_Critical_Section(
      Pointer_Critical_Section : in Access_Critical_Section);
  --winbase.LeaveCriticalSection
    procedure Leave_Critical_Section(
      Pointer_Critical_Section : in Access_Critical_Section);
  --winbase.CreateProcessA
    function Create_Process(
      Application_Name   : in Interfaces.C.Strings.Chars_Ptr;
      Command_Line       : in Interfaces.C.Strings.Chars_Ptr;
      Process_Attributes : in Access_Security_Attributes;
      Thread_Attributes  : in System.Address;
      Inherit_Handles    : in Interfaces.C.Int;
      Creation_Flags     : in Interfaces.C.Unsigned_Long;
      Environment        : in System.Address;
      Current_Directory  : in Interfaces.C.Strings.Chars_Ptr;
      Startup_Info       : in Access_Startup_Information;
      Process_Info       : in Access_Process_Information)
      return Interfaces.C.Int;
  --winbase.CloseHandle
    function Close_Handle(
      Object_Handle : in System.Address)
      return Interfaces.C.Int;
  --Gnat.adaint.add_handle
    procedure Add_Handle(
      Process_Handle : in System.Address);
  --Gnat.adaint.remove_handle
    procedure Remove_Handle(
      Process_Handle : in System.Address);
  --Gnat.adaint.win32_no_block_spawn
    function Windows_Non_Blocking_Process_Spawn(
      Command    : in String;
      Parameters : in String)
      return Integer;
  ----------------
  -- Directives --
  ----------------
    pragma Convention( C , List_Entry);
    pragma Convention( C , Critical_Section);
    pragma Convention( C , Critical_Section_Debug);
    pragma Convention( C , Process_List);
    pragma Convention( C , Startup_Information);
    pragma Convention( C , Process_Information);
    pragma Convention( C , Security_Attributes);
    pragma Import(Stdcall, Initialize_Critical_Section, "InitializeCriticalSection");
    pragma Import(Stdcall, Enter_Critical_Section,      "EnterCriticalSection");
    pragma Import(Stdcall, Leave_Critical_Section,      "LeaveCriticalSection");
    pragma Import(Stdcall, Create_Process,              "CreateProcessA");
    pragma Import(Stdcall, Close_Handle,                "CloseHandle");
  ---------------
  -- Variables --
  ---------------
  --Gnat.adaint.PLIST;
  --Gnat.adaint.plist_length;
    Process_List_Root   : Access_Process_List := new Process_List;
    Process_List_Length : Interfaces.C.Int    := 0;
  -----------
  -- Tasks --
  -----------
  -- Yo dawg...
    task type Mutex
      is
        entry Enter;
        entry Leave;
      end Mutex;
  end Interface_Windows;
