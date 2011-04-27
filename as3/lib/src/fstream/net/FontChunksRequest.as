package fstream.net {

	import flash.net.URLRequest;
	/**
	 * @author Memmie Lenglet
	 */
	public class FontChunksRequest extends FontRequest
	{
		private static var _defaultChunkLength:uint = 100;
		
		private var _chunkLength:uint;
		
		public function FontChunksRequest(fontName:String = "", fontStyle:String = "regular", chars:String = "")
		{
			super(fontName, fontStyle, chars);
			_chunkLength = _defaultChunkLength;
		}
		
		/**
		 * Alias to FontRequest.defaultURLSyntax
		 * @see FontRequest.defaultURLSyntax
		 */
		static public function get defaultURLSyntax():String
		{
			return FontRequest.defaultURLSyntax;
		}
		
		static public function set defaultURLSyntax(value:String):void
		{
			FontRequest.defaultURLSyntax = value;
		}
		
		/**
		 * Chunck size value used as default for each FontRequest instance property <code>chunkLength</code>
		 * @default 100
		 * @see chunkLength
		 */
		static public function get defaultChunkLength():uint
		{
			return _defaultChunkLength;
		}
		
		static public function set defaultChunkLength(value:uint):void
		{
			_defaultChunkLength = value;
		}
		
		/**
		 * Chunk size of each part 
		 */
		public function get chunkLength():uint
		{
			return _chunkLength;
		}
		
		public function set chunkLength(value:uint):void
		{
			_chunkLength = value;
		}
		
		override public function clone():FontRequest
		{
			var clone:FontChunksRequest=  new FontChunksRequest(fontName, fontStyle, chars);
			clone.urlSyntax = urlSyntax;
			clone.chunkLength = _chunkLength;
			return clone;
		}
		
		override public function get urlRequests():Vector.<URLRequest>
		{
			var urlRequests:Vector.<URLRequest> = new Vector.<URLRequest>();
			var ranges:Vector.<uint> = new Vector.<uint>();//will contains first char code of each ranges
			var charCodes:String = neededChars;
			for(var i:uint = 0, length:uint = charCodes.length; i < length; i++)
			{
				var rangeFirstCharCode:uint = uint(charCodes.charCodeAt(i) / _chunkLength) * _chunkLength;//first char code of range
				if(ranges.length == 0 || ranges.length > 0 && ranges[ranges.length - 1] < rangeFirstCharCode)
					ranges.push(rangeFirstCharCode);
			}
			
			var baseURL:String = urlSyntax.replace("<fontname>", fontName).replace("<fontstyle>", fontStyle);
			for each(rangeFirstCharCode in ranges)
			{
				var firstCharCode:String = ("000" + rangeFirstCharCode.toString(16)).substr(-4, 4).toUpperCase();
				var lastCharCode:String = ("000" + (Math.min(rangeFirstCharCode + _chunkLength - 1, 0xFFFF)).toString(16)).substr(-4, 4).toUpperCase();
				var url:String = baseURL.replace("<range>", "U+" + firstCharCode + "-U+" + lastCharCode);
				urlRequests.push(new URLRequest(url));
			}
			
			return urlRequests;
		}
	}
}
