package fstream.utils {

	import flash.errors.IOError;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * Read font data from SWF bytes
	 * Read the first font (DefineFont3) from SWF bytes
	 * @author Memmie Lenglet
	 */
	//TODO use Memory for read operations
	//TODO support mutiple fonts (need some changes in IFontDataInput)
	public class SWFFontDataInput implements IFontDataInput
	{
		private var _bytes:ByteArray;
		private var _numChars:uint;
		private var _numKernings:uint;
		private var _codeTablePosition:uint;
		private var _fontFlags:uint;
		private var _languageCode:uint;
		private var _offsetTablePosition:uint;
		private var _csmTableHintPosition:uint;
		private var _fontBoundsTablePosition:Vector.<uint>;
		private var _fontName:String;
		
		static private const SIGNATURE:uint = 0x465753;//FWS
		static private const SIGNATURE_COMPRESSED:uint = 0x435753;//CWS
		static private const SIGNATURE_COMPRESSED_LZMA:uint = 0x5A5753;//ZWS
		
		static private const BYTE:uint = 1;
		static private const SHORT:uint = 2;
		static private const LONG:uint = 4;
		static private const ALIGN_ZONE:uint = BYTE * 2 + SHORT * 4;
		
		static private const DEFAULT_ASCENT:uint = 0;
		static private const DEFAULT_DESCENT:uint = 0;
		static private const DEFAULT_LEADING:uint = 0;
		static private const DEFAULT_ADVANCE:uint = 0;
		static private const DEFAULT_BOUND:ByteArray = new ByteArray();
		{
			DEFAULT_BOUND.length = BYTE;
			DEFAULT_BOUND.writeByte(0);//rect with 0 bit for each values [0, 0, 0, 0]
		}
		static private const DEFAULT_ALIGN_ZONE:ByteArray = new ByteArray();
		{
			DEFAULT_ALIGN_ZONE.length = BYTE * 2 + SHORT * 4;
			DEFAULT_ALIGN_ZONE.writeByte(2);
			DEFAULT_ALIGN_ZONE.writeUnsignedInt(0x00000000);
			DEFAULT_ALIGN_ZONE.writeUnsignedInt(0x00000000);
			DEFAULT_ALIGN_ZONE.writeByte(0x03);
		}
		private var _hasLayout:Boolean;
		private var _wideOffsets:Boolean;
		private var _wideCodes:Boolean;
		private var _hasAlignZones:Boolean;
		
		/**
		 * 
		 * @param bytes SWF bytes
		 */
		public function SWFFontDataInput(bytes:ByteArray)
		{
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			var header:uint = bytes.readUnsignedByte() << 16 | bytes.readUnsignedByte() << 8 | bytes.readUnsignedByte();
			if (header != SIGNATURE && header != SIGNATURE_COMPRESSED)
				throw new IOError("Invalid header");
			
			bytes.position += BYTE;//version (1)
			var uncompressedLength:uint = bytes.readUnsignedInt();
			
			if(header == SIGNATURE_COMPRESSED)//zlib
			{
				uncompressedLength -= BYTE * 8;//substract header count (signature (3) + version (1) + FileLength (4))
				_bytes = new ByteArray();
				_bytes.endian = Endian.LITTLE_ENDIAN;
				bytes.readBytes(_bytes);//extract content without header (8 bytes already readed)
				bytes = _bytes;
				try
				{
					bytes.uncompress();
				}
				catch (error:Error)
				{
					throw new IOError("Invalid compression");
				}
			}
			else if(header == SIGNATURE_COMPRESSED_LZMA)//lzma
			{
				throw new IOError("LZMA compression not supported yet.");//SWF13 ?
			}
			else
			{
				_bytes = bytes;
			}
			
			//Check length
			if(bytes.length != uncompressedLength)
				throw new IOError("Invalid length");
			//trace(Math.ceil(((bytes.readUnsignedByte() >> 3) * 4 - 3) / 8));
			bytes.position += Math.ceil(((bytes.readUnsignedByte() >> 3) * 4 + 5) / 8) + SHORT * 2;//FrameSize RECT (1+) + framerate (2) + framecount (2)

			var fontID:uint = 0;//Dictionary 0 entry is not allowed
			
			//Default values
			_csmTableHintPosition = 0;
			_hasAlignZones = false;
			
			while(bytes.bytesAvailable >= 2)
			{
				var tagHeader:uint = bytes.readUnsignedShort();
				var tagLength:uint = tagHeader & 0x3F;//short format
				if(tagLength == 0x3F)//extended format
					tagLength = bytes.readUnsignedInt();
				
				//first DefineFont3
				if(tagHeader >> 6 == 75 && fontID == 0)
				{
					//FontID
					fontID = bytes.readUnsignedShort();
					
					//FontFlags
					_fontFlags = bytes.readUnsignedByte();
					_hasLayout = (_fontFlags & 0x80) > 0;
					_wideOffsets = (_fontFlags & 0x08) > 0;
					_wideCodes = (_fontFlags & 0x04) > 0;//must be 1 for SWF6+ (and FontFlagsShiftJIS & FontFlagsANSI to 0)
					
					//LanguageCode
					_languageCode = bytes.readUnsignedByte();
					
					//FontNameLen + FontName
					_fontName = bytes.readUTFBytes(bytes.readUnsignedByte());
					
					//NumGlyphs
					_numChars = bytes.readUnsignedShort();
					
					_offsetTablePosition = bytes.position;
					bytes.position += (_wideOffsets ? LONG : SHORT) * _numChars;
					_codeTablePosition = _offsetTablePosition + (_wideOffsets ? bytes.readUnsignedInt() : bytes.readUnsignedShort());
					
					if(_hasLayout)
					{
						//FontBoundsTable
						bytes.position = _codeTablePosition + SHORT * _numChars * 2 + SHORT * 3;
						_fontBoundsTablePosition = new Vector.<uint>(_numChars + 1);
						_fontBoundsTablePosition[0] = bytes.position;
						for(var i:uint = 0; i < _numChars; i++)
						{
							bytes.position += Math.ceil(((bytes.readUnsignedByte() >> 3) * 4 + 5) / 8);
							_fontBoundsTablePosition[i + 1] = bytes.position;
						}
						
						//KerningCount
						_numKernings = bytes.readUnsignedShort();
						bytes.position += _numKernings * ((_wideCodes ? SHORT : BYTE) * 2 + SHORT);
					}
					else
					{
						_numKernings = 0;
					}
				}
				//associated DefineFontAlignZones
				else if(tagHeader >> 6 == 73 && bytes.readUnsignedShort() == fontID)//FontID
				{
					_hasAlignZones = true;
					_csmTableHintPosition = bytes.position;
					bytes.position += tagLength - SHORT;
				}
				else
				{
					bytes.position += tagLength;
				}
			}
			
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontName():String
		{
			return _fontName;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get bold():Boolean
		{
			return (_fontFlags & 0x01) > 0;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get italic():Boolean
		{
			return (_fontFlags & 0x02) > 0;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get smallText():Boolean
		{
			return (_fontFlags & 0x20) > 0;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get csmTableHint():uint
		{
			_bytes.position = _csmTableHintPosition;
			return _bytes.readUnsignedByte() >>> 6;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get languageCode():uint
		{
			return _languageCode;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontAscent():uint
		{
			if(!_hasLayout)
				return DEFAULT_ASCENT;
			_bytes.position = _codeTablePosition + SHORT * _numChars;//skip CodeTable (2)
			return _bytes.readUnsignedShort();
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontDescent():uint
		{
			if(!_hasLayout)
				return DEFAULT_DESCENT;
			_bytes.position = _codeTablePosition + SHORT * _numChars + SHORT;//skip CodeTable (2) + FontAscent (2)
			return _bytes.readUnsignedShort();
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontLeading():uint
		{
			if(!_hasLayout)
				return DEFAULT_LEADING;
			_bytes.position = _codeTablePosition + SHORT * _numChars + SHORT + SHORT;//skip CodeTable (2) + FontAscent (2) + FontDescent (2)
			return _bytes.readUnsignedShort();
		}
	
		/**
		 * @inheritDoc
		 */
		public function get numChars():uint
		{
			return _numChars;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get charCodes():Vector.<uint>
		{
			if(_numChars == 0)
				return new Vector.<uint>();
			
			_bytes.position = _codeTablePosition;
			var charCodes:Vector.<uint> = new Vector.<uint>(_numChars);
			for(var i:uint = 0; i < _numChars; i++)
				charCodes[i] = _bytes.readUnsignedShort();
			return charCodes;
		}
	
		/**
		 * @inheritDoc
		 */
		public function readGlyphShapeAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			if(index >= _numChars)
				throw new ArgumentError("Invalid index.");
			
			_bytes.position = _offsetTablePosition + (_wideOffsets ? LONG : SHORT) * index;
			var position:uint = _wideOffsets ? _bytes.readUnsignedInt() : _bytes.readUnsignedShort();//relative position
			var length:uint = (_wideOffsets ? _bytes.readUnsignedInt() : _bytes.readUnsignedShort()) - position;
			_bytes.position = _offsetTablePosition + position;//absolute position
			_bytes.readBytes(bytes, offset, length);
			return length;
		}
	
		/**
		 * @inheritDoc
		 */
		public function readAdvanceAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			if(index >= _numChars)
				throw new ArgumentError("Invalid index.");
			
			bytes.position = offset;
			if(_hasLayout)
			{
				_bytes.position = _codeTablePosition + SHORT * _numChars + SHORT * 3 + SHORT * index;
				bytes.writeShort(_bytes.readUnsignedShort());
			}
			else
			{
				bytes.writeShort(DEFAULT_ADVANCE);
			}
			return SHORT;
		}
	
		/**
		 * @inheritDoc
		 */
		public function readAlignZoneAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			if(index >= _numChars)
				throw new ArgumentError("Invalid index.");
			
			var length:uint;
			if(_hasAlignZones)
			{
				length = ALIGN_ZONE;
				_bytes.position = _csmTableHintPosition + BYTE + ALIGN_ZONE * index;//CSMTableHint
				_bytes.readBytes(bytes, offset, length);
			}
			else
			{
				length = DEFAULT_ALIGN_ZONE.length;
				bytes.position = offset;
				bytes.writeBytes(DEFAULT_ALIGN_ZONE);
			}
			return length;
		}
	
		/**
		 * @inheritDoc
		 */
		public function readBoundAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			if(index >= _numChars)
				throw new ArgumentError("Invalid index.");
			
			var length:uint;
			if(_hasLayout)
			{
				var position:uint = _fontBoundsTablePosition[index];
				length = _fontBoundsTablePosition[index + 1] - position;
				_bytes.position = position;
				_bytes.readBytes(bytes, offset, length);
			}
			else
			{
				length = DEFAULT_BOUND.length;
				DEFAULT_BOUND.position = 0;
				DEFAULT_BOUND.readBytes(bytes, offset, length);
			}
			return length;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get numKernings():uint
		{
			return _numKernings;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get kerningsCharCodes():Vector.<uint>
		{
			if(_numKernings == 0)
				return new Vector.<uint>();
			
			_bytes.position = _fontBoundsTablePosition[_fontBoundsTablePosition.length - 1] + SHORT;
			var kerningCharCodes:Vector.<uint> = new Vector.<uint>(_numKernings * 2);
			var i:uint;
			if(_wideCodes)
			{
				for(i = 0; i < _numKernings; i++)
				{
					kerningCharCodes[i * 2] = _bytes.readUnsignedByte();
					kerningCharCodes[i * 2 + 1] = _bytes.readUnsignedByte();
					_bytes.position += SHORT;//Skip FontKerningAdjustment
				}
			}
			else
			{
				for(i = 0; i < _numKernings; i++)
				{
					kerningCharCodes[i * 2] = _bytes.readUnsignedShort();
					kerningCharCodes[i * 2 + 1] = _bytes.readUnsignedShort();
					_bytes.position += SHORT;//Skip FontKerningAdjustment
				}
			}
			return kerningCharCodes;
		}
	
		/**
		 * @inheritDoc
		 */
		public function readKerningRecordAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			if(index >= _numKernings)
				throw new ArgumentError("Invalid index.");
			var length:uint = (_wideCodes ? SHORT : BYTE) * 2 + SHORT;
			_bytes.position = _fontBoundsTablePosition[_fontBoundsTablePosition.length - 1] + SHORT + length * index;
			_bytes.readBytes(bytes, offset, length);
			return length;
		}
	
		/**
		 * @inheritDoc
		 */
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
