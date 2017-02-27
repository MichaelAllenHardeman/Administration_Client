
------------------------------------------------------------------------------------------------------------------------
--                                                                                                                    --
--  file:        Generic_Client.ads                                                                                   --
--  author:      Michael Hardeman                                                                                     --
--  language:    Ada                                                                                                  --
--  description: Package specifications and functional/procedural prototypes for a generic client                     --
--                                                                                                                    --
------------------------------------------------------------------------------------------------------------------------

with
  Gnat.Sockets,
  Ada.Strings.Unbounded;
use
  Gnat.Sockets,
  Ada.Strings.Unbounded;
package Generic_Client
  is
  -----------
  -- Types --
  -----------
    type Message;
    type Connection;
  ------------------
  -- Access_Types --
  ------------------
    type Access_String
      is access all String;
  -------------
  -- Records --
  -------------
    type Message
      is record
        Origin     : Unbounded_String := Null_Unbounded_String;
        Command    : Unbounded_String := Null_Unbounded_String;
        Parameters : Unbounded_String := Null_Unbounded_String;
      end record;
    type Connection
      is record
        Client  : Socket_Type    := No_Socket;
        Server  : Socket_Type    := No_Socket;
        Address : Sock_Addr_Type := No_Sock_Addr;
        Channel : Stream_Access  := null;
      end record;
  -----------------
  -- Subprograms --
  -----------------
    procedure Initialize(
      Host           : in     String;
      Port           : in     Port_Type;
      The_Connection : in out Connection);
    procedure Wait_For_Connection(
      The_Connection : in out Connection;
      Verify         : access function(
        Item : in String)
        return Boolean);
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
        Result         : in     Boolean));
    procedure Finalize(
      The_Connection : in out Connection);
  end Generic_Client;
