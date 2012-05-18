module main;

import std.stdio;
import std.cstream;
import std.getopt;
import core.thread;
import std.base64;
import std.string;

import jlib.proxy.proxy;
import jlib.dns.dns;

import routines;
import types;
import worker;

//void main() 
//{
//    DnsSocket socket = new DnsSocket();
//    Packet pack = new Packet();
//    pack.id = 10044;
//    pack.flags = 0b1_0000_0000;
//    Packet.Question quest;
//    quest.domain = cast(ubyte[])"aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.aaaaaaaaa.yandex.ru";
//
//    pack.addQuestion( quest);
//    
//    socket.send( pack);
//    pack = socket.receive();
//    
//    //din.getc();
//}

void main(string[] argv)
{
	string[]	textOpt			= new string[ TEXT_OPTIONS_SIZE ];
	passwd_type passwd;				// May use encryption later, just a string for now
	int[]		numOpt			= new int[ NUMERIC_OPTIONS_SIZE ];
	bool[]		switchersOpt	= new bool[ SWITCHER_OPTIONS_SIZE ];

	// D auto-initialization must work? 
	//textOpt[LOGIN] = "";
	//passwd = "";

	getopt( argv,
		   "login|l", &(textOpt[LOGIN]),
		   "password|p", &passwd,
		   "server|s", &textOpt[DNS_SERVER],
		   "domain|d", &textOpt[DOMAIN],
		   "buffer-size|b", &numOpt[BUFFER_SIZE],
		   "forking|f", &switchersOpt[FORKING]
		);

	version( Windows)
		switchersOpt[FORKING] = false;

	//assert( !textOpt[LOGIN].empty || !passwd.empty, "Error: no login or password presented");
	// ATTENTION! NEEDED!
	debug {
		textOpt[LOGIN] = "login";
		passwd = "passwd";
		textOpt[DOMAIN] = "d.jtalk.me";

		dout.writeLine( "Start test:");
		dout.writeLine( textOpt[LOGIN] ~ ':' ~ passwd ~ ':' ~ text(textOpt[LOGIN].empty));
		dout.flush();
		//din.getc();
	}

	// Look whether there're a first dot.
	if ( textOpt[DOMAIN][0] == '.') 
		textOpt[DOMAIN] = textOpt[DOMAIN][ 1 .. $];

	try {
		DnsSocket dns_socket = new DnsSocket( textOpt[DNS_SERVER]);
		//dns_socket.buffer_size = numOpt[BUFFER_SIZE];


		Proxy proxy = new Proxy(Proxy.default_address);
		proxy.listen(1);

		UserID userID = Base64URL.encode(mkHash( textOpt[LOGIN], passwd));

		//userID = std.string.translate(userID, ['+' : '-', '/' : '_'], ['=']);

		// Remove '='s from the end of an ID
		userID = removeBase64Suffix( userID);

		ThreadGroup threads = new ThreadGroup();
		Proxy accepted;
		// Main cycle
		while(1){	
			accepted = proxy.accept();
			
			threads.add(
						new Worker( textOpt[LOGIN], userID, dns_socket, accepted, textOpt[DOMAIN] )
						);

			foreach( ref curThread; threads)
			{
				if ( !curThread.isRunning )
					threads.remove( curThread);
			}
		}
	}
	catch (Exception ex)
	{
		dout.writeLine(ex.msg);
	}
}

