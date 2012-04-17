module jlib.dns.packet;

import jlib.dns.types;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;
debug import std.cstream;
import std.conv : text;
import std.algorithm : splitter;




class Packet
{
	struct Question
	{
		ubyte[] domain;
		Type type;
		Class _class;
		ushort offset[2];
		bool __isProcessed; // shows whether this answer is proceeded (all links has been changed with essential values
	}
	
	struct Answer
	{
		ubyte[] domain;
		ushort offset[2];
		Type type;
		Class _class;
		TTL ttl;
		ushort _length;
		ubyte[] data;
		ushort data_offset[2];
		bool __isProcessed; // shows whether this answer is proceeded (all links has been changed with essential values
	}
	
private:
	Question[]	__questions;
	Answer[] 	__answers;
	bool 		__isRequest;
	
	static immutable packet_offset = 0x2a;
	
	ubyte[] decompress(ubyte[] data)
	{
		ubyte[] searchForJump(ref ushort toJump)
		{
			foreach( ref quest ; __questions)
			{
				debug dout.writeLine("searchForJump0 " ~ text(quest.offset) ~ " " ~ text(toJump)); // !!!!!!!!!!!!!!
				with( quest)
					if ( offset[0] <= toJump && offset[1] > toJump)
						return domain[ toJump - offset[0] .. $ ];
			}
			foreach( ref ans ; __answers)
			{
				with(ans)
				{
					debug dout.writeLine("searchForJump0 " ~ text(ans.offset) ~ " " ~ text(toJump)); // !!!!!!!!!!!!!!
				
					if ( offset[0] <= toJump && offset[1] > toJump)
						return domain[ toJump - offset[0] .. $ ];
					
					debug dout.writeLine("searchForJump0 " ~ text(ans.data_offset) ~ " " ~ text(toJump)); // !!!!!!!!!!!!!!
					if ( data_offset[0] <= toJump && data_offset[1] > toJump)
						return data[ toJump - data_offset[0] .. $ ];
					}
			}		
			assert(0, "Error while decompress");
		}
		
		debug dout.writeLine("decompress0 " ~ cast(string)data); // !!!!!!!!!!!!!!
		size_t first;
		do {
			if ((data[first] & 0b_1100_0000) == 0xc0)
			{
				debug dout.writeLine("decompress1 " ~ cast(string)data); // !!!!!!!!!!!!!!
				ubyte[2] toJumpBin = data[first .. first+2];
				toJumpBin[0] &= 0b_0011_1111;
				ushort toJump = bigEndianToNative!(ushort, 2)(toJumpBin);
				data = data[0 .. first] ~ searchForJump(toJump);
				debug dout.writeLine("decompress2 " ~ cast(string)data); // !!!!!!!!!!!!!!
				break;
			}
			ubyte temp = data[first];
			data[first] = '.';
			first += temp + 1;
		} while ( first < data.length);
		return data;
	}
	
protected:		
	void parseAnswer(ushort number)
	in
	{
		if (!__questions[$-1].__isProcessed)
			parseQuestion(number);
		if (number != 0)
			parseAnswer(cast(ushort)(number-1));
	}
	body
	{
		if ( __answers[number].__isProcessed)
			return;
		
		with (__answers[number]) 
		{
			domain = decompress( domain );
			if ( type == entry_type.A 
				|| type == entry_type.AAAA
				|| type == entry_type.TXT) 
			{
			} // These types does not require decompression
			else
			{
				// Does require decompression
				debug dout.writeLine("parseAnswer NotA " ~ cast(string)domain); // !!!!!!!!!!!!!!
				data = decompress(data);	
				data = data[1 .. $];
				debug dout.writeLine("parseAnswer A " ~ cast(string)data); // !!!!!!!!!!!!!!
			}
			__isProcessed = true;
		}
	}
			
	void parseQuestion(ushort number)
	in
	{
		if ( number && !__questions[number-1].__isProcessed)
			parseQuestion(cast(ushort)(number-1));
	}
	body
	{
		if (__questions[number].__isProcessed)
			return;
		
		with( __questions[number])
		{
			debug dout.writeLine("parseQuestion " ~ cast(string)domain); // !!!!!!!!!!!!!!!
			domain = decompress(domain);
			domain = domain[1 .. $];
			__isProcessed = true;
		}
		
	}
		
public:
	ushort id;
	ushort flags;
	ushort questions_count;
	ushort answers_count;
	ushort authoritative_answers_count;
	ushort additional_answers_count;
	uint total_answers_count;
	
	ubyte return_code;
	
	
	this() {}
	this(ubyte[] packet)
	{
		size_t current_offset = void;
		
		ubyte pair[2];
		pair = packet[0 .. 2];
		id = bigEndianToNative!(ushort, 2)(pair);
		
		pair = packet[2 .. 4];
		flags = bigEndianToNative!(ushort, 2)(pair);
		return_code = cast(ubyte)(flags & 0b_1111);
		
		pair = packet[4 .. 6];
		questions_count = bigEndianToNative!(ushort, 2)(pair);
		
		pair = packet[6..8];
		answers_count = bigEndianToNative!(ushort, 2)(pair);
		
		pair = packet[8 .. 10];
		authoritative_answers_count = bigEndianToNative!(ushort, 2)(pair);
		
		pair = packet[10 .. 12];
		additional_answers_count = bigEndianToNative!(ushort, 2)(pair);
		
		total_answers_count = answers_count + authoritative_answers_count 
			+ additional_answers_count;
		
		packet = packet[12 .. $];
		current_offset = 12;
		
		__questions = new Question[questions_count];
		size_t len = void;
		ushort i;
		for(  ; i < questions_count; i++)
		{
			len = 0;
			with( __questions[i])
			{
				do {
					if ((packet[len] & 0b_1100_0000) == 0xc0)
					{
						len += 2;
						break;
					}
					len += packet[len] + 1;
				} while( packet[len] != 0);
				
				domain = packet[0 .. len].dup;
				packet = packet[len+1 .. $];
				offset[0] = cast(ushort)current_offset;
				offset[1] = cast(ushort)( current_offset += len + 1);
				
				pair = packet[0 .. 2];
				type = bigEndianToNative!(ushort, 2)(pair);
				
				pair = packet[2 .. 4];
				_class = bigEndianToNative!(ushort, 2)(pair);
			}
			packet = packet[4 .. $];
			current_offset += 4;
		}
		
		
		__answers = new Answer[total_answers_count];
		ubyte[4] quad = void;
		packet ~= 0;
		debug dout.writeLine("Packet.this(ubyte[]) total: " ~ text(total_answers_count));
		for( i = 0; i < total_answers_count; i++)
		{
			len = 0;
			with( __answers[i])
			{
				do {
					debug dout.writeLine("Packet.this(ubyte[]) len: " ~ text(packet[len]));
					if ((packet[len] & 0b_1100_0000) == 0xc0)
					{
						len += 2;
						break;
					}
					len += packet[len] + 1;
					//debug dout.writeLine("Packet.this(ubyte[]) packet: " ~ text(packet));
					debug dout.writeLine("Packet.this(ubyte[]) new data: " ~ text([len, packet.length]));
				} while( packet[len] != 0);
				domain = packet[0 .. len].dup;
				debug dout.writeLine("Packet.this(ubyte[]) " ~ text( domain));
				packet = packet[len .. $];
				offset[0] = cast(ushort)current_offset;
				offset[1] = cast(ushort)(current_offset += len);
				
				pair = packet[0 .. 2];
				type = bigEndianToNative!(ushort, 2)(pair);
				debug dout.writeLine("Packet.this(ubyte[]) type: " ~ text(type));
				
				pair = packet[2 .. 4];
				_class = bigEndianToNative!(ushort, 2)(pair);
				debug dout.writeLine("Packet.this(ubyte[]) class: " ~ text(_class));
				
				quad = packet[ 4 .. 8];
				ttl = bigEndianToNative!(TTL, 4)(quad);
				debug dout.writeLine("Packet.this(ubyte[]) ttl: " ~ text(ttl));
				
				pair = packet[8 .. 10];
				_length = bigEndianToNative!(ushort, 2)(pair);
				debug dout.writeLine("Packet.this(ubyte[]) length: " ~ text(_length));
				
				data_offset[0] = cast(ushort)(current_offset += 10);
				data_offset[1] = cast(ushort)(current_offset += _length);
				data = packet[10 .. 10+_length].dup;
				debug dout.writeLine("Packet.this(ubyte[]) data: " ~ text(data));
				
				packet = packet[10+_length .. $];
				//debug dout.writeLine("this() pack: " ~ text(packet));
			}
		}
		
	}
	
	~this() 
	{
		delete __questions;
		delete __answers;
	}
	
	Answer getAnswer(ushort number)
	in
	{
		assert(number < __answers.length, r"Number is out of range in answers");
	}
	body
	{
		parseAnswer(number);
		return __answers[number];
	}
	
	Question getQuestion(ushort number)
	in
	{
		assert(number < __questions.length, r"Number is out of range in questions");
	}
	body
	{
		parseQuestion(number);
		return __questions[number];
	}
		
	
	string getData(ushort number)
	in
	{
		assert(number < __answers.length, r"Number is out of range in answers' data");
	}
	body
	{
		parseAnswer(number);
		return ( __answers[number].type == entry_type.A || 
			__answers[number].type == entry_type.AAAA ? text(__answers[number].data) :
				cast(string) __answers[number].data);
	}
	
	void addQuestion(Question toAdd)
	{
		__questions ~= toAdd;
	}
	
	void addAnswer(Answer toAdd)
	{
		__answers ~= toAdd;
	}
	
	ubyte[] makePacket()
	{
		alias nativeToBigEndian ntb;
		ubyte[] packet = (
			ntb(id) ~
			ntb(flags) ~
			ntb(cast(ushort)__questions.length) ~
			ntb(answers_count) ~
			ntb(authoritative_answers_count) ~
			ntb(additional_answers_count)
			); // header is ready
		debug dout.writeLine("__questions.length: " ~ text(__questions.length));
		ubyte[] domainToRequest(ubyte[] domain)
		{
			auto domains = splitter(domain, cast(ubyte)'.');
			ubyte[] acc;
			foreach( dom; domains)
				acc ~= ( cast(ubyte) dom.length
						~ dom );
			return acc;
		}
		
		ubyte[] makeQuestion(ref Question quest) 
		{			
			ubyte[] question = (
				domainToRequest(quest.domain) ~ 
				0 ~
				nativeToBigEndian(quest.type) ~ 
				nativeToBigEndian(quest._class));
			return question;			
		}
		ubyte[] makeAnswer(ref Answer ans)
		{
			ubyte[] answer = (
				domainToRequest(ans.domain) ~
				nativeToBigEndian(ans.type) ~ 
				nativeToBigEndian(ans._class) ~
				nativeToBigEndian(ans.ttl) ~
				nativeToBigEndian(ans._length) ~
				ans.data); // No compression for a while
			return answer;
		}
		
		foreach( ref quest; __questions)
			packet ~= makeQuestion(quest);
		
		foreach( ref ans ; __answers)
			packet ~= makeAnswer(ans);
		
		return packet;
	}
}