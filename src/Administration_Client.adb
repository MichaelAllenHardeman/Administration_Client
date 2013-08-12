
------------------------------------------------------------------------------------------------------------------------
--                                                                                                                    --
--  file:        Administration_Client.adb                                                                            --
--  author:      mhardeman25@gmail.com                                                                                --
--  language:    Ada, put on your big boy pants please.                                                               --
--  description: Main Procedure of the client program, and Implementation of the Generic Client                       --
--                                                                                                                    --
------------------------------------------------------------------------------------------------------------------------
-- Inside every well-written large program is a well-written small program. ~Charles Antony Richard Hoare

with
  Ada.Streams,
  Ada.Strings,
  Ada.Strings.Fixed,
  Ada.Strings.Unbounded,
  Gnat.Os_Lib,
  Gnat.Regpat,
  Gnat.Sockets,
  Generic_Client,
  Interface_Windows,
  System,
  Interfaces.C;
use
  Ada.Streams,
  Ada.Strings.Unbounded,
  Gnat.Sockets,
  Generic_Client,
  Interface_Windows;
procedure Administration
  is
  ---------------
  -- Constants --
  ---------------
    HOST             : constant String    := "localhost";
    PORT             : constant Port_Type := 31534;
    ACCEPTED_ORIGIN  : constant String    := "127.0.0.1";
    MESSAGE_QUIT     : constant String    := "quit";
    WINDOWS          : constant String    := "C:\Windows\";
    SYSTEM_32        : constant String    := WINDOWS & "System32\";
    PROGRAM_FILES_64 : constant String    := "C:\Program Files (x86)\";
    PROGRAM_FILES_32 : constant String    := "C:\Program Files\";
    IS_x64           : constant Boolean   := Gnat.Os_Lib.Is_Directory(PROGRAM_FILES_64);
    VNC_64           : constant String    := PROGRAM_FILES_64 & "UltraVNC\vncviewer.exe";
    VNC_32           : constant String    := PROGRAM_FILES_32 & "UltraVNC\vncviewer.exe";          
    MSTSC            : constant String    := SYSTEM_32 & "mstsc.exe";
    EXPLORE          : constant String    := WINDOWS & "explorer.exe";
    PING             : constant String    := "ping.bat";
    PUTTY            : constant String    := "putty.exe";
    IE_64            : constant String    := PROGRAM_FILES_64 & "Internet Explorer\iexplore.exe";
    IE_32            : constant String    := PROGRAM_FILES_32 & "Internet Explorer\iexplore.exe";
    COMMAND_RE       : constant String    := "Command=(.*)&";
    PARAMETERS_RE    : constant String    := "Parameters=(.*)[\s]*HTTP";    
    LINE_ENDING      : constant String    := ASCII.CR & ASCII.LF;
    CORS_RESPONSE    : constant String    :=
      "HTTP/1.1 200 OK"                                   & LINE_ENDING &
      "Server: Custom-Gnat-Client-v1.0"                   & LINE_ENDING &
      "Access-Control-Allow-Origin: http://127.0.0.1"     & LINE_ENDING &
      "Connection: Close"                                 & LINE_ENDING &
      "Content-Length: 26"                                & LINE_ENDING &
      "Content-Type: text/html"                           & LINE_ENDING & LINE_ENDING ;
    SUCCESS : constant String := "<result>true </result>" & LINE_ENDING & LINE_ENDING ;
    FAILURE : constant String := "<result>false</result>" & LINE_ENDING & LINE_ENDING ;
  ----------------------------
  -- Run_Regular_Expression --
  ----------------------------
    procedure Run_Regular_Expression(
      Expression    : in  String;
      Search_String : in  String;
      First_Index   : out Positive;
      Last_Index    : out Positive;
      Is_Found      : out Boolean)
      is
      Compiled_Expression : Gnat.Regpat.Pattern_Matcher     := Gnat.Regpat.Compile(Expression);
      Indicies_Of_Result  : Gnat.Regpat.Match_Array(0 .. 1) := (others => Gnat.Regpat.No_Match);
      begin
        Gnat.Regpat.Match(Compiled_Expression, Search_String, Indicies_Of_Result);
        Is_Found := not Gnat.Regpat."="(Indicies_Of_Result(1), Gnat.Regpat.No_Match);
        if Is_Found then
          First_Index := Indicies_Of_Result(1).First;
          Last_Index  := Indicies_Of_Result(1).Last;
        end if;
      end Run_Regular_Expression;
  -------------------------
  -- Extract_From_String --
  -------------------------
    function Extract_From_String(
      Expression : in String;
      Message    : in String)
      return String
      is
      First  : Positive := 1; 
      Last   : Positive := 1;
      Found  : Boolean  := False;
      begin
        Run_Regular_Expression(
          Expression,
          Message,
          First, 
          Last, 
          Found);
        if Found then
          return Message(First .. Last);
        end if;
        return " ";
      end Extract_From_String;
  ---------------------
  -- Execute_Locally --
  ---------------------
    function Execute_Locally(
      Command    : in String;
      Parameters : in String)
      return Boolean
      is
      begin
        return (Windows_Non_Blocking_Process_Spawn(Command, Parameters) /= -1);
      end Execute_Locally;
  ---------------------------
  -- Administration_Verify --
  ---------------------------
    function Administration_Verify(
      Item : in String)
      return Boolean
      is
        Origin : String := Extract_From_String(
          "([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):[0-9]+",
          Item);
      begin
        if Origin = ACCEPTED_ORIGIN then
          return True;
        else
          return False;
        end if;
      end Administration_Verify;
  ----------------------------------
  -- Administration_Parse_Message --
  ----------------------------------
    procedure Administration_Parse_Message(
      The_Connection : in out Connection;
      The_Message    : in out Message)
      is
      Data         : Ada.Streams.Stream_Element_Array (1..1) := (others => Ada.Streams.Stream_Element'First);
      Offset       : Ada.Streams.Stream_Element_Count        := Ada.Streams.Stream_Element_Count'First;
      Buffer       : Access_String                           := new String(1..1024);
      Buffer_Index : Natural                                 := Natural'First;
      begin
        loop
          Ada.Streams.Read(The_Connection.Channel.all, Data (1..1), Offset);
          if(Offset /= 0) then
            Buffer_Index := Buffer_Index + 1;
            Buffer.all(Buffer_Index) := Character'Val(Data(1));
            exit when
              Character'Val(Data(1)) = ASCII.NUL or (
              Buffer_Index >= 4 and then 
              Buffer.all((Buffer_Index-3)..Buffer_Index) = (LINE_ENDING & LINE_ENDING));
          end if;
        end loop;
        declare
          Http_Packet : String := Buffer(1..Buffer_Index);
        begin
          The_Message.Command    := To_Unbounded_String(Extract_From_String(COMMAND_RE,    Http_Packet));
          The_Message.Parameters := To_Unbounded_String(Extract_From_String(PARAMETERS_RE, Http_Packet));
        end;
      end Administration_Parse_Message;
  ------------------------------------
  -- Administration_Process_Message --
  ------------------------------------
    procedure Administration_Process_Message(
      The_Connection : in out Connection;
      The_Message    : in out Message;
      Result         :    out Boolean)
      is
      Command        : String       := Ada.Strings.Unbounded.To_String(The_Message.Command);
      Parameters     : String       := Ada.Strings.Unbounded.To_String(The_Message.Parameters);
      begin
        if Command = "vncviewer" then
          if IS_x64 then
            Result := Execute_Locally(VNC_64, Parameters);
          else
            Result := Execute_Locally(VNC_32, Parameters);
          end if;
        elsif Command = "mstsc" then
          Result := Execute_Locally(MSTSC, "/v:" & Parameters);
        elsif Command = "explore" then
          Result := Execute_Locally(EXPLORE, "\\" & Parameters & "\C$");
        elsif Command = "ping" then
          Result := Execute_Locally(PING, Parameters);
        elsif Command = "ping%20-a" then
          Result := Execute_Locally(PING, Parameters);
        elsif Command = "putty%20-telnet" then
          Result := Execute_Locally(PUTTY, "-telnet" & " " & Parameters);
        elsif Command = "putty%20-ssh" then
          Result := Execute_Locally(PUTTY, "-ssh" & " " & Parameters);
        elsif Command = "iexplore" then
          if IS_x64 then
            Result := Execute_Locally(IE_64, Parameters);
          else
            Result := Execute_Locally(IE_32, Parameters);
          end if;
        else
          Result := False;
        end if;
      end Administration_Process_Message;
  ----------------------------------
  -- Administration_Send_Response --
  ----------------------------------
    procedure Administration_Send_Response(
      The_Connection : in out Connection;
      Result         : in     Boolean)
      is
      begin
        String'Write(The_Connection.Channel, CORS_RESPONSE);
        if Result = True then
          String'Write(The_Connection.Channel, SUCCESS);
        else
          String'Write(The_Connection.Channel, FAILURE);
        end if;
      end Administration_Send_Response;
  ---------------
  -- Variables --
  ---------------
    The_Connection : Connection;
    The_Message    : Message;
  ----------
  -- Main --
  ----------
  begin
    Generic_Client.Initialize(HOST, PORT, The_Connection);
    loop
      Generic_Client.Wait_For_Connection(
        The_Connection,
        Administration_Verify'Access);
      Generic_Client.Handle_Connection(
        The_Connection,
        The_Message,
        Administration_Parse_Message'Access,
        Administration_Process_Message'Access,
        Administration_Send_Response'Access);
      exit when The_Message.Command = MESSAGE_QUIT;
    end loop;
    Generic_Client.Finalize(The_Connection);
  end Emory_Client;
  