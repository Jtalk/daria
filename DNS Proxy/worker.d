/***********************************************************************
	Copyright (C) 2012 Nazarenko Roman

	GNU GENERAL PUBLIC LICENSE - Version 3 - 29 June 2007

	This file is part of DNS Proxy project.

	DNS Proxy is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	DNS Proxy is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with DNS Proxy. If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

/**
* Author: Nazarenko Roman <mailto: me@jtalk.me>, Schevchenko Igor
* License: <http://www.gnu.org/licenses/gpl.html>
*/

/**
	This is a core module for dns proxy worker thread.
*/

module worker;

import core.thread;
import std.stdio;
import std.cstream;
import std.base64;
import std.random : uniform;
import std.exception;
import std.string;
import std.conv : text, parse;
import std.math : ceil;
import std.algorithm;

import jlib.dns.dns;
import jlib.proxy.proxy;
import routines;

private import types;


string[] 
cut( string str, size_t num) 
{
	string[] buffer;
	for (size_t i; i < num; ++i)
		buffer ~= str[i * num .. min((i+1) * num, $)];
	return buffer;
}

ubyte[] 
makeDomain( string[] parts...) 
{
	string buffer;
	foreach( part; parts)
		buffer ~= ( part ~ '.');
	return cast(ubyte[]) buffer;
}

class Worker : Thread
{
private:

	UserID		__userID = void;
	string		__login = void;
	DnsSocket	__dns_socket = void;
	Proxy		__proxy = void;
	string		__domain = void;
	string		token = void;
	string[]	parts = void;

public:
	this( string login, UserID userID, DnsSocket dns_socket, Proxy proxy, string domain)
	{
		__login = login;
		__userID = userID;
		__dns_socket = dns_socket;
		__proxy = proxy;
		__domain = domain;
		super( &run);
		this.start();
	}

private:
	void
	control( string T, string toControl) 
	{
		// We need it to be higher to prevent access violation when toControl is less than T
		if (toControl.length < T.length)
			toControl ~= "000000";
		static assert( ERROR.length <= "000000".length ); // Looks if error became too long someways.

		// Converts answer status header to lower case.
		enforce(
				toLower( toControl[ 0 .. T.length]) == T, 
				"Server error: " ~ toControl
				);
	}

	

	void 
	sendParts( string[] parts, size_t[] numbers = null)
	{
		void send( size_t to_send)
		{
			ubyte[] domain = makeDomain( token, text(to_send), parts[to_send], __domain);
			debug dout.writeLine("Domain: \n" ~ cast(string)domain ~ "\n--------------------------------------------------------------");
			debug dout.flush();

			string toControl = io( domain, SEND).getData(0);
			handle!SEND(toControl);
		}

		if ( numbers == null)
			for( int i; i < parts.length; i++) 
				send( i);
		else
			foreach( i ; numbers)
				send( i);
	}

	string[] 
	receiveParts(size_t number)
	in
	{
		static assert( bool.init == false);
		assert( number, "Number == 0 in Worker.receiveParts()");
	}
	body
	{
		debug dout.writeLine( "Start receiving, n = " ~ text( number));
		debug dout.flush();

		string[] buffer;
		bool[] received;
		buffer.length = number;
		received.length = buffer.length;


		// Going through all the packets
		while ( canFind( received, false))
		{
			for ( size_t i ; i < number ; i++)
			{
				if ( received[i] == true) 
					continue;

				Packet recv = io( makeDomain( token, text(i), __domain), RECV);
				size_t num = getNumber( cast(string) recv.getQuestion().domain);

				string data = handle!RECV( recv.getData());

				debug dout.writeLine( "Part "~ text( i) ~ " is received: \n" ~ data ~ "\n--------------------------------------------------");
				debug dout.flush();

				if (data) 
				{
					buffer[num] = data;
					received[num] = true;
				}
			}
		}
		return buffer;
	}

	size_t 
	getLost()
	{
		size_t ready;
		while ( !ready)
		{
			ubyte[] domain = makeDomain( token, text( uniform( 1000, 9999)), __domain);
			string answer = io(domain, STATUS).getData();
			debug dout.writeLine("Status has been received: " ~ answer);
			debug dout.flush();

			ready = handle!(STATUS)( answer);
		}
		return ready;
	}

	Packet 
	io( ubyte[] domain, ushort type) 
	{
		Packet packet = new Packet();
		packet.id = uniform!(ushort)();
		packet.flags = FLAGS;

		Packet.Question quest;
		quest.domain = domain;

		quest.type = type;
		
		packet.addQuestion(quest);

		__dns_socket.send(packet);

		return __dns_socket.receive();
	}


	void
	need( string data) 
	{
		auto needs = parseNeeds( data);
		foreach( Need ; needs) 
		{
			string recv = io( makeDomain( token, text(Need), parts[Need], __domain), SEND).getData();
			handle!STATUS( recv);
		}
	}

	void 
	run()
	{
		ubyte[] data = __proxy.receive();
		debug dout.writeLine( cast(string) data);
		debug dout.writeLine("------------------------------------------------------------------");

		// Data encoding
		string encoded = cast(string) Base64URL.encode(data);
		encoded = removeBase64Suffix(encoded);
	
		debug dout.writeLine( encoded);
		debug dout.writeLine("------------------------------------------------------------------");
		debug dout.flush();

		// Getting token. ------------------------------------------------------------------------
		// Counting parameters needed:
		// Maximum length of the one packet:
		real chunk_length =
			jlib.dns.types.DNS_PACKET_MAXLEN	// Maximum possible length of the DNS packet
			- jlib.dns.types.DNS_HEADER_SIZE	// Size of the DNS header
			-  __domain.length				// Main domain length
			- TOKEN_MAXLEN					// Token length
			- INDEX_MAXLEN					// Maximum length of the index of a current part
			- PROTO_PARTS_MAXSIZE;			// Maximum parts per request in protocol we use

		// Number of parts of our data:
		auto index_count = cast(size_t)ceil( cast(real)encoded.length / chunk_length);

		// Requesting token.
		{
			// Create a url from all data provided.
			ubyte[] domain = makeDomain( __login, __userID, text(index_count), __domain);

			// Send it and get a response.
			string answer = io(domain, REGISTRATION).getData();

			// We have a token!
			control(TOKEN,answer);
			token = answer[TOKEN.length .. $];
			debug dout.writeLine("Token found: " ~ text(token) ~ "\nSending data...");
			debug dout.flush();
		}
		// Token has been got. ----------------------------------------------------------------

		// Sending all the data to the server. ------------------------------------------------
		// Cut encoded data into index_count parts.
		parts = cut( encoded, index_count);
		sendParts( parts);		
		// All parts have been sent. ----------------------------------------------------------

		// Getting lost. ----------------------------------------------------------------------
		size_t ready = getLost();
		debug dout.writeLine("Server received all parts successfully... recieving answer is started");
		debug dout.flush();
		// All lost data has been sent, now receiving. --------------------------------------------

		// Receiving. -----------------------------------------------------------------------------
		parts = receiveParts(ready);
		string recvData = mergeData( parts);

		ubyte[] binaryData = Base64.decode( recvData);
		debug dout.writeLine("All data received: \n" ~ cast(string) binaryData ~ "\n--------------------------------------------------------------");
		debug dout.flush();

		__proxy.send( binaryData);
	}

	template handle( size_t T) 
	{
		auto handle( string toControl )
		{
			static assert(T == SEND || T == STATUS || T == RECV, "Wrong type");

			switch( toControl[ 0 .. MIN_STATUS] ) 
			{
				case DONE[0 .. MIN_STATUS]:		{
					static if ( T == SEND) return true; // All right, continue.
					static if ( T == STATUS) return 0;
					throw new Exception("Dones are not allowed in RECV cycle");
					assert(0);
				}
				case TOKEN[0 .. MIN_STATUS]:	{
					enforce(toControl[TOKEN.length .. $] == token, "Error: another token received."); 
					static if ( T == SEND) return true; // if received different token — break the execution.
					static if ( T == STATUS) return 0;
					static if ( T == RECV) return null;
					assert(0);
				}
				case ERROR[0 .. MIN_STATUS]:	{
					throw new Exception(toControl); // Just throw an exception
					assert(0);
				}

				case NEED[0 .. MIN_STATUS]:		{
					static if ( T == SEND) return true; // Needn't to handle needs before all the packet has been sent.
					static if ( T == STATUS) { need( toControl); return 0; } 
					static if ( T == RECV) throw new Exception("Needs are not allowed in RECV cycle.");
					assert(0);
				}
				case DATA[0 .. MIN_STATUS]:		{
					static if ( T == SEND || T == STATUS)  throw new Exception("Data received before request has been sent. Aborting..."); // Possible attack, must break the execution.
					static if ( T == RECV) return toControl[ DATA.length .. $];
					assert(0);
				}
				case READY[0 .. MIN_STATUS]:	{
					static if ( T == SEND ) throw new Exception("Data is ready before request has been sent. Aborting..."); // Possible attack, must break the execution.
					static if ( T == STATUS ) return parse!size_t(toControl[ READY.length .. $]);
					static if ( T == RECV) throw new Exception("Readys are not allowed during RECV cycle");
					assert(0);
				}
				default:						{
					throw new Exception("Server error: " ~ toControl); // Just throw an exception
					assert(0);
				}
			}
			assert(0);
		}
	}
}