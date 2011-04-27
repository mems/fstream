package fstream.utils {

	import flash.utils.getQualifiedClassName;
	import flash.utils.ByteArray;
	/**
	 * Merge a collection of IFontDataInput to make an unique IFontDataInput object, by suppress duplicates plus sort all charcodes and kernings.
	 * Data depends the order of elements in collection. Font name, style, metrics, etc. come from first element completed by other (second, third, etc.)
	 * @author Memmie Lenglet
	 */
	//TODO (?) use ByteArray instead Vector.<uint>
	//TODO make same optimization for kernings like charcodes (or similar, by reference with a Dictionary)
	public class FontDataInputUnion implements IFontDataInput
	{
		private var _fonts:Vector.<IFontDataInput>;
		private var _charCodes:Vector.<uint>;
		private var _kerningsCharCodes:Vector.<uint>;
		
		private var _kerningsFontMap:Vector.<IFontDataInput>;
		private var _kerningsLocalIndexMap:Vector.<uint>;
		private var _charsFontMap:Vector.<IFontDataInput>;
		private var _charsLocalIndexMap:Vector.<uint>;
		
		/**
		 * @throws ArgumentError If fontsData is null or if its length is less that one.
		 */
		public function FontDataInputUnion(fontsData:Vector.<IFontDataInput>)
		{
			if(fontsData == null || fontsData.length < 1)
				throw new ArgumentError("Invalid argument fontsData.");
			_fonts = fontsData.concat();
			
			computeChars();
			computeKernings();
		}

		private function computeChars():void
		{
			//Get all charcodes of all fontsData
			//Get startCharOffset of each fontsData startCharOffset(n) = startCharOffset(n - 1) + numChars(n)
			var numFonts:uint = _fonts.length,
				charCodes:Array = [],//use Array instead Vector.<uint> for its sort "return indexed array" method
				charsLocalIndexMap:Vector.<uint> = new Vector.<uint>(),
				charsFontMap:Vector.<IFontDataInput> = new Vector.<IFontDataInput>(),
				totalNumChars:uint = 0;
			
			var charCodeCount:ByteArray = new ByteArray();
			charCodeCount.length = 8192;
			
			//Loop on all fonts
			for(var fontIndex:uint = 0, index:uint = 0; fontIndex < numFonts; ++fontIndex)
			{
				var font:IFontDataInput = _fonts[fontIndex];
				
				if(font == null || font.numChars == 0)
					continue;
				
				var fontCharCodes:Vector.<uint> = font.charCodes;
				var numChars:uint = fontCharCodes.length;
				charsFontMap.length =
				charsLocalIndexMap.length =
				(charCodes.length += numChars);
				
				//Loop on all chars
				for(var localIndex:uint = 0; localIndex < numChars; ++localIndex)//append and filter for uniques values
				{
					var charCode:uint = fontCharCodes[localIndex];
					if(((charCodeCount[uint(charCode / 8)] >> (charCode % 8)) & 1) == 0)
					{
						charCodeCount[uint(charCode / 8)] |= (1 << (charCode % 8));
						charCodes[index] = charCode;
						charsLocalIndexMap[index] = localIndex;
						charsFontMap[index] = font;
						index++;
					}
				}
				totalNumChars = index;
			}
			charCodes.length = totalNumChars;
			
			var offsets:Array = charCodes.sort(Array.NUMERIC | Array.RETURNINDEXEDARRAY), offset:uint;
			_charCodes = new Vector.<uint>(totalNumChars);
			_charsLocalIndexMap = new Vector.<uint>(totalNumChars);
			_charsFontMap = new Vector.<IFontDataInput>(totalNumChars);
			for(index = 0; index < totalNumChars; index++)
			{
				offset = offsets[index];
				_charCodes[index] = charCodes[offset];
				_charsLocalIndexMap[index] = charsLocalIndexMap[offset];
				_charsFontMap[index] = charsFontMap[offset];
			}
		}
		
		private function computeKernings():void
		{
			//Get all kernings codes of all fontsData
			//Get startKerningOffset of each fontData startKerningOffset(n) = startKerningOffset(n - 1) + numKernings(n)
			//Simplify all computing, by concat left with right codes (SHORT << 16 | SHORT = LONG)
			var numFonts:uint = _fonts.length,
				kerningsCharCodes:Array = [],
				kerningsLocalIndexMap:Vector.<uint> = new Vector.<uint>(),
				kerningsFontMap:Vector.<IFontDataInput> = new Vector.<IFontDataInput>(),
				totalNumKernings:uint = 0;
			
			//Loop on all fonts
			for(var fontIndex:uint = 0, index:uint = 0; fontIndex < numFonts; fontIndex++)
			{
				var font:IFontDataInput = _fonts[fontIndex];
				
				if(font == null || font.numKernings == 0)
					continue;
				
				var fontKerningsCharCodes:Vector.<uint> = font.kerningsCharCodes;
				var numKernings:uint = fontKerningsCharCodes.length / 2;
				kerningsLocalIndexMap.length =
				kerningsFontMap.length =
				(kerningsCharCodes.length += numKernings);
				
				//Loop on all chars
				for(var localIndex:uint = 0; localIndex < numKernings; localIndex++)//append and filter for uniques values
				{
					var kerning:uint = fontKerningsCharCodes[localIndex * 2] << 16 | fontKerningsCharCodes[localIndex * 2 + 1];
					if(charCodes.lastIndexOf(kerning, index) < 0)
//					if(charCodes.indexOf(kerning) < 0)
					{
						kerningsCharCodes[index] = kerning;
						kerningsLocalIndexMap[index] = localIndex;
						kerningsFontMap[index] = font;
						index++;
					}
				}
				totalNumKernings = index;
			}
			
			var offsets:Array = kerningsCharCodes.sort(Array.NUMERIC | Array.RETURNINDEXEDARRAY), offset:uint;
			_kerningsCharCodes = new Vector.<uint>(totalNumKernings * 2);
			_kerningsLocalIndexMap = new Vector.<uint>(totalNumKernings);
			_kerningsFontMap = new Vector.<IFontDataInput>(totalNumKernings);
			for(index = 0; index < totalNumKernings; index++)
			{
				offset = offsets[index];
				kerning = kerningsCharCodes[offset];
				_kerningsCharCodes[index * 2] = kerning >> 16;
				_kerningsCharCodes[index * 2 + 1] = kerning & 0xFFFF;
				_kerningsLocalIndexMap[index] = kerningsLocalIndexMap[offset];
				_kerningsFontMap[index] = kerningsFontMap[offset];
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get fontName():String
		{
			return _fonts[0].fontName;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get bold():Boolean
		{
			return _fonts[0].bold;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get italic():Boolean
		{
			return _fonts[0].italic;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get smallText():Boolean
		{
			return _fonts[0].smallText;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get csmTableHint():uint
		{
			return _fonts[0].csmTableHint;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get languageCode():uint
		{
			return _fonts[0].languageCode;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontAscent():uint
		{
			return _fonts[0].fontAscent;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontDescent():uint
		{
			return _fonts[0].fontDescent;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get fontLeading():uint
		{
			return _fonts[0].fontLeading;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get charCodes():Vector.<uint>
		{
			return _charCodes.concat();
		}
	
		/**
		 * @inheritDoc
		 */
		public function get numChars():uint
		{
			return _charCodes.length;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get numKernings():uint
		{
			return _kerningsCharCodes.length / 2;
		}
	
		/**
		 * @inheritDoc
		 */
		public function get kerningsCharCodes():Vector.<uint>
		{
			return _kerningsCharCodes.concat();
		}
	
		/**
		 * @inheritDoc
		 */
		public function readKerningRecordAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			return _kerningsFontMap[index].readKerningRecordAt(bytes, _kerningsLocalIndexMap[index], offset);
		}
	
		/**
		 * @inheritDoc
		 */
		public function readGlyphShapeAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			return _charsFontMap[index].readGlyphShapeAt(bytes, _charsLocalIndexMap[index], offset);
		}
	
		/**
		 * @inheritDoc
		 */
		public function readAdvanceAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			return _charsFontMap[index].readAdvanceAt(bytes, _charsLocalIndexMap[index], offset);
		}
	
		/**
		 * @inheritDoc
		 */
		public function readAlignZoneAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			return _charsFontMap[index].readAlignZoneAt(bytes, _charsLocalIndexMap[index], offset);
		}
	
		/**
		 * @inheritDoc
		 */
		public function readBoundAt(bytes:ByteArray, index:uint, offset:uint = 0):uint
		{
			return _charsFontMap[index].readBoundAt(bytes, _charsLocalIndexMap[index], offset);
		}
	
		/**
		 * @inheritDoc
		 */
		public function append(...args:Array):IFontDataInput
		{
			if(args.length == 0)
				throw new ArgumentError("No arguments found.");
			
			var fonts:Vector.<IFontDataInput> = _fonts.concat();
			var y:uint = fonts.length, length:uint = args.length;
			fonts.length += args.length;
			for(var i:uint = 0; i < length; i++)
			{
				if(args[i] is Vector.<IFontDataInput>)
				{
					var vect:Vector.<IFontDataInput> = args[i] as Vector.<IFontDataInput>;
					var vectLength:uint = vect.length;
					fonts.length += vectLength - 1;
					for(var j:uint = 0; j < vectLength; j++)
						fonts[y++] = vect[j];
					continue;
				}
				if(!(args[i] is IFontDataInput))
					throw new TypeError("Invalid type: " + getQualifiedClassName(args[i]));
				fonts[y++] = args[i];
			}
			return new FontDataInputUnion(fonts);
		}
	}
}
