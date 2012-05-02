module routines;

import std.md5 : sum;
import std.exception : enforce;
import std.conv : text;
import core.vararg;

alias string passwd_type;

ubyte[16] mkHash( string login, passwd_type passwd /* NOT SURE COUNT FUCK THIS SHIT */)
{
	ubyte[16] digest;
	sum(digest, login, passwd);
	return digest;
}

string mkDomain( ... )
{
	string domain;
	for( int i = 0 ; i < _arguments.length; i++)
	{
		if( _arguments[i] == typeid(int) )
			domain ~= text(va_arg!int(_argptr)) ~ '.';
		else if (_arguments[i] == typeid(string) )
			domain ~= va_arg!string(_argptr) ~ '.';
		else assert( 0, "Unsupported arguments in mkDomain");
	}
	return domain;
}