module jlib.socks.dummy_tcp_socket;

public import std.socket;

/// $(D TcpSocket) is a shortcut class for a TCP Socket.
class DummyTcpSocket: Socket
{
    /// Constructs a blocking TCP Socket.
    this(AddressFamily family)
    {
        super(family, SocketType.STREAM, ProtocolType.TCP);
    }

    /// Constructs a blocking IPv4 TCP Socket.
    protected this()
    {
		super();
    }


    //shortcut
    /// Constructs a blocking TCP Socket and connects to an $(D Address).
    this(Address connectTo)
    {
        this(connectTo.addressFamily());
        connect(connectTo);
    }
	
	protected override Socket 
	accepting() 
	{
		return new DummyTcpSocket;
	}
	
}