/***********************************************************************
  Copyright (C) 2012-2013 Roman Nazarenko.

  GNU GENERAL PUBLIC LICENSE - Version 3 - 29 June 2007

  This file is part of Daria project.

  Daria is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daria is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daria. If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

/**
* Author: Nazarenko Roman <mailto: me@jtalk.me>, Schevchenko Igor
* License: <http://www.gnu.org/licenses/gpl.html>
*/

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