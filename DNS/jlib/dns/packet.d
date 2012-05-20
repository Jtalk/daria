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
	This is a DNS packet module. It provides programmer-friendly interface
	to work with DNS packets.

	It would be great to understand DNS packets before use this module.
*/
module jlib.dns.packet;

import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.conv : text;
import std.algorithm : splitter;
import std.exception : enforce;

import jlib.dns.types;


/** 
	Standard DNS packet class
*/
class Packet
{
	struct Question
	{
		ubyte[] domain;
		Type type;
		Class _class;
		ushort offset[2]; // Domain offset to use in decompression
		bool __isProcessed; // shows whether this answer is proceeded (all 
		// links has been changed with essential values)
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
		bool __isProcessed; // shows whether this answer is proceeded (all 
		// links has been changed with essential values)
	}

	/// Packet offset represents the offset of the header (deprecated)
	//static immutable packet_offset = 0x2a;
	
private:
	Question[]	__questions;
	Answer[] 	__answers;
	bool 		__isRequest;
	
	/**
		Decompresses domain name presented.

		Params:
			data	= domain name to decompress

		Returns:
			domain name decompressed
	*/
	ubyte[] 
	decompress(ubyte[] data)
	{
		/// Local function to search presented offset in all questions and answers
		ubyte[] 
		searchForJump(ref ushort toJump)
		{
			foreach( ref quest ; __questions)
			{
				with( quest)
					if ( offset[0] <= toJump && offset[1] > toJump)
						return domain[ toJump - offset[0] .. $ ];
				// The dark magic, forget this.
			}

			foreach( ref ans ; __answers)
			{
				with(ans)
				{
					if ( offset[0] <= toJump && offset[1] > toJump)
						return domain[ toJump - offset[0] .. $ ];
					
					if ( data_offset[0] <= toJump && data_offset[1] > toJump)
						return data[ toJump - data_offset[0] .. $ ];
				}
				// The dark magic again.
			}

			enforce(0, "Error while decompress: no offset found");
			return null;
		}
		
		size_t first; // Index of the first 
		ubyte temp = void; // Forget it
		do {
			if ((data[first] & 0b_1100_0000) == 0xc0) // If compression found
			{
				ubyte[2] toJumpBin = data[first .. first+2]; // copy link

				// zeroize first 2 bits. They're only to make us know 
				// about compression.
				toJumpBin[0] &= 0b_0011_1111; 

				// Make jump offset
				ushort toJump = bigEndianToNative!(ushort, 2)(toJumpBin);

				// Add compressed data to the end of the domain
				data = data[0 .. first] ~ searchForJump(toJump); 
				break;
			}

			// Some kind of swapping
			temp = data[first];
			data[first] = '.';
			first += temp + 1; // first now points to the byte next to '.'

		} while ( first < data.length);
		return data;
	}
	
protected:
	/// General parsers
	/**
		Parses answers and decompresses all the stuff inside.
		
		Params: 
			number	= index of answer to parse.
	*/
	void 
	parseAnswer(ushort number)
	in
	{
		// Preparse all the questions
		if (!__questions[$-1].__isProcessed)
			parseQuestion(number);

		// Preparse all previous answers
		if (number)
			parseAnswer(cast(ushort)(number-1));
	}
	body
	{
		// Do nothing if answer is already parsed
		if ( __answers[number].__isProcessed)
			return;
		
		with (__answers[number]) 
		{
			domain = decompress( domain );

			if ( type == entry_type.A 
				|| type == entry_type.AAAA) 
			{
			} // These types does not require decompression
			else if ( type == entry_type.TXT )
				data = data[1 .. $]; // Remove initial trash of the TXT entry
				// Does not require decompression too
			else
			{
				// Does require decompression
				data = decompress(data);	
				data = data[1 .. $];
			}
			__isProcessed = true;
		}
	}
		
	/**
		Parses answers and decompresses all the stuff inside.

		Params: 
		number	= index of answer to parse.
	*/
	void 
	parseQuestion(ushort number)
	in
	{
		// Parse previous questions
		if ( number && !__questions[number-1].__isProcessed)
			parseQuestion(cast(ushort)(number-1));
	}
	body
	{
		// If already processed, do nothing
		if (__questions[number].__isProcessed)
			return;
		
		with( __questions[number])
		{
			// Domains always require decompressio, even for PTR.
			domain = decompress(domain);
			domain = domain[1 .. $];
			__isProcessed = true;
		}
	}
		
public:
	/// Packet header's data
	ushort id;
	ushort flags;
	ushort questions_count;
	ushort answers_count;
	ushort authoritative_answers_count;
	ushort additional_answers_count;

	uint total_answers_count; /// Sum of three answers counts above
	
	ubyte return_code; /// DNS return code
	
	/**
		The default constructor
	*/
	this() {}

	/**
		Constructor. Builds a packet from the binary representation provided.

		The packet must be correct. If not, behaviour is unspecified. Out of range 
		exception may be thrown if byte string is less than must be, or some
		values may become incorrect. An application must control values itself.
	
		Params:
			packet	= byte representation of the DNS packet.
	*/
	this(ubyte[] packet)
	{
		size_t current_offset = void;
		
		ubyte pair[2]; // Ubyte's short value representation
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
			+ additional_answers_count; // Evaluates total count
		
		packet = packet[12 .. $]; // Cutting header off
		current_offset = 12;
		
		__questions = new Question[questions_count];
		size_t len = void; // The length of the next part of the url
		for( ushort i; i < questions_count; i++) // Foreach
		{
			len = 0;
			with( __questions[i])
			{
				do {
					if ((packet[len] & 0b_1100_0000) == 0xc0) // If compressed
					{
						len += 2;
						break; // Stop the value parsing. 
					}
					len += packet[len] + 1; // Next part of the domain entry
				} while( packet[len] != 0);
				
				domain = packet[0 .. len].dup; // Copy the question's domain
				packet = packet[len+1 .. $]; // Cut packet

				// Set offsets
				offset[0] = cast(ushort)current_offset;
				offset[1] = cast(ushort)( current_offset += len + 1);
				
				pair = packet[0 .. 2];
				type = bigEndianToNative!(ushort, 2)(pair);
				
				pair = packet[2 .. 4];
				_class = bigEndianToNative!(ushort, 2)(pair);
			}
			packet = packet[4 .. $]; // Cutting type and class off
			current_offset += 4;
		}
		
		// Process answers
		__answers = new Answer[total_answers_count];
		ubyte[4] quad = void; // ubyte representation of int to get answer length
		packet ~= 0; // Dunno Y it's there
		// Maybe to avoid out of range violation 
		
		for( uint i = 0; i < total_answers_count; i++) // Foreach
		{
			len = 0;
			with( __answers[i])
			{
				do {
					if ((packet[len] & 0b_1100_0000) == 0xc0) // If compression
					{
						len += 2;
						break; // Get the compression pointer and stop the processing
					}
					len += packet[len] + 1; // Next part
				} while( packet[len] != 0);

				domain = packet[0 .. len].dup; 
				packet = packet[len .. $];
				offset[0] = cast(ushort)current_offset;
				offset[1] = cast(ushort)(current_offset += len);
				
				pair = packet[0 .. 2];
				type = bigEndianToNative!(ushort, 2)(pair);
				
				pair = packet[2 .. 4];
				_class = bigEndianToNative!(ushort, 2)(pair);
				
				quad = packet[ 4 .. 8];
				ttl = bigEndianToNative!(TTL, 4)(quad);
				
				pair = packet[8 .. 10];
				_length = bigEndianToNative!(ushort, 2)(pair);
				
				data_offset[0] = cast(ushort)(current_offset += 10);
				data_offset[1] = cast(ushort)(current_offset += _length);
				data = packet[10 .. 10+_length].dup; // Getting answer's data
				// Since there're length field, we need no monkey business 
				// to get the entire field.
				
				packet = packet[10+_length .. $]; // Goto next answer
			}
		}	
	}
	
	/**
		Destructor. Deletes questions and answers to make this class be able 
		to work in non-GC environment.
	*/
	~this() 
	{
		//delete __questions;
		//delete __answers;
	}

	/**
	Copying method. Makes a copy of this class.
	Return:
	A copy of the caller class
	*/
	deprecated Packet copy()
	{
		Packet newp = new Packet();
		newp.id = id;
		newp.flags = flags;
		newp.return_code = return_code;

		return newp;
	}

	/// Received data.
	/**
		Extracts the answer of the number specified.

		Params:
			number	= number of answer to return.

		Returns:
			Answer structure.

		Throws:
			An assert exception if number is out of range.
	*/
	Answer 
	getAnswer(ushort number = 0)
	in
	{
		assert(number < __answers.length, r"Number is out of range in answers");
	}
	body
	{
		parseAnswer(number);
		return __answers[number];
	}
	
	/**
		Extracts the question of the number specified.

		Params:
			number	= number of question to return.

		Returns:
			Question structure.

		Throws:
		An assert exception if number is out of range.
	*/
	Question 
	getQuestion(ushort number = 0)
	in
	{
		assert(number < __questions.length, r"Number is out of range in questions");
	}
	body
	{
		parseQuestion(number);
		return __questions[number];
	}
		
	/**
	Extracts the answer's data of the number specified.

	Params:
		number	= number of answer.

	Returns:
		string representing answer's data.

	Throws:
		An assert exception if number is out of range.
	*/
	string 
	getData(ushort number = 0)
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
	
	/// Making data to send.
	/**
		Adds the question specified to the questions array.
		
		Params:
			toAdd	= Question to add to the array.
	*/
	void 
	addQuestion(Question toAdd)
	{
		__questions ~= toAdd;
	}
	
	/**
		Adds the answer specified to the answers array.

		Params:
			toAdd	= Answer to add to the array.
	*/
	void 
	addAnswer(Answer toAdd)
	{
		__answers ~= toAdd;
	}
	
	/// Packet finalizing.
	/**
		Builds a binary representation of this packet. 

		Note that questions_count is ignored, using length of the questions array
		instead.

		Returns:
			Binary representation of the current packet.
	*/
	ubyte[] 
	makePacket()
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

		/**
			The subroutine to convert domain name to the DNS request. 
		*/
		ubyte[] 
		domainToRequest(ubyte[] domain)
		{
			// Splitting the domain to its parts.
			auto domains = splitter(domain, cast(ubyte)'.');

			ubyte[] acc; // Domain accumulator
			foreach( dom; domains)
				acc ~= ( cast(ubyte) dom.length
						~ dom ); // Adding part's length and the part itself.
			return acc;
		}

		/**
			The subroutine to convert Question structure to the byte string.
		*/
		ubyte[] 
		makeQuestion(ref Question quest) 
		{			
			ubyte[] question = (
				domainToRequest(quest.domain) ~ 
				0 ~
				nativeToBigEndian(quest.type ? quest.type : cast(ushort)entry_type.A) ~ 
				nativeToBigEndian(quest._class ? quest._class : cast(ushort)io_type.IN));
			return question;			
		}

		/**
			The subroutine to convert Answer structure to the byte string.
			
			Bugs: unable to compress domains (and probably will never be).
		*/
		ubyte[] 
		makeAnswer(ref Answer ans)
		{
			ubyte[] answer = (
				domainToRequest(ans.domain) ~
				nativeToBigEndian(ans.type) ~ 
				nativeToBigEndian(ans._class) ~
				nativeToBigEndian(ans.ttl) ~
				nativeToBigEndian(ans._length) ~
				ans.data); 
			return answer;
		}
		
		foreach( ref quest; __questions)
			packet ~= makeQuestion(quest);
		
		foreach( ref ans ; __answers)
			packet ~= makeAnswer(ans);
		
		return packet;
	}
}