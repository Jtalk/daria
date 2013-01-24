/***********************************************************************
	Copyright (C) 2012 Nazarenko Roman

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
 * Author: Nazarenko Roman <mailto: me@jtalk.me>, Shevchenko Igor
 * License: <http://www.gnu.org/licenses/gpl.html>
 */

/**
	This is a core module for all DNS features. It contains the DNS socket to 
	perform IO operations with the remote DNS server.
*/
module jlib.dns.core;

import std.socket : UdpSocket, Address, InternetAddress, getAddress, SocketOSException, wouldHaveBlocked;
import std.exception : enforce;
import std.array : empty;
debug import std.stdio : writeln;

import jlib.dns.packet;
public import jlib.dns.types;

private const size_t	DNS_HEADER_SIZE = 12; 
private const size_t	DNS_BUFFER_SIZE = 512; /// The size of the receive buffer of the socket			


/**
	dns_socket is a class that makes friendly implementations of the standard 
	DNS resolving routines representing them in readable form.

	It converts some frequently used types (such as A) to the readable form, and
	represents all the other in simple binary form.
 */
class DnsSocket : UdpSocket
{
	/// Server initialization part

	private Address				__dns_server; /// Must be operating system's DNS server
	private immutable ushort	__dns_port = 53; /// Standard DNS port

	/**
		Initializes DNS server with the one presented in the OS configuration.
		Doesn't work for now, just putting a google dns address to the __dns_server 
		variable.
	 
		User classes may recall the init_server routine if something goes
		wrong. 

		Params:
			address	= address of the dns server to connect.
			port	= port of the remote dns server.
	
		Bugs: Doesn't work as well as expected :( 
	 */
	void 
	init_server(string address = "", ushort port = 0)
	{
		address = (address.empty ? "8.8.8.8" : address);
		__dns_server = getAddress(address, ( port ? port : this.__dns_port) )[0];
	}
	
	/// Server connection
	/**
		Binds to the local socket and connects to the remote DNS server represented 
		by __dns_server.
	 */
	void 
	init()
	{
		bind();
		connect(__dns_server);
		__buffer_s = DNS_BUFFER_SIZE;
	}

	/** 
		Binds the socket to the local address. Successors may use it to specify 
		the address, by default connects to the 0.0.0.0 and any free port.
	
		Params: 
			address	= local address to bind
			port	= local port to bind
	 */
	protected void 
	bind(string address = "", ushort port = 0)
	{
		if (port == 0)
			port = InternetAddress.PORT_ANY;
		if (address.length == 0)
			address = "0.0.0.0";
		super.bind(getAddress(address, port)[0]); // May cause a problem
	}
	
public:
	/** 
		The default constructor. Calls all the initial routines and
		makes the class ready to work with DNS.
	 */
	this() 
	{
		super();
		init_server();	
		init();
	}

	/** 
		Constructor. Makes us able to choose DNS server address and port. Calls all the initial routines and
		makes the class ready to work with the DNS.
	*/
	this(string address, ushort port = 0)
	{
		super();
		init_server(address, port);
		init();
	}

	/** 
		Destructor. Frees the dns server variable (to use in non-GC systems), but 
		feature may work wrong.

		FIX: now makes nothing since GC is not able to handle memory deletion.
	 */
	~this() 
	{
		//delete __dns_server; // Damn GC, it falls if memory is already cleared.
	}
	
	/// IO operations
	private uint __buffer_s; // 

	/** 
		Sends the packet to the DNS server in this class. 
	
		Note that function doesn't look whether packet is a correct DNS packet, 
		it's too expensive and useless. Just look after your app. ;) 
	
		Params: 
			packet = a packet to send. 
	
		Throws: 
			Exception if Socket.send fails.
	*/
	void 
	send(Packet packet) 
	{ 
		// TODO: Put getErrorText() to the exception's message. 
		// There was some issues with that when I tried.
		enforce( 
			   super.send(cast (void[]) packet.makePacket()) > 0, 
			   "Unable to send in dns_socket.send()");
	}
	
	/**
		Receives the packet. 
	
		Returns: 
			Packet class with all the data received. 
	
		Throws: 
		Exception:	if receive falls, Packet constructon may throw the Exception
					too if packet is malformed (look at the Packet's documentation.
	*/
	Packet 
	receive()
	{
		// TODO: Put getErrorText() to the exception's message. 
		// There was some issues with that when I tried.
		ubyte[] buffer = new ubyte[ __buffer_s ];
		size_t received = super.receive(buffer);
		enforce( 
				 received > 0, 
				wouldHaveBlocked() ? "empty" : "Error while receive");
		return new Packet(buffer[ 0 .. received]);
	}
	
	/// Properties
	@property
	{
		/**
			This is the way to change DNS server's address directly from the 
			application. 

			Params:
				new_addr = string with the address to replace with.

			Returns:
				string with the current DNS address.

			It will not work without rebinding.
		*/
		string address() { return __dns_server.toAddrString; }
		string address(string new_addr) { __dns_server = getAddress( new_addr, this.__dns_port)[0]; return new_addr; }

		/**
			Socket's receive buffer size property.

			Params:
				newsize = new size of the receive buffer.

			Returns:
				current size of the receive buffer.
		*/
		size_t buffer_s() { return __buffer_s; }
		size_t buffer_s(size_t newsize) { __buffer_s = newsize > 0 ? newsize : DNS_BUFFER_SIZE; return __buffer_s; }
	}
}