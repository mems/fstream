package fstream.utils
{
	import flash.utils.ByteArray;
	
	/**
	* Dump binary data. Trace bytes with hex adresses
	* NOTE: Endianness dont have any impact
	* @author Memmie Lenglet
	*/
	public function dump(bytes:ByteArray):void
	{
		var output:String = "Address   +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +a +b +c +d +e +f  Dump";
		var dump:String = "";
		var byte:uint;
		const ADDRESS:String = "00000000";
		for(var i:uint = 0, length:uint = bytes.length; i < length; i++)
		{
			if (i % 16 == 0)// dump offset
				output += "\n" + ("00000000" + i.toString(16)).substr( -8, 8) + "  ";
			
			/*if (i % 8 == 0)
				output += " ";*/
			
			byte = bytes[i];
			output += ("0" + byte.toString(16)).substr(-2, 2) + " ";
			//put char or "." if non printable char
			dump += (byte < 32 || byte > 126) ? "." : String.fromCharCode(byte);
			if ((i + 1) % 16 == 0)
			{
				output += " " + dump;
				dump = "";
			}
			if (((i + 1) % 16 != 0) && (i == length - 1))
				output += "                                             ".substr(0, 3 * (16 - (i + 1) % 16)) + " " + dump;
		}
		
		trace(output);
	}
}