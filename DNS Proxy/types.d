module types;

enum {
	REGISTRATION = 256,
	SEND,
	STATUS,
	RECV
};

enum {
	LOGIN,
	DNS_SERVER,
	DOMAIN,
};
immutable 

enum {
	BUFFER_SIZE,
	LOGLEVEL
};
immutable 

enum {
	FORKING
};

/// Sizes:
immutable {
	int TEXT_OPTIONS_SIZE = 3;
	int NUMERIC_OPTIONS_SIZE = 2;
	int SWITCHER_OPTIONS_SIZE = 1;
}

/// Some needed values:
immutable {
	size_t HASH_LENGTH = 16;
	//size_t TOKEN_LENGTH = 24; 
	
	size_t PROTO_PARTS_MAXSIZE = 3;
	size_t INDEX_MAXLEN = 5;
}

alias string passwd_type;

alias string UserID;

alias ubyte[HASH_LENGTH] Hash;
//alias ubyte[TOKEN_LENGTH] Token;

/// Server answer types:
immutable { 
	string TOKEN = "token=";
	string ERROR = "error=";
	string NEED = "need=";
	string DATA = "data=";
	string DONE = "done";
	string READY = "ready=";

	size_t MAX_STATUS = 6;
	size_t MIN_STATUS = 4;

	size_t TOKEN_MAXLEN = 8;
	size_t DNS_MAXPART = 62;

	ushort FLAGS = 0b_0000_0001_0000_0000;
}