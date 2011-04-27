package fstream.utils {

	import flash.utils.ByteArray;
	/**
	 * Output byte under a hexadecimal representation, starting with "0x"
	 * @author Memmie Lenglet
	 * @see http://code.google.com/p/as3crypto/source/browse/trunk/as3crypto/src/com/hurlant/util/Hex.as
	 */
	public function toHexa(value:*):String
	{	
		var hexaString:String = "";
		if(value is ByteArray)
		{
			hexaString = "0x";
			var bytes:ByteArray = ByteArray(value);
			for(var i:uint = 0, length:uint = bytes.length; i < length; i++)
				hexaString += HEXA_TABLE[bytes[i]];
		}
		else if(value is uint || value is int)
		{
			hexaString = "0x";
			var integer:uint = uint(value);
			hexaString = HEXA_TABLE[(integer >>> 24) & 0xFF] + HEXA_TABLE[(integer >>> 16) & 0xFF] + HEXA_TABLE[(integer >>> 8) & 0xFF] + HEXA_TABLE[integer & 0xFF];
		}
		
		return hexaString;
	}
}

internal const HEXA_TABLE:Vector.<String> =
(function():Vector.<String>
{
	var table:Vector.<String> = new Vector.<String>(256, true);
	for(var i:uint = 0; i < 256; i++)
		table[i] = ("0" + i.toString(16)).substr(-2, 2);
	return table;
})();