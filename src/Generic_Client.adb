
------------------------------------------------------------------------------------------------------------------------
--                                                                                                                    --
--  file:        Generic_Client.adb                                                                                   --
--  author:      Michael Hardeman                                                                                     --
--  language:    Ada                                                                                                  --
--  description: Procedural/Functional implementation of package specification for generic client                     --
--                                                                                                                    --
------------------------------------------------------------------------------------------------------------------------

package body Generic_Client
  is
  ----------------
  -- Initialize --
  ----------------
    procedure Initialize(
      Host           : in     String;
      Port           : in     Port_Type;
      The_Connection : in out Connection)
      is
      begin
        Gnat.Sockets.Initialize;
        The_Connection.Address.Addr := Addresses(Get_Host_By_Name(Host), 1);
        The_Connection.Address.Port := Port;
        Create_Socket(The_Connection.Client);
        Set_Socket_Option(The_Connection.Client, Socket_Level, (Reuse_Address, True));
        Bind_Socket(The_Connection.Client, The_Connection.Address);
        Listen_Socket(The_Connection.Client);
      end Initialize;
  -------------------------
  -- Wait_For_Connection --
  -------------------------
    procedure Wait_For_Connection(
      The_Connection : in out Connection;
      Verify         : access function(
        Item : in String)
        return Boolean)
      is
        Is_Verified : Boolean := false;
      begin
        if The_Connection.Channel = null then
          while not Is_Verified loop
            Accept_Socket(
              The_Connection.Client, 
              The_Connection.Server, 
              The_Connection.Address);
            Is_Verified := Verify(Image(Get_Address(Stream(The_Connection.Server))));
          end loop;
          The_Connection.Channel := Stream(The_Connection.Server);
        else
          null;
          -- TODO: Handle error here.
        end if;
      end Wait_For_Connection;
  -----------------------
  -- Handle_Connection --
  -----------------------
    procedure Handle_Connection(
      The_Connection   : in out Connection;
      The_Message      : in out Message;
      Parse_Message    : access procedure(
        The_Connection : in out Connection;
        The_Message    : in out Message);
      Process_Message  : access procedure(
        The_Connection : in out Connection;
        The_Message    : in out Message;
        Result         :    out Boolean);
      Send_Response    : access procedure(
        The_Connection : in out Connection;
        Result         : in     Boolean))
      is
      Result : Boolean := False;
      begin
        Parse_Message(The_Connection, The_Message);
        Process_Message(The_Connection, The_Message, Result);
        Send_Response(The_Connection, Result);
        Close_Socket(The_Connection.Server);
        The_Connection.Channel := null;
      end Handle_Connection;
  --------------
  -- Finalize --
  --------------
    procedure Finalize(
      The_Connection : in out Connection)
      is
      begin
        Close_Socket(The_Connection.Client);
        Gnat.Sockets.Finalize;
      end Finalize;
  end Generic_Client;
  
