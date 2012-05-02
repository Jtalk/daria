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

alias string UserID;