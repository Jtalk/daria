/***********************************************************************
Copyright (C) 2012 Nazarenko Roman

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
* Author: Nazarenko Roman <mailto: me@jtalk.me>
* License: <http://www.gnu.org/licenses/gpl.html>
*/

module jlib.proxy.types;

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