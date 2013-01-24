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
  This is a Daria debug module. It implements some common debug techniques, 
  such as logging to the logfile and tty output.
*/

module dbg;

import std.stdio;

/// Default log file name.
immutable string stdlog = "./log.log"; 

/// Default error message starting and finishing.
immutable string start =  "ERROR REPORT: ---------------------------------------";
immutable string end =    "\n-----------------------------------------------------";


static {
  File* logfile = void; /// Logfile
  bool toStd; /// Will dbg output to tty.
  bool toLog; /// Will dbg output to logfile.
  size_t logLevel;

  /// Creates default logfile.
  static this()
  {
    logLevel = 0;
    toStd = toLog = true;
    logfile = new File(stdlog, "wa");
  }

  /// Makes a debug report.
  static void
  report(size_t level)(string[] dbgout...)
  {
    if (level <= logLevel)
    {
      if (toLog) 
      {
        logfile.writeln(start);
        foreach(str; dbgout)
          logfile.write(str);
        logfile.writeln(end);
      }

      if (toStd)
      {
        writeln(start);
        foreach(str; dbgout)
          write(str);
        writeln(end);
      }
    }
  }
}
