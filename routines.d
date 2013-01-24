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
removeBase64Suffix(string base64) 
{
  size_t counter = base64.length;
  while(base64[--counter] == '=') {}
  return base64[ 0 .. counter+1];
}

ubyte[16] 
mkHash(string login, passwd_type passwd /* NOT SURE COUNT FUCK THIS SHIT */)
{
  ubyte[16] digest;
  sum(digest, login, passwd);
  return digest;
}

pure @safe string 
mergeData(string[] data...)
{
  string buffer;
  foreach(part ; data) 
    buffer ~= part;
  return buffer;
}

size_t
getNumber(string domain)
{
  string number = find(domain, '.');
  number = number[ 1 .. $];
  return parse!size_t(number);
}

auto
parseNeeds(string need)
{
  auto strNeeds = splitter(need, ',');
  auto needs = map!"parse!size_t(a)"(strNeeds);
  return needs;
}

string[] 
cut(string str, size_t num, size_t chunk_len) 
{
  string[] buffer;
  for (size_t i; i < num-1; ++i)
    buffer ~= str[i * chunk_len .. (i+1) * chunk_len];
  buffer ~= str[(num-1) * chunk_len .. $]; // Optimization
  return buffer;
}

ubyte[] 
makeDomain(string[] parts...) 
{
  string buffer;
  foreach(part; parts)
    buffer ~= (part ~ '.');
  return cast(ubyte[]) buffer[ 0 .. $-1];
}