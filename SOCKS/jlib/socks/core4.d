module jlib.socks.core4;

import jlib.socks.dummy_tcp_socket;
import std.conv : text;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;
debug import std.cstream;


const size_t	BUFFER_SIZE = 1024*4;	

class Socks4 : DummyTcpSocket
{
	alias Socks4	reference;
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
		assert( super.send(data) > 0, r"Socket send error");
		return 0; // stupid language
	}
	
	ubyte[] receive()
	{
		ubyte[] buffer = new ubyte[ BUFFER_SIZE ];
		assert( super.receive( buffer ) > 0, r"Socket receive error");
		debug dout.writeLine( text( buffer));
		return buffer;
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