/***********************************************************************
Copyright (C) 2012-2013 Roman Nazarenko.

GNU GENERAL PUBLIC LICENSE - Version 3 - 29 June 2007

This file is part of Daria project.

Daria is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Daria is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Daria. If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

/**
* Author: Nazarenko Roman <mailto: me@jtalk.me>
* License: <http://www.gnu.org/licenses/gpl.html>
*/

/**
  HTTP proxy class. 
*/

module jlib.proxy.core;

import std.socket;
import std.conv : text;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.exception : enforce;
debug import std.cstream;
import dbg;


private const size_t  PROXY_BUFFER_SIZE = 1024*4;  

class Proxy : Socket
{
  alias Proxy  reference;
private:    
  static
  {
    public const Address default_address;
    
    static this()
    {
      default_address = getAddress("localhost", 2013)[0];
    }
  }
  
  void bindLocal(const Address toListen) {
    report!2("Trying to bind proxy server at ", toListen.text);
    bind(cast(Address)toListen);
    report!2("Success!");
  }
  
public:  
  this() {
    super();
  }
  this(const Address toListen) {
    super(Socket.addressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    bindLocal(toListen);
  }
  this(ushort port) {
    super(Socket.addressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    const Address toListen = port != 0 ? getAddress("localhost", port)[0] : default_address;
    bindLocal(toListen);
  }
  ~this() {}
  
  protected override Socket accepting()
  {
    return new reference;
  }
  
  override ptrdiff_t send(const(void)[] data)
  {
    ptrdiff_t ret = super.send(data);
    enforce(ret > 0, r"Socket send error");
    return ret; // stupid language
  }
  
  ubyte[] receive()
  {
    ubyte[] buffer = new ubyte[ PROXY_BUFFER_SIZE ];
    size_t received = super.receive(buffer);
    enforce(received > 0, r"Socket receive error");
    return buffer[ 0 .. received];
  }
  
  override void connect(Address)
  {
    assert(0, r"Connection from proxy server isn't allowed");
  }
  
  private alias Socket.accept oldAccept;
  override reference accept()
  {
    return cast(reference) super.accept();
  }
}