module types;

enum {
	REGISTRATION = 256,
	DATA,
	STATUS 
};

enum {
	LOGIN,
	DNS_SERVER,
	DOMAIN,
};
immutable int TEXT_OPTIONS_SIZE = 3;

enum {
	BUFFER_SIZE
};
immutable int NUMERIC_OPTIONS_SIZE = 1;

enum {
	FORKING
};
immutable int SWITCHER_OPTIONS_SIZE = 1;

immutable size_t HASH_LENGTH = 16;
immutable size_t TOKEN_LENGTH = 24; 

alias string UserID;

alias ubyte[HASH_LENGTH] Hash;
alias ubyte[TOKEN_LENGTH] Token;