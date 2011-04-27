package fstream.utils {

	import flash.utils.ByteArray;
	/**
	 * Sort each char by its code (Unicode) and remove duplicates (if <code>unique == true</code>)
	 * NOTE: FlashPlayer support only BMP (Basic Multilanguage Plane), max value is 0xFFFF
	 * @author Memmie Lenglet
	 * @param value charcodes to sort
	 * @param unique Remove duplicate
	 * @return Sorted char codes by its Unicode code and all duplicate are removed (if <code>unique = true</code>)
	 * @see http://en.wikipedia.org/wiki/Character_encoding Character encoding
	 * @see http://www.cybercomms.org/Tamarin/doxygen/html/d3/dcb/ArrayClass_8cpp-source.html#l00529
	 */
	public function sortChars(value:String, unique:Boolean = true):String
	{
		var length:uint = value.length, i:uint, y:uint;
		if(length <= 1)
		{
			return value;
		}
		
		if(!unique)
		{
			//sort by char code
			return (value.split("").sort() as Array).join("");
		}
		
		//Optimized way (change the switch limit, depend if the original value is not too long prefere standard way, which use less memory)
		if(length >= 4096)
		{
			var charCodeMap:ByteArray = new ByteArray();
			charCodeMap.length = 8192;
			var numChars:uint = 0;
			for(i = 0; i < length; i++)
			{
				var charCode:uint = value.charCodeAt(i);
				var byte:uint = charCodeMap[uint(charCode / 8)];
				if(((byte >> (charCode % 8)) & 1) == 0)
				{
					charCodeMap[uint(charCode / 8)] = byte | (1 << (charCode % 8));
					numChars++;
				}
			}
			
			var charCodes:Array = new Array(numChars),
				j:uint = 0;
			for(i = 0, length = charCodeMap.length; i < length; i++)
			{
				byte = charCodeMap[i];
				for(y = 0; y < 8; y++)
				{
					if(((byte >> y) & 1) == 1)
						charCodes[j++] = i * 8 + y;
				}
			}
			
			return String.fromCharCode.apply(null, charCodes);
		}
		
		//Standard way
		var chars:Array = value.split("").sort();//sort by char code
		var filteredChars:Array = new Array(length);
		
		for(i = 0, y = 0; i < length; i++)
			if(i == 0 || i > 0 && chars[i] != filteredChars[y - 1])
				filteredChars[y++] = chars[i];
		
		//All undefined value are ingnored in join
		return filteredChars.join("");
	}
}