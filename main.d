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
import std.md5 : sum;
import std.string;
import core.exception, std.exception;

import jlib.proxy.proxy;
import jlib.dns.dns;

import routines;
import types;
import worker;
static import dbg;

immutable int HANDLE_IMMEDIATELY = 1; // Make Socket.listen() accept connections without queuing

string 
purgePrefix(string text, char symbol) {
  while (text[0] == symbol) {
    text = text[1 .. $];
  }
  return text;  
}

ubyte[16] 
md5hash(string text) {
  ubyte[16] digest;
  sum(digest, text);
  return digest;
}

ThreadGroup
removeFinished(ThreadGroup group) {
  foreach(ref currentThread; group) {
    if (!currentThread.isRunning ) {
      group.remove(currentThread); // GC will handle Thread object for us.
    }
  }
  return group;
}

void main(string[] argv) {
  byte logLevel;
  bool isForking;
  size_t bufferSize;
  string domain, dnsServerAddress, login;
  passwd_type passwd;
  ushort port;
  
  getopt(argv,
       "login|l", &login,
       "password|p", &passwd,
       "server|s", &dnsServerAddress,
       "domain|d", &domain,
       "buffer-size|b", &bufferSize,
       "forking|f", &isForking,
       "error|e", &logLevel,
       "port", &port
    );
  version(Windows)
    isForking = false; // Windows has no fork()
  dbg.logLevel = logLevel;
  debug {
    login = "login";
    passwd = "passwd";
    domain = "d.jtalk.me";
    logLevel = dbg.logLevel = 3;
  }
  assert(!login.empty || !passwd.empty, "Error: no login or password presented");    
  dbg.report!1("Start test:\n", login, ":", passwd, ":", port.text);
  
  domain = purgePrefix(domain, '.'); 
  auto proxy = new Proxy(port);
  proxy.listen(HANDLE_IMMEDIATELY);
  auto userPasswordHash = md5hash(login ~ text(passwd));
  auto userID = cast(string)Base64URL.encode(userPasswordHash);
  // Remove '='s from the end of an ID
  userID = removeBase64Suffix(userID);
  auto threads = new ThreadGroup();
  Proxy accepted;
  // Main cycle
  while(1) {  
    accepted = proxy.accept();
    // We transfer loglevel to worker cuz worker will use it's own logger.
    Thread worker = new Worker(login, userID, dnsServerAddress, accepted, domain, logLevel);
    threads.add(worker);
    removeFinished(threads);
  }
}

