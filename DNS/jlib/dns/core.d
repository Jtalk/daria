module jlib.dns.core;

import std.socket : UdpSocket, Address, InternetAddress, getAddress, SocketOSException;
import std.exception;
import std.random : uniform, Random;
import std.array : split;
import std.typetuple;
import jlib.dns.packet;
import std.bitmanip : nativeToBigEndian;
public import jlib.dns.types;
debug import std.cstream;

const size_t	DNS_HEADER_SIZE = 12;
const size_t	BUFFER_SIZE = 1024*4;			



class dns_socket : UdpSocket
{
	
	static
	{
		Address				__dns_server;
		immutable ushort	__dns_port = 53;
		
		ubyte[] createHeader(ushort ID, ushort flags, ushort questions) 
		{
			alias nativeToBigEndian ntb;
			return (
				ntb(ID) ~
				ntb(flags) ~
				ntb(questions) ~
				new ubyte[6] );
		}
		ubyte[] createPacket(ubyte[] header, string domain, entry_type entry, io_type io) 
		{
			return ( 
				header ~ 
				domainToRequest(domain) ~ 
				0 ~
				nativeToBigEndian(cast(ushort) entry) ~ 
				nativeToBigEndian(cast(ushort) io) ~ 
				0 );
		}
		private ubyte[] domainToRequest(string domain)
		{
			string[] domains = split(domain, ".");
			ubyte[] acc;
			foreach( ref dom; domains)
				acc ~= ( cast(ubyte) dom.length
						~ dom );
			return acc;
		}
		
		void init_server()
		{
			string address = "8.8.8.8";
			__dns_server = getAddress(address, this.__dns_port)[0];
		}
	}
	
	
private: 
		
	void init()
	{
		dout.writeLine("Before connect");
		bind();
		connect(__dns_server);
		dout.writeLine("After connect");
	}
	
	
public:
	

public:
	this() 
	{ 
		super();
		init_server();	
		init();
	}
	~this() {}
	
	private alias UdpSocket.bind oldBind;
	void bind(string address = "", ushort port = 0)
	in
	{
		if (port == 0)
			port = InternetAddress.PORT_ANY;
		if (address.length == 0)
			address = "0.0.0.0";
	}
	body
	{
		try
		{
			oldBind( 
				getAddress( address, port)[0] );
		}
		catch ( SocketOSException exc)
		{
			debug dout.writeLine(exc.msg);
			throw exc;
		}
	}
	
	protected alias UdpSocket.send send;
	void send(Packet newp) 
	{ 
		assert( send(cast (void[]) newp.makePacket()) > 0, "Unable to send in dns_socket.send()");
	}
	
	protected alias UdpSocket.receive receive;
	Packet receive()
	{
		ubyte[] buffer = new ubyte[ BUFFER_SIZE ];
		assert( receive(buffer) > 0, "Unable to receive in dns_socket.receive()");
		return new Packet(buffer);
	}
	
	@property
	{
		
		static
		{
			string address() { return __dns_server.toAddrString; }
			string address(string new_addr) { __dns_server = getAddress( new_addr, this.__dns_port)[0]; return new_addr; }
		}
	}
}