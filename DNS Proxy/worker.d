module worker;

import core.thread;
import std.cstream;
import std.base64;
import std.random : uniform;

import jlib.dns.dns;
import jlib.proxy.proxy;

private import types;

class Worker : Thread
{
private:

	UserID		__userID = void;
	string		__login = void;
	DnsSocket	__dns_socket = void;
	Proxy		__proxy = void;
	string		__domain = void;

	debug {
		import std.stdio;
		static File dbg = void;
		static this()
		{
			dbg = *new File( r"log.txt", "w");
		}
	}
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
	void run()
	{
		ubyte[] data = __proxy.receive();
		debug dbg.writeln( cast(string) data);
		debug dbg.writeln("------------------------------------------------------------------");

		string encoded = cast(string) Base64URL.encode(data);
		debug dbg.writeln( encoded);
		debug dbg.writeln("------------------------------------------------------------------");

		Packet packet = new Packet();
		packet.id = uniform!(ushort)();
		packet.flags = 0b_0000_0001_0000_0000;
		
		Packet.Question quest;
		quest.domain = ( cast(ubyte[]) __login ~ '.');
		quest.domain ~= ( cast(ubyte[]) __userID ~ '.');
		quest.domain ~=  cast(ubyte[]) __domain;

		quest.type = REGISTRATION;
		quest._class = io_type.IN;

		packet.addQuestion( quest);

		__dns_socket.send(packet);
		packet = __dns_socket.receive();
	}
}