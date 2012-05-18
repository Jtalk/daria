module routines;

import std.md5 : sum;
import std.exception : enforce;
import std.conv;
import std.random : uniform;
import core.vararg;
import std.algorithm;

import jlib.dns.dns;
import types;

pure @safe string 
removeBase64Suffix( string base64) 
{
	size_t counter = base64.length;
	while( base64[--counter] == '=') {};
	return base64[ 0 .. counter+1];
}

ubyte[16] 
mkHash( string login, passwd_type passwd /* NOT SURE COUNT FUCK THIS SHIT */)
{
	ubyte[16] digest;
	sum(digest, login, passwd);
	return digest;
}

pure @safe string 
mergeData( string[] data...)
{
	string buffer;
	foreach( part ; data) 
		buffer ~= part;
	return buffer;
}

size_t
getNumber( string domain)
{
	string number = find( domain, '.');
	number = number[ 1 .. $];
	return parse!size_t( number);
}

auto
parseNeeds( string need)
{
	auto strNeeds = splitter( need, ',');
	auto needs = map!"parse!size_t( a)"( strNeeds);
	return needs;
}