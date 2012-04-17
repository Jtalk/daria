module jlib.dns.types;

enum entry_type // DNS entry type
{
    A = 1,
    CNAME = 5,
    PTR = 12,
    TXT = 16,
	AAAA = 28,
	UNKNOWN = 999
};

enum io_type // Shows whether we need to get or send DNS info. IN must be used, OUT is for future purposes
{
    IN = 1
};

alias ushort Type;
alias ushort Class;
alias uint TTL;



