package fstream.net {

	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.ByteArray;
	
	/**
	 * Font request give font name, style and chars to load.
	 * @author Memmie Lenglet
	 */
	public class FontRequest
	{
		private var _fontName:String;
		private var _fontStyle:String;
		private var _chars:ByteArray;
		private var _numChars:uint;
		private var _urlSyntax:String;
		private static var _defaultURLSyntax:String = "<fontname>;<fontstyle>?range=<range>";

		public function FontRequest(fontName:String = "", fontStyle:String = "regular", chars:String = "")
		{
			_fontName = fontName;
			_fontStyle = fontStyle;
			_chars = new ByteArray();
			_chars.length = 8192;
			_numChars = 0;
			this.chars = chars;
			_urlSyntax = _defaultURLSyntax;
		}
		
		/**
		 * When it's called, the getter return only needed chars. Depends of current registered fonts in FlashPlayer Character Dictionary (in memory)
		 */
		public function get neededChars():String
		{
			var neededChars:String = "";
			
			//Search font matching with same fontName and same fontStyle
			for each(var font:Font in Font.enumerateFonts(false))
			{
				if(font.fontName == fontName && font.fontStyle == fontStyle)
					break;
				else
					font = null;
			}
			
			if(font != null)
			{
				var requestedChars:String = chars;
				for(var i:uint = 0, length:uint = requestedChars.length; i < length; i++)
				{
					var char:String = requestedChars.charAt(i);
					if(!font.hasGlyphs(char))
						neededChars += char;
				}
			}
			else
			{
				neededChars = chars;
			}
			
			return neededChars;
		}
		
		/**
		 * URL syntax value used as default for each FontRequest instance property <code>urlSyntax</code>
		 * @default "&lt;fontname&gt;;&lt;fontstyle&gt;?range=&lt;range&gt;"
		 * @see urlSyntax
		 */
		static public function get defaultURLSyntax():String
		{
			return _defaultURLSyntax;
		}
		
		static public function set defaultURLSyntax(value:String):void
		{
			_defaultURLSyntax = value;
		}
		
		/**
		 * URL syntax of font service
		 */
		public function get urlSyntax():String
		{
			return _urlSyntax;
		}
		
		public function set urlSyntax(value:String):void
		{
			_urlSyntax = value;
		}
		
		/**
		 * Sorted chars
		 */
		public function get chars():String
		{
			var charCodes:Array = new Array(_numChars),
				j:uint = 0;
			for(var i:uint = 0, length:uint = _chars.length; i < length; i++)
			{
				var byte:uint = _chars[i];
				for(var y:uint = 0; y < 8; y++)
				{
					if(((byte >> y) & 1) == 1)
						charCodes[j++] = i * 8 + y;
				}
			}
			
			return String.fromCharCode.apply(null, charCodes);
		}

		public function set chars(value:String):void
		{
			for(var j:uint = 0; j < 8192; j++)
				_chars[j] = 0;
			
			for(var i:uint = 0, length:uint = value.length; i < length; i++)
			{
				var charCode:uint = value.charCodeAt(i);
				var byte:uint = _chars[uint(charCode / 8)];
				if(((byte >> (charCode % 8)) & 1) == 0)
				{
					_chars[uint(charCode / 8)] = byte | (1 << (charCode % 8));
					_numChars++;
				}
			}
		}

		/**
		 * Font style
		 * @see flash.text.FontStyle
		 */
		public function get fontStyle():String {
			return _fontStyle;
		}

		public function set fontStyle(value:String):void
		{
			_fontStyle = value;
		}

		/**
		 * Font name
		 */
		public function get fontName():String {
			return _fontName;
		}

		public function set fontName(value:String):void
		{
			_fontName = value;
		}
		
		/**
		 * Make a exact copie of this object
		 */
		public function clone():FontRequest
		{
			var clone:FontRequest = new FontRequest(_fontName, _fontStyle, chars);
			clone.urlSyntax = urlSyntax;
			return clone;
		}
		
		/**
		 * URLRequests needed for font to load.
		 */
		public function get urlRequests():Vector.<URLRequest>
		{
			var requestedChars:String = neededChars;
			if(requestedChars.length == 0)
				return new Vector.<URLRequest>();
			
			var start:uint = requestedChars.charCodeAt(0);
			var ranges:Array = [];
			var length:uint = requestedChars.length;
			for (var i:uint = 0; i < length; i++)
			{
				var nextIsNewRange:Boolean = i + 1 < length && requestedChars.charCodeAt(i + 1) > requestedChars.charCodeAt(i) + 1;
				if (nextIsNewRange || (i + 1 == length))
				{
					var end:uint = requestedChars.charCodeAt(i);
					
					if(start == end)
						ranges.push("U+" + ("000" + start.toString(16)).substr(-4, 4).toUpperCase());
					else
						ranges.push("U+" + ("000" + start.toString(16)).substr(-4, 4).toUpperCase() + "-U+" + ("000" + end.toString(16)).substr(-4, 4).toUpperCase());
					
					if(nextIsNewRange)
						start = requestedChars.charCodeAt(i + 1);
				}
			}
			
			var url:String = _urlSyntax.replace("<fontname>", fontName)
				.replace("<fontstyle>", fontStyle)
				.replace("<range>", ranges.join(","));
			return new <URLRequest>[new URLRequest(url)];
		}
	}
}
