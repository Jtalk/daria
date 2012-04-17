module jlib.socks.types;

enum socks_version
{
	SOCKS4 = 4,
	SOCKS5
}

enum socks_command
{
	CONNECT = 1,
	BIND,
	
	GRANTED = 90,
	FAILED,
	NO_IDENTD,
	WRONG_UID
}