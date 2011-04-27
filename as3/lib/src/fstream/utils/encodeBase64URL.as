package fstream.utils {

	import flash.utils.ByteArray;
	/**
	 * Base 64 url encoding
	 * Modified version of Jean-Philippe Auclair (no padding and replace all "+" by "-" and "/" by "_")
	 * Precalulate data (for base 64 with padding): <code>(2 + data.length - ((data.length + 2) % 3)) * 4 / 3</code>
	 * or (for base 64 url, without padding): <code>Math.ceil(data.length * 4 / 3)</code>
	 * @see http://jpauclair.net/2010/01/09/base64-optimized-as3-lib/ Base64 Optimized as3 lib - jpauclair
	 * @see http://en.wikipedia.org/wiki/Base64#URL_applications Base64 / URL Applications - Wikipedia
	 */
	public function encodeBase64URL(data:ByteArray):String
	{
		var out:ByteArray = new ByteArray();
		//Presetting the length keep the memory smaller and optimize speed since there is no "grow" needed
		out.length = Math.ceil(data.length * 4 / 3); //Preset length //1.6 to 1.5 ms
		var i:int = 0;
		var r:int = data.length % 3;
		var length:int = data.length - r;
		var c:int;//read (3) character AND write (4) characters

		while(i < length)
		{
			//Read 3 Characters (8bit * 3 = 24 bits)
			c = data[i++] << 16 | data[i++] << 8 | data[i++];	

			//Cannot optimize this to read int because of the positioning overhead. (as3 bytearray seek is slow)
			//Convert to 4 Characters (6 bit * 4 = 24 bits)
			c = (CHAR_MAP[c >>> 18] << 24) | (CHAR_MAP[c >>> 12 & 0x3f] << 16) | (CHAR_MAP[c >>> 6 & 0x3f] << 8 ) | CHAR_MAP[c & 0x3f];

			//Optimization: On older and slower computer, do one write Int instead of 4 write byte: 1.5 to 0.71 ms
			out.writeInt(c);
		}	

		if(r == 1) //Need two "=" padding (but due to url encoding, don't add padding char)
		{
			//Read one char, write two chars, write padding
			c = data[i];
			c = (CHAR_MAP[c >>> 2] << 8) | CHAR_MAP[(c & 0x03) << 4];
			out.writeShort(c);
		}
		else if(r == 2) //Need one "=" padding (but due to url encoding, don't add padding chars)
		{
			c = data[i++] << 8 | data[i];
			c = (CHAR_MAP[c >>> 10] << 16) | (CHAR_MAP[c >>> 4 & 0x3f] << 8) | CHAR_MAP[(c & 0x0f) << 2];
			out.writeShort(c >> 8);
			out.writeByte(c);
		}	

	 	out.position = 0;
		return out.readUTFBytes(out.length);
	}
}

//eq. of "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
internal const CHAR_MAP:Array = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104,
105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 45, 95];
