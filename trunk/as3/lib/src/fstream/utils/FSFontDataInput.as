package fstream.utils {

	import flash.errors.IOError;
	import flash.utils.ByteArray;
	/**
	 * @deprecated
	 * @author Memmie Lenglet
	 */
	//TODO use Memory for read operations
	public class FSFontDataInput implements IFontDataInput
	{
		private var _numChars:uint;
		private var _numKernings:uint;
		private var _charPosition:Vector.<uint>;
		private var _bytes:ByteArray;
		private var _kerningCountPosition:uint;
		private var _fontFlags:uint;
		private var _languageCodePosition:uint;
		private var _alignZonePosition:Vector.<uint>;
		
		/**
		 * @param bytes Read only bytes
		 */
		public function FSFontDataInput(bytes:ByteArray)
		{
			_bytes = bytes;
			bytes.position = 0;
			
			var bytesLength:uint = bytes.length;
			if(bytesLength <= 14)
					throw new IOError("Bad size.");
			
			//FontLength
			if(bytes.readUnsignedInt() > bytesLength - 4)
				throw new IOError("No enough bytes.");
			
			var fontNameLength:uint = bytes.readUnsignedByte();
			
			//FontFlags
			bytes.position += fontNameLength;
			_fontFlags = bytes.readUnsignedByte();
			
			_languageCodePosition = bytes.position;
			
			bytes.position += 7;
			_numChars = _bytes.readUnsignedShort();
			
			//CharTableOffset
			_charPosition = new Vector.<uint>(_numChars);
			var fontCharTablePosition:uint = _languageCodePosition + 9 + 6 * _numChars + 4;
			for(var i:uint = 0; i < _numChars; i++)
				_charPosition[i] = fontCharTablePosition + bytes.readUnsignedInt();
			//KerningCountOffset
			_kerningCountPosition = fontCharTablePosition + bytes.readUnsignedInt();
			
			bytes.position = _kerningCountPosition;
			_numKernings = bytes.readUnsignedShort();
			
			_alignZonePosition = new Vector.<uint>(_numChars);
			for(var j:uint = 0; j < _numChars; j++)
			{
				var position:uint = _charPosition[j] + 2;
				bytes.position = position;
				_alignZonePosition[j] = position + Math.ceil(((bytes.readUnsignedByte() >> 3) * 4 + 5) / 8);
			}
		}
		
		public function get fontName():String
		{
			_bytes.position = 4;//skip FontLength (4)
			return _bytes.readUTFBytes(_bytes.readUnsignedByte());
		}
	
		public function get bold():Boolean
		{
			return Boolean(_fontFlags & 0x40);
		}
	
		public function get italic():Boolean
		{
			return Boolean(_fontFlags & 0x80);;
		}
	
		public function get smallText():Boolean
		{
			return Boolean(_fontFlags & 0x20);
		}
	
		public function get csmTableHint():uint
		{
			return _fontFlags >> 3 & 0x3;
		}
	
		public function get languageCode():uint
		{
			_bytes.position = _languageCodePosition;
			return _bytes.readUnsignedByte();
		}
	
		public function get fontAscent():uint
		{
			_bytes.position = _languageCodePosition + 1;//skip LanguageCode (1)
			return _bytes.readUnsignedShort();
		}
	
		public function get fontDescent():uint
		{
			_bytes.position = _languageCodePosition + 3;//skip LanguageCode (1) + FontAscent (2)
			return _bytes.readUnsignedShort();
		}
	
		public function get fontLeading():uint
		{
			_bytes.position = _languageCodePosition + 5;//skip LanguageCode (1) + FontAscent (2) + FontDescent (2)
			return _bytes.readUnsignedShort();
		}
	
		public function get numChars():uint
		{
			return _numChars;
		}
	
		public function get charCodes():Vector.<uint>
		{
			_bytes.position = _languageCodePosition + 9;//skip LanguageCode (1) + FontAscent (2) + FontDescent (2) + FontLeading (2) + CharCount (2)
			var charCodes:Vector.<uint> = new Vector.<uint>(_numChars);
			for(var i:uint = 0; i < _numChars; i++)
				charCodes[i] = _bytes.readUnsignedShort();
			return charCodes;
		}
	
		public function readAdvanceAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			bytes.position = offset;
			_bytes.position = _charPosition[index];
			bytes.writeShort(_bytes.readUnsignedShort());
			return 2;
		}
	
		public function readBoundAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			var position:uint = _charPosition[index] + 2;
			var length:uint = _alignZonePosition[index] - position;
			_bytes.position = position;
			_bytes.readBytes(bytes, offset, length);
			return length;
		}
	
		public function readAlignZoneAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			_bytes.position = _alignZonePosition[index];
			_bytes.readBytes(bytes, offset, 6);
			return 6;
		}
	
		public function readGlyphShapeAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			var position:uint = _alignZonePosition[index] + 6;
			var length:uint = (index == (_numChars - 1) ? _kerningCountPosition : _charPosition[index + 1]) - position;
			_bytes.readBytes(bytes, offset, length);
			return length;
		}
	
		public function get numKernings():uint
		{
			return _numKernings;
		}
	
		public function get kerningsCharCodes():Vector.<uint>
		{
			_bytes.position = _kerningCountPosition + 2;
			var kerningCharCodes:Vector.<uint> = new Vector.<uint>(_numKernings * 2);
			for(var i:uint = 0; i < _numKernings; i += 2)
			{
				kerningCharCodes[i] = _bytes.readUnsignedShort();
				kerningCharCodes[i + 1] = _bytes.readUnsignedShort();
				_bytes.position += 2;//Skip FontKerningAdjustment
			}
			return kerningCharCodes;
		}
	
		public function readKerningRecordAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			_bytes.position = _kerningCountPosition + 2 + 6 * index;
			_bytes.readBytes(bytes, offset, 6);
			return 6;
		}
	
		public function append(...args:Array):IFontDataInput
		{
			if(args.length == 0)
				throw new ArgumentError("No arguments found.");
			
			var length:uint = args.length;
			var fontsData:Vector.<IFontDataInput> = new Vector.<IFontDataInput>(length + 1);
			fontsData[0] = this;
			
			for(var i:uint = 0; i < length; i++)
			{
				if(!(args[i] is IFontDataInput))
					throw new TypeError("Invalid type.");
				fontsData[i + 1] = args[i];
			}
			
			return new FontDataInputUnion(fontsData);
		}
	}
}
