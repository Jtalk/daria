module main;

import std.stdio;
import std.cstream;
import std.getopt;
import core.thread;
import std.base64;

import jlib.proxy.proxy;
import jlib.dns.dns;

import routines;
import types;
import worker;

void main(string[] argv)
{
	string[]	textOpt			= new string[ TEXT_OPTIONS_SIZE ];
	passwd_type passwd;				// May use encryption later
	int[]		numOpt			= new int[ NUMERIC_OPTIONS_SIZE ];
	bool[]		switchersOpt	= new bool[ SWITCHER_OPTIONS_SIZE ];

	textOpt[LOGIN] = "";
	passwd = "";

	getopt( argv,
		   "login|l", &(textOpt[LOGIN]),
		   "password|p", &passwd,
		   "server|s", &textOpt[DNS_SERVER],
		   "domain|d", &textOpt[DOMAIN],
		   "buffer-size|b", &numOpt[BUFFER_SIZE],
		   "forking|f", &switchersOpt[FORKING]
		);

	version( POSIX)
		switchersOpt[FORKING] = true;
	else
		switchersOpt[FORKING] = false;

	debug {
		dout.writeLine( "Start test:");
		dout.writeLine( textOpt[LOGIN] ~ ':' ~ passwd ~ ':' ~ text(textOpt[LOGIN].empty));
		//din.getc();
	}

	//assert( !textOpt[LOGIN].empty || !passwd.empty, "Error: no login or password presented");
	// ATTENTION! NEEDED!
	debug textOpt[LOGIN] = "login";
	debug passwd = "passwd";
	debug textOpt[DOMAIN] = "c.mainnika.ru.";
	
	try {
		DnsSocket dns_socket = new DnsSocket( textOpt[DNS_SERVER]);
		dns_socket.buffer_size = numOpt[BUFFER_SIZE];

		Proxy proxy = new Proxy(Proxy.default_address);
		proxy.listen(1);

		UserID userID = Base64URL.encode(mkHash( textOpt[LOGIN], passwd));

		ThreadGroup threads = new ThreadGroup();
		Worker threadToAdd;
		Proxy accepted;
		while(1)
		{	
			accepted = proxy.accept();
			threadToAdd = new Worker( textOpt[LOGIN], userID, dns_socket, accepted, textOpt[DOMAIN] );
			threads.add( threadToAdd);

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

