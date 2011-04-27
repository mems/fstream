package fstream.utils {

	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * Generate a uncompressed SWF (FWS) with one embedded font and it own class
	 * Contains the strict minimum of data (no metadata, no MainClass, only FontClass, no background color, stage size [0 x 0], etc.)
	 * NOTICE: All tags (except FileAttributes and ShowFrame/End) use the tag length in its extended format
	 * NOTICE: Here, DefineFont3 always use flags hasLayout wideoffset and widecode as true
	 * NOTICE: Font data could be corrupted, but don't have any security impact since all SWF tags define there length. The only problem could be with <code>Loader.loadBytes()</code> which will never dispatch an <code>Event.COMPLETE</code> event.
	 * @author Memmie Lenglet
	 */
	//TODO use Memory for read/write operations
	//TODO replace superclass of embedded font class by an custom class, for adding the ability to read / override glyphs data
	public class SWFFontDataOutput implements IFontDataOutput
	{
		// SWF header signature
		static private const SWF_SIGN:uint = 0x465753;//FWS
		
		static private const BYTE:uint = 1;
		static private const SHORT:uint = 2;
		static private const LONG:uint = 4;
		
		private var _bytes:ByteArray;
		private var _fontClassName:String;
		
		/**
		 * @param bytes ByteArray where all data will be written
		 */
		public function SWFFontDataOutput(bytes:ByteArray)
		{
			_bytes = bytes;
			_bytes.endian = Endian.LITTLE_ENDIAN;
		}
		
		/**
		 * Define full qualified class name use to link embedded font to an AS3 class
		 * Default auto generated syntax: <code>fstream.fonts.EmbeddedFont$HelveticaNeue85UltraLight_regular</code> where font name is "Helvetica Neue 85 Ultra Light" on font style is "regular" (a flash <code>FontStyle</code> supported)
		 * NOTE: The separator of class and its package is "." or "::". Classname or package could contains invalid chars (not supported by ASC - ActionScript Compiler) like symbol, space, null chars, etc. but can produce errors throught <code>getDefinitionByClassName()</code> or <code>applicationDomain.getDefinition()</code> calls.
		 */
		public function get fontClassName():String
		{
			return _fontClassName;
		}
		
		public function set fontClassName(value:String):void
		{
			_fontClassName = value;
		}
		
		/**
		 * NOTE: All NumZoneData must be always 2 (like it written in SWF specification).
		 */
		public function writeDefineFontAlignZones(fontData:IFontDataInput):void
		{
			var length:uint = fontData.numChars;
			_bytes.writeShort(73 << 6 | 0x3F);
			_bytes.writeUnsignedInt(SHORT + BYTE + length * (SHORT * 4 + BYTE * 2));
			_bytes.writeShort(0x0001);
			_bytes.writeByte((fontData.csmTableHint & 0x03) << 6);
			var currentPosition:uint = _bytes.position;
			for(var i:uint = 0; i < length; i++)
				currentPosition += fontData.readAlignZoneAt(_bytes, i, currentPosition);
			_bytes.position = currentPosition;
		}
	
		/**
		 * Write Font tag (DefineFont3, ID = 75)
		 */
		public function writeDefineFont3(fontData:IFontDataInput):void
		{
			_bytes.writeShort(75 << 6 | 0x3F);
			_bytes.writeUnsignedInt(0x00000000);//temp size
			var beginPosition:uint = _bytes.position;
			
			//Font ID
			_bytes.writeShort(0x0001);
	
			//FontFlags has layout + ShiftJIS + small text + ANSI + WideOffsets + WideCodes + italic + bold
			//Always define hasLayout, WideOffsets and WideCodes to true (in our case)
			//10X011XX
			var flags:uint = 0x8C;
			if(fontData.smallText)
				flags |= 0x20;
			if(fontData.italic)
				flags |= 0x02;
			if(fontData.bold)
				flags |= 0x01;
			_bytes.writeByte(flags);
			
			//LanguageCode
			_bytes.writeByte(fontData.languageCode);
			
			var fontName:String = fontData.fontName;
			//FontNameLen
			_bytes.writeByte(getUTFStringBytesLength(fontName));
			
			//FontName
			_bytes.writeUTFBytes(fontName);
			
			//NumGlyphs
			var numChars:uint = fontData.numChars;
			_bytes.writeShort(numChars);
			
			//Skip OffsetTable and CodeTableOffset
			var offsetTablePosition:uint = _bytes.position;
			var glyphShapeBytesOffsets:Vector.<uint> = new Vector.<uint>(numChars + 1);//for each chars (OffsetTable) + CodeTableOffset
			//_bytes.length += LONG * numChars + LONG;
			_bytes.position += LONG * numChars + LONG;
			
			//GlyphShapeTable
			var currentPosition:uint = _bytes.position;
			var bytesLength:uint, currentOffset:uint = glyphShapeBytesOffsets[0] = LONG * numChars + LONG;
			for(var i:uint = 0; i < numChars; i++)
			{
				bytesLength = fontData.readGlyphShapeAt(_bytes, i, currentPosition);
				currentOffset += bytesLength;
				glyphShapeBytesOffsets[i + 1] = currentOffset;
				currentPosition += bytesLength;
			}
			
			//Back to OffsetTable + CodeTableOffset
			_bytes.position = offsetTablePosition;
			for(i = 0; i <= numChars; i++)//for each chars (OffsetTable) + CodeTableOffset
				_bytes.writeUnsignedInt(glyphShapeBytesOffsets[i]);
			
			_bytes.position = currentPosition;
			
			//CodeTable
			var charCodes:Vector.<uint> = fontData.charCodes;
			for(i = 0; i < numChars; i++)
				_bytes.writeShort(charCodes[i]);
			
			//FontAscent
			_bytes.writeShort(fontData.fontAscent);
			
			//FontDescent
			_bytes.writeShort(fontData.fontDescent);
			
			//FontLeading
			_bytes.writeShort(fontData.fontLeading);
			
			//FontAdvanceTable
			currentPosition = _bytes.position;
			for(i = 0; i < numChars; i++)
				currentPosition += fontData.readAdvanceAt(_bytes, i, currentPosition);
			_bytes.position = currentPosition;
			
			//FontBoundsTable
			currentPosition = _bytes.position;
			for(i = 0; i < numChars; i++)
				currentPosition += fontData.readBoundAt(_bytes, i, currentPosition);
			_bytes.position = currentPosition;
			
			//KerningCount
			var numKernings:uint = fontData.numKernings;
			_bytes.writeShort(numKernings);
			
			//FontKerningTable
			currentPosition = _bytes.position;
			for(i = 0; i < numKernings; i++)
				currentPosition += fontData.readKerningRecordAt(_bytes, i, currentPosition);
			
			//write in tag header the tag length
			var endPosition:uint = currentPosition;
			_bytes.position = beginPosition - LONG;
			_bytes.writeUnsignedInt(endPosition - beginPosition);
			
			_bytes.position = endPosition;
		}
		
		/**
		 * Write ABC bytecode tag (DoABC, ID = 82) define one class named with provided full qualified name <code>([&lt;packagename&gt;.]&lt;classname&gt;)</code> extending <code>flash.text.Font</code>
		 * @see http://www.adobe.com/devnet/actionscript/articles/avm2overview.pdf
		 * @see http://lists.motion-twin.com/pipermail/haxe/2009-July/027198.html
		 * @see http://lists.motion-twin.com/pipermail/haxe/attachments/20090707/3ed203ef/Hello-0001.obj
		 * @see http://lists.motion-twin.com/pipermail/haxe/attachments/20090707/3ed203ef/Context-0001.obj
		 * @see https://github.com/jcheng/as3abc/blob/master/src/com/codeazur/as3abc/
		 * @see http://code.google.com/p/hxformat/source/browse/trunk/format/abc/
		 * @see http://hg.mozilla.org/tamarin-central/file/fbecf6c8a86f/utils
		 */
		public function writeDoABCTag(fontQualifiedClassName:String):void
		{
			var packageName:String = "", className:String, lastIndexOf:int;
			
			if((lastIndexOf = fontQualifiedClassName.lastIndexOf("::")) >= 0)
			{
				packageName = fontQualifiedClassName.substring(0, lastIndexOf);
				className = fontQualifiedClassName.substring(lastIndexOf + 2);
			}
			else if((lastIndexOf = fontQualifiedClassName.lastIndexOf(".")) >= 0)
			{
				packageName = fontQualifiedClassName.substring(0, lastIndexOf);
				className = fontQualifiedClassName.substring(lastIndexOf + 1);
			}
			else
			{
				className = fontQualifiedClassName;
			}
			
			_bytes.writeShort(82 << 6 | 0x3F);
			_bytes.writeUnsignedInt(0x00000000);//temp size
			var beginPosition:uint = _bytes.position;
			
			_bytes.writeUnsignedInt(0x00000000);//Flags, kDoAbcLazyInitializeFlag = 0
			writeString(null);//Name STRING, null
			_bytes.writeShort(16);//minor_version u16, 16
			_bytes.writeShort(46);//major_version u16, 46
			//constant_pool cpool_info
			{
				_bytes.writeByte(1);//int_count u30, 0 + 1
				_bytes.writeByte(1);//uint_count u30, 0 + 1
				_bytes.writeByte(1);//double_count u30, 0 + 1
				_bytes.writeByte(7);//string_count u30, 6 + 1
				//string_info string[string_count]
				{
					//ID = 1 ""
					_bytes.writeByte(0);//0 bytes length
					//_bytes.writeUTFBytes("");
					
					//ID = 2 Object
					_bytes.writeByte(6);//6 bytes length
					_bytes.writeUTFBytes("Object");
					
					//ID = 3 flash.text
					_bytes.writeByte(10);//10 bytes length
					_bytes.writeUTFBytes("flash.text");
					
					//ID = 4 Font
					_bytes.writeByte(4);//4 bytes length
					_bytes.writeUTFBytes("Font");
					
					if(packageName != "")
					{
						//ID = 5 <packagename>
						writeEncodedUTF(packageName);
					}
					
					//ID = 6 or 5 <classname>
					writeEncodedUTF(className);
				}
				_bytes.writeByte(4);//namespace_count u30, 3 + 1
				//namespace_info namespace[namespace_count]
				{
					//ID = 1 package namespace ""
					_bytes.writeByte(0x16);//CONSTANT_PackageNamespace
					_bytes.writeByte(1);//string id ""
					
					//ID = 2 package namespace flash.text
					_bytes.writeByte(0x16);//CONSTANT_PackageNamespace
					_bytes.writeByte(3);//string id flash.text
					
					if(packageName != "")
					{
						//ID = 3 package namespace <packagename>
						_bytes.writeByte(0x16);//CONSTANT_PackageNamespace
						_bytes.writeByte(5);//string id <packagename>
					}
				}
				_bytes.writeByte(2);//ns_set_count 1 + 1//Don't know if needed (I don't know exactly what is it)
				//ns_set[ns_set_count] ns_set_info
				{
					_bytes.writeByte(1);//count 1
					_bytes.writeByte(1);//namespace id ""
				}
				_bytes.writeByte(4);//multiname_count 3 + 1
				//multiname[multiname_count] multiname_info
				{
					//ID 1 qname .Object
					_bytes.writeByte(0x07);//CONSTANT_QName
					_bytes.writeByte(1);//namespace id ""
					_bytes.writeByte(2);//string id Object
					
					//ID 2 qname flash.text.Font
					_bytes.writeByte(0x07);//CONSTANT_QName
					_bytes.writeByte(2);//namespace id flash.text
					_bytes.writeByte(4);//string id Font
					
					//ID 3 qname <packagename>.<classname>
					_bytes.writeByte(0x07);//CONSTANT_QName
					_bytes.writeByte(packageName != "" ? 3 : 1);//namespace id <packagename> or ""
					_bytes.writeByte(6);//string id <classname>
				}
			}
			_bytes.writeByte(3);//method_count u30
			//method[method_count] method_info
			{
				//ID 0 init():* top level script (declarations)
				_bytes.writeByte(0);//no parameters
				_bytes.writeByte(0);//type wildcard
				_bytes.writeByte(0);//no name
				_bytes.writeByte(0);//flags
				
				//ID 1 cinit():* static initializer
				_bytes.writeByte(0);//no parameters
				_bytes.writeByte(0);//type wildcard
				_bytes.writeByte(0);//no name
				_bytes.writeByte(0);//flags
				
				//ID 2 iinit/ctor():* instance initializer/instance constructor
				_bytes.writeByte(0);//no parameters
				_bytes.writeByte(0);//type wildcard
				_bytes.writeByte(0);//no name
				_bytes.writeByte(0);//flags
			}
			_bytes.writeByte(0);//metadata_count
			_bytes.writeByte(1);//class_count
			//instance[class_count] instance_info
			{
				//ID 0 <packagename>.<classname>
				_bytes.writeByte(3);//name
				_bytes.writeByte(2);//super_name flash.text Font
				_bytes.writeByte(0x03);//flags u8, 0x01 | 0x02 (sealed and final class)
				_bytes.writeByte(0);//intrf_count
				_bytes.writeByte(2);//iinit (instance initializer)
				_bytes.writeByte(0);//trait_count u30, 0
			}
			//class[class_count] class_info
			{
				//ID 0 <packagename>.<classname>
				_bytes.writeByte(1);//cinit
				_bytes.writeByte(0);//trait_count u30, 0
			}
			_bytes.writeByte(1);//script_count u30
			//script_info script[[script_count] script
			{
				_bytes.writeByte(0);//init
				_bytes.writeByte(1);//trait_count u30, 1
				//trait[trait_count] traits_info
				{
					//<packagename>.<classname>
					_bytes.writeByte(3);//name
					_bytes.writeByte(4);//kind Trait_Class
					_bytes.writeByte(0);//slot id
					_bytes.writeByte(0);//class id
				}
			}
			_bytes.writeByte(3);//method_body_count u30
			//method_body[method_body_count] method_body_info
			{
				//ID = 0 init
				_bytes.writeByte(0);//method id
				_bytes.writeByte(2);//max_stack
				_bytes.writeByte(1);//local_count = 0 + 1
				_bytes.writeByte(0);//init_scope_depth
				_bytes.writeByte(4);//max_scope_depth
				_bytes.writeByte(18);//code_length in bytes
				_bytes.writeByte(0xD0);//code = getlocal 0//this.
				_bytes.writeByte(0x30);//code = pushscope
				_bytes.writeByte(0x64);//code = getglobalscope
				
				_bytes.writeByte(0x60);//code = getlex
				_bytes.writeByte(1);//code = superclass Object
				_bytes.writeByte(0x30);//code = pushscope
				
				_bytes.writeByte(0x60);//code = getlex
				_bytes.writeByte(2);//code = superclass flash.text.Font
				_bytes.writeByte(0x30);//code = pushscope
				
				_bytes.writeByte(0x60);//code = getlex
				_bytes.writeByte(2);//code = superclass flash.text.Font
				
				_bytes.writeByte(0x58);//code = newclass
				_bytes.writeByte(0);//code = class <packagename>.<classname>
				
				_bytes.writeByte(0x1D);//code = popscope
				_bytes.writeByte(0x1D);//code = popscope
				
				_bytes.writeByte(0x68);//code = initproperty
				_bytes.writeByte(3);//code = class <packagename>.<classname>
				
				_bytes.writeByte(0x47);//code = returnvoid//return void;
				_bytes.writeByte(0);//exception_count
				_bytes.writeByte(0);//trait_count
				
				//ID = 1 cinit
				_bytes.writeByte(1);//method id
				_bytes.writeByte(0);//max_stack
				_bytes.writeByte(1);//local_count = 0 + 1
				_bytes.writeByte(0);//init_scope_depth
				_bytes.writeByte(0);//max_scope_depth
				_bytes.writeByte(1);//code_length in bytes
				_bytes.writeByte(0x47);//code = returnvoid//return void;
				_bytes.writeByte(0);//exception_count
				_bytes.writeByte(0);//trait_count
				
				//ID = 2 iinit/ctor
				_bytes.writeByte(2);//method id
				_bytes.writeByte(1);//max_stack
				_bytes.writeByte(1);//local_count = 0 + 1
				_bytes.writeByte(0);//init_scope_depth
				_bytes.writeByte(0);//max_scope_depth
				_bytes.writeByte(4);//code_length in bytes
				_bytes.writeByte(0xD0);//code = getlocal 0//this.
				_bytes.writeByte(0x49);//code = constructsuper//super
				_bytes.writeByte(0);//code = with 0 args//();
				_bytes.writeByte(0x47);//code = returnvoid//return void;
				_bytes.writeByte(0);//exception_count
				_bytes.writeByte(0);//trait_count
			}
			
			//write in tag header the tag length
			var endPosition:uint = _bytes.position;
			_bytes.position = beginPosition - LONG;
			_bytes.writeUnsignedInt(endPosition - beginPosition);
			
			_bytes.position = endPosition;
		}
		
		/**
		 * U32 type
		 * Used for ABC data
		 * @see http://www.adobe.com/devnet/actionscript/articles/avm2overview.pdf 4.1 Primitive data types
		 */
		public function writeEncodedUInt(value:uint):void
		{	
			if (value < 0x80)
			{
			    _bytes.writeByte(value);
			}
			else if (value < 0x4000)
			{
				_bytes.writeByte((value & 0x7F) | 0x80);
				_bytes.writeByte((value >> 7) & 0x7F);
			}
			else if (value < 0x200000)
			{
				_bytes.writeByte((value & 0x7F) | 0x80);
				_bytes.writeByte((value >> 7) | 0x80);
				_bytes.writeByte((value >> 14) & 0x7F);
			}
			else if (value < 0x10000000)
			{
				_bytes.writeByte((value & 0x7F) | 0x80);
				_bytes.writeByte(value >> 7 | 0x80);
				_bytes.writeByte(value >> 14 | 0x80);
				_bytes.writeByte((value >> 21) & 0x7F);
			}
			else
			{
				_bytes.writeByte((value & 0x7F) | 0x80);
				_bytes.writeByte(value >> 7 | 0x80);
				_bytes.writeByte(value >> 14 | 0x80);
				_bytes.writeByte(value >> 21 | 0x80);
				_bytes.writeByte((value >> 28) & 0x0F);
			}
	    }
	    
	    /**
	     * String with its length written at the begin as an encoded uint
	     * @see writeEncodedUInt()
	     */
	    public function writeEncodedUTF(value:String):void
	    {
	    	writeEncodedUInt(getUTFStringBytesLength(value));
	    	_bytes.writeUTFBytes(value);
	    }
	
		/**
		 * Write SymbolClass SWF tag
		 */
		public function writeSymbolClassTag(fontQualifiedClassName:String):void
		{
			var tagLength:uint = SHORT * 2 + getUTFStringBytesLength(fontQualifiedClassName) + BYTE;
			//SymbolClass tag
			//Header RECORDHEADER, code 76 + tagLength bytes length
			_bytes.writeShort(76 << 6 | 0x3F);
			_bytes.writeUnsignedInt(tagLength);
			//NumSymbols UI16, 2
			_bytes.writeShort(1);
			//Tag2 UI16, 1 (first DefineFont3 ID, 0 is for MainDocumentClass if exist)
			_bytes.writeShort(1);
			//Name2 STRING, fontQualifiedClassName
			writeString(fontQualifiedClassName);
		}
		
		/**
		 * Write a string null terminated (char 0)
		 * @see http://en.wikipedia.org/wiki/UTF8#Design
		 * @see http://www.adobe.com/content/dam/Adobe/en/devnet/swf/pdf/swf_file_format_spec_v10.pdf#nameddest=G4.84620
		 */
		public function writeString(value:String = ""):void
		{
			if(value != null && value != "")
				_bytes.writeUTFBytes(value);
			_bytes.writeByte(0x00);//null char
		}
			
		/**
		 * Write SWF header with this informations:
		 * - uncompress
		 * - version 10
		 * - size [0x0]
		 * - file size 0 (must be overwritten)
		 * - 0 fps
		 * - one frame (require 1 ShowFrame tag)
		 * - FileAttributes tag with ActionScript3 flag = true
		 */
		private function writeHeader():void
		{
			//Signature UI8+UI8+UI8, uncompressed
			_bytes.writeByte(SWF_SIGN >> 16 & 0xFF);
			_bytes.writeByte(SWF_SIGN >> 8 & 0xFF);
			_bytes.writeByte(SWF_SIGN & 0xFF);
			//Version UI8, SWF10
			_bytes.writeByte(10);
			//FileLength UI32
			_bytes.writeUnsignedInt(0x000000);
			//FrameSize RECT, [0,0,0,0] if you set 0 for num bits, some parser fail to handle it correctly
			_bytes.writeByte(0);
			/*
			_bytes.writeByte(2 << 3);//2 num bits
			_bytes.writeByte(0);
			*/
			//FrameRate UI16 (8.8 fixed), 0fps
			_bytes.writeShort(0x0000);
			//FrameCount UI16, 1 frame (need at least 1 frame, else FlashPlayer never dispatch complete load event)
			_bytes.writeShort(0x0001);
			//FileAttributes tag
			//Header RECORDHEADER, (short) code 69 + 4 bytes length
			_bytes.writeShort(69 << 6 | LONG);//writeSWFTagHeader(bytes, 69, 4);
			//Flags UI32, all equal 0 except ActionScript3
			_bytes.writeByte(0x08);
			//reserved
			_bytes.writeByte(0x00);_bytes.writeShort(0x0000);
		}
		
		/**
		 * Write given font in a SWF container
		 */
		public function writeFont(font:IFontDataInput):void
		{
			if(_fontClassName == null || _fontClassName == "")
			{
				//remove spaces and uppercase first word letters: "  my class .  name  " will produce "MyClassName"
				var classNamePart:String = font.fontName.replace(/\.|(::)/gi, "").replace(/(\s+)(\S{1,1}?)/gi, removeSpacesUpperFirstLetter);
				_fontClassName = "fstream.fonts.EmbeddedFont$" + classNamePart.substr(0, 1).toUpperCase() + classNamePart.substr(1);
				if(font.bold && font.italic)
					_fontClassName += "_boldItalic";
				else if(font.bold)
					_fontClassName += "_bold";
				else if(font.italic)
					_fontClassName += "_italic";
				else
					_fontClassName += "_regular";
			}
			
			var beginPos:uint = _bytes.position;
			writeHeader();
			writeDefineFont3(font);
			writeDefineFontAlignZones(font);
			writeDoABCTag(_fontClassName);
			writeSymbolClassTag(_fontClassName);
			//ShowFrame tag required
			//Header RECORDHEADER, (short) code 1 + 0 bytes length
			_bytes.writeShort(1 << 6);
			//no end tag needed
			
			//Write total length
			var endPos:uint = _bytes.position;
			_bytes.position = beginPos + BYTE * 4;
			_bytes.writeUnsignedInt(endPos - beginPos);
		}
		
		/**
		 * Used default fontClassName generator, located in writeFont()
		 */
		private function removeSpacesUpperFirstLetter():String
		{
			return String(arguments[2]).toUpperCase();
		}
	}
}
