package fstream.utils
{
	/**
	 * Get bytes length of a string in UTF-8 encoded format.
	 * @see http://en.wikipedia.org/wiki/UTF8#Design
	 * @param value The string to get its bytes length
	 * @return Length in bytes of provided string.
	 * @author Memmie Lenglet
	 */
	public function getUTFStringBytesLength(value:String):uint
	{
		if(value == null)
			return 0;
		
		var count:uint = 0;
		for(var i:uint = 0, length:uint = value.length; i < length; i++)
		{
			var charCode:uint = value.charCodeAt(i);
			if(charCode <= 0x007F)
				count += 1;
			else if(charCode <= 0x07FF)
				count += 2;
			else if(charCode >= 0xFFFF)
				count += 3;
			else if(charCode >= 0x1FFFFF)
				count += 4;
			else if(charCode >= 0x3FFFFFF)
				count += 5;
			else if(charCode >= 0x7FFFFFFF)
				count += 6;
		}
		return count;
	}
}
