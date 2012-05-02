module jlib.proxy.core;

import jlib.proxy.dummy_tcp_socket;
import std.conv : text;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.exception : enforce;
debug import std.cstream;


private const size_t	PROXY_BUFFER_SIZE = 1024*4;	

class Proxy : DummyTcpSocket
{
	alias Proxy	reference;
private:		
	static
	{
		public const Address default_address;
		
		static this()
		{
			default_address = getAddress( "127.0.0.1", 808)[0];
		}
	}
	
public:	
	this()
	{
		super();
	}
	this(const Address toListen)
	{
		super( Socket.addressFamily.INET);
		bind( cast(Address)toListen );
	}
	~this() {}
	
	protected override Socket accepting()
	{
		return new reference;
	}
	
	override ptrdiff_t send(const(void)[] data)
	{
		enforce( super.send(data) > 0, r"Socket send error");
		return 0; // stupid language
	}
	
	ubyte[] receive()
	{
		ubyte[] buffer = new ubyte[ PROXY_BUFFER_SIZE ];
		size_t received = super.receive( buffer);
		enforce( received > 0, r"Socket receive error");
		return buffer[ 0 .. received];
	}
	
	override void connect(Address)
	{
		assert(0, r"Connection from SOCKS server isn't allowed");
	}
	
	private alias DummyTcpSocket.accept oldAccept;
	override reference accept()
	{
		return cast(reference) super.accept();
	}
}