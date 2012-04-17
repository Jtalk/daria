module main;

import std.stdio;
import std.cstream;
import jlib.socks.socks4;
import jlib.dns.dns;

void main(string[] argv)
{
	Socks4 socket = new Socks4( Socks4.default_address);
	socket.listen(1);
	Socks4 acc = socket.accept();

	ubyte[] data = acc.receive();
	dout.writeLine( text(data));
	debug din.getc();
}
