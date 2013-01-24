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

module main;

import std.stdio;
import std.cstream;
import std.getopt;
import core.thread;
import std.base64;
import std.string;
import core.exception, std.exception;

import jlib.proxy.proxy;
import jlib.dns.dns;

import routines;
import types;
import worker;
static import dbg;

void main(string[] argv)
{
  string[]  textOpt = new string[ TEXT_OPTIONS_SIZE ];
  passwd_type passwd;        // May use encryption later, just a string for now
  int[]  numOpt = new int[ NUMERIC_OPTIONS_SIZE ];
  bool[] switchersOpt = new bool[ SWITCHER_OPTIONS_SIZE ];
  getopt(argv,
       "login|l", &(textOpt[LOGIN]),
       "password|p", &passwd,
       "server|s", &textOpt[DNS_SERVER],
       "domain|d", &textOpt[DOMAIN],
       "buffer-size|b", &numOpt[BUFFER_SIZE],
       "forking|f", &switchersOpt[FORKING],
       "error|e", &numOpt[LOGLEVEL],
    );

  version(Windows)
    switchersOpt[FORKING] = false;
  dbg.logLevel = cast(byte) numOpt[LOGLEVEL]; // There's much less levels than 256... 
  assert(!textOpt[LOGIN].empty || !passwd.empty, "Error: no login or password presented");
  // ATTENTION! NEEDED!
  debug {
    textOpt[LOGIN] = "login";
    passwd = "passwd";
    textOpt[DOMAIN] = "d.jtalk.me";
    numOpt[LOGLEVEL] = dbg.logLevel = 3;
  }
  dbg.report!1("Start test:\n", textOpt[LOGIN], ":", passwd, ":", text(textOpt[LOGIN].empty));
  // Look whether there're a first dot.
  if (textOpt[DOMAIN][0] == '.') 
    textOpt[DOMAIN] = textOpt[DOMAIN][ 1 .. $];
    Proxy proxy = new Proxy(Proxy.default_address);
    proxy.listen(1);
    UserID userID = Base64URL.encode(mkHash(textOpt[LOGIN], passwd));
    // Remove '='s from the end of an ID
    userID = removeBase64Suffix(userID);
    ThreadGroup threads = new ThreadGroup();
    Proxy accepted;
    // Main cycle
  try {
    while(1) {  
      accepted = proxy.accept();
      threads.add(
            new Worker(textOpt[LOGIN], userID, textOpt[DNS_SERVER], accepted, textOpt[DOMAIN], cast(byte)numOpt[LOGLEVEL] )
            );
      foreach(ref curThread; threads)
        if (!curThread.isRunning )
          threads.remove(curThread);
    }
  }
  catch (Throwable ex) {
    writeln(ex.msg, ex.file);
    writeln("STOP");
  }
}

