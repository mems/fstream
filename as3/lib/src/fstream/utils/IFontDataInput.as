package fstream.utils {

	import flash.utils.ByteArray;
	
	/**
	 * Interface define methods to read font data. Usually in a SWF file stream.
	 * @author Memmie Lenglet
	 */
	public interface IFontDataInput
	{
		/**
		 * Define the font name
		 */
		function get fontName():String;
		
		/**
		 * Define if the font style is bold
		 */
		function get bold():Boolean;
		
		/**
		 * Define if the font style is italic
		 */
		function get italic():Boolean;
		
		/**
		 * Define if the font is small.
		 * Character glyphs are aligned on pixel boundaries for dynamic and input text.
		 */
		function get smallText():Boolean;
		
		/**
		 * Font thickness hint. Refers to the thickness of the typical stroke used in the font.
		 * 0 = thin
		 * 1 = medium
		 * 2 = thick
		 * Flash Player maintains a selection of CSM tables for many fonts. However, if the font is not found in Flash Player's internal table, this hint is used to choose an appropriate table.
		 */
		function get csmTableHint():uint;
		
		/**
		 * Flash Player uses language codes to determine line-breaking rules for dynamic text, and to choose backup fonts when a specified device font is unavailable. Other uses for language codes may be found in the future.
		 * A language code of zero means no language. This code results in behavior that is dependent on the locale in which Flash Player is running. At the time of writing, the following language codes are recognized by Flash Player:
		 * 1 = Latin (the western languages covered by Latin-1: English, French, German, and so on)
		 * 2 = Japanese
		 * 3 = Korean
		 * 4 = Simplified Chinese
		 * 5 = Traditional Chinese
		 */
		function get languageCode():uint;
		
		/**
		 * Font ascender height.
		 */
		function get fontAscent():uint;
		
		/**
		 * Font descender height.
		 */
		function get fontDescent():uint;
		
		/**
		 * Font leading height
		 * It is a vertical line-spacing metric. It is the distance (in EM-square coordinates) between the bottom of the descender of one line and the top of the ascender of the next line.
		 */
		function get fontLeading():uint;
		
		/**
		 * Fast access to number of glyphs in font.
		 */
		function get numChars():uint;
		
		/**
		 * Sorted char codes in ascent order.
		 * All char codes are Unicodes.
		 */
		function get charCodes():Vector.<uint>;
		
		/**
		 * Fast access to number of kernings in font.
		 */
		function get numKernings():uint;
		
		/**
		 * Sorted kernings char code in ascent order.
		 * It's two dimension array. Its length equal to <code>kerningsCharCodes.length = numKernings * 2</code>. For accessing both left and right char codes, read it like that: <code>left = kerningsCharCodes[index * 2]; right = kerningsCharCodes[index * 2 + 1];</code>
		 * NOTE: Cache the returned value (in a variable) if you need multiple accesses, to avoid redundant read operations.
		 */
		function get kerningsCharCodes():Vector.<uint>;
		
		/**
		 * Read bytes of specified kerning
		 * A Kerning Record defines the distance between two glyphs in EM square coordinates. Certain pairs of glyphs appear more aesthetically pleasing if they are moved closer together, or farther apart. The FontKerningCode1 and FontKerningCode2 fields are the character codes for the left and right characters. The FontKerningAdjustment field is a signed integer that defines a value to be added to the advance value of the left character.
		 * @param bytes Bytes to read into
		 * @param index Kerning index.
		 * @param offset Offset in provided ByteArray to start writing.
		 * @return Number of bytes written
		 */
		function readKerningRecordAt(bytes:ByteArray, index:uint, offset:uint = 0):uint;
		
		/**
		 * Read glyph bytes of specified char
		 * @param bytes Bytes to read into
		 * @param index Char index.
		 * @param offset Offset in provided ByteArray to start writing.
		 * @return Number of bytes written
		 */
		function readGlyphShapeAt(bytes:ByteArray, index:uint, offset:uint = 0):uint;
		
		/**
		 * Advance value to be used for each glyph in dynamic glyph text.
		 * @param bytes Bytes to read into
		 * @param index Char index.
		 * @param offset Offset in provided ByteArray to start writing.
		 * @return Number of bytes written
		 */
		function readAdvanceAt(bytes:ByteArray, index:uint, offset:uint = 0):uint;
		
		/**
		 * Read align bytes of specified char (SWF ZONERECORD format)
		 * NOTE: NumZoneData must be always 2. Total in bytes is 10.
		 * @param bytes Bytes to read into
		 * @param index Char index.
		 * @param offset Offset in provided ByteArray to start writing.
		 * @return Number of bytes written
		 */
		function readAlignZoneAt(bytes:ByteArray, index:uint, offset:uint = 0):uint;
		
		/**
		 * Read bound bytes of specified char (SWF RECT format)
		 * @param bytes Bytes to read into
		 * @param index Char index.
		 * @param offset Offset in provided ByteArray to start writing.
		 * @return Number of bytes written
		 */
		function readBoundAt(bytes:ByteArray, index:uint, offset:uint = 0):uint;
		
		/**
		 * Make an union with others IFontDataInput
		 * Current data include font name, style, metrics ands chars (glyphs, bounds, etc.) take precedence over others appended.
		 * 
		 * @throws TypeError Invalid type. One of provided argument don't implement IFontDataInput interface
		 */
		function append(...args:Array):IFontDataInput;
	}
}