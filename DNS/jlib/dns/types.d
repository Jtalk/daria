/***********************************************************************
	Copyright (C) 2012 Nazarenko Roman

	GNU GENERAL PUBLIC LICENSE - Version 3 - 29 June 2007

	This file is part of DNS Proxy project.

	DNS Proxy is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	DNS Proxy is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with DNS Proxy. If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

/**
* Author: Nazarenko Roman <mailto: me@jtalk.me>
* License: <http://www.gnu.org/licenses/gpl.html>
*/

/**
	This module provides non-class types for DNS routines
*/
module jlib.dns.types;

enum entry_type /// DNS entry type
{
    A = 1,
    CNAME = 5,
    PTR = 12,
    TXT = 16,
	AAAA = 28,
	UNKNOWN = 999
};

enum io_type /// Shows whether we need to get or send DNS info. IN must be used, OUT is for future purposes
{
    IN = 1
};

alias ushort Type;
alias ushort Class;
alias uint TTL;

immutable {
	size_t	DNS_HEADER_SIZE = 12; 
	size_t	DNS_BUFFER_SIZE = 512; /// The size of the receive buffer of the socket	
	size_t	DNS_PACKET_MAXLEN = 250/2; // ?
}



