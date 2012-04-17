module jlib.dns.parser;

import std.bitmanip : nativeToBigEndian, bigEndianToNative;
import std.socket : InternetAddress;
import jlib.dns.types;
// f  f+1 f+2 f+3 f+4 f+5
// 2  00  00   1   00  00  00  01  00  01 c0
// 0  1   2    3   4   5   6   7   8   9  10

