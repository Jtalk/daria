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

/**
  This is a dummy module to import in the application. It exports all the modules 
  needed to use this library
*/
module jlib.dns.dns;
public import jlib.dns.core;
public static import jlib.dns.types;
public import jlib.dns.packet;