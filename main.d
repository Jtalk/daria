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
  byte logLevel;
  bool isForking;
  size_t bufferSize;
  string domain, dnsServerAddress, login;
  passwd_type passwd;
  
  getopt(argv,
       "login|l", &login,
       "password|p", &passwd,
       "server|s", &dnsServerAddress,
       "domain|d", &domain,
       "buffer-size|b", &bufferSize,
       "forking|f", &isForking,
       "error|e", &logLevel,
    );
  version(Windows)
    isForking = false; // Windows has no fork()
  dbg.logLevel = logLevel;
  assert(!login.empty || !passwd.empty, "Error: no login or password presented");
  debug {
    login = "login";
    passwd = "passwd";
    domain = "d.jtalk.me";
    logLevel = dbg.logLevel = 3;
  }
  dbg.report!1("Start test:\n", login, ":", passwd, ":", text(login.empty));
  // Look whether there're a first dot.
  if (domain[0] == '.') 
    domain = domain[ 1 .. $];
  Proxy proxy = new Proxy(Proxy.default_address);
  proxy.listen(1);
  UserID userID = Base64URL.encode(mkHash(login, passwd));
  // Remove '='s from the end of an ID
  userID = removeBase64Suffix(userID);
  ThreadGroup threads = new ThreadGroup();
  Proxy accepted;
  // Main cycle
  // TODO: Try to remove exception handling - it's useless here, at least in releases.
  try {
    while(1) {  
      accepted = proxy.accept();
      threads.add( // We transfer loglevel to worker cuz worker will use it's own logger.
        new Worker(login, userID, dnsServerAddress, accepted, domain, logLevel)
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

