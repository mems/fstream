package fstream.test {

	import fstream.utils.IFontDataInput;

	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	public class FontDataInputDefault implements IFontDataInput
	{
	
		private var _fontName:String;
		private var _bold:Boolean;
		private var _italic:Boolean;
		private var _smallText:Boolean;
		private var _csmTableHint:uint;
		private var _languageCode:uint;
		private var _fontAscent:uint;
		private var _fontDescent:uint;
		private var _fontLeading:uint;
		private var _charCodes:Vector.<uint>;
		private var _kerningsCharCodes:Vector.<uint>;
	
		public function FontDataInputDefault() {
			_fontName = "";
			_charCodes = new Vector.<uint>();
			_kerningsCharCodes = new Vector.<uint>();
		}
	
		public function get fontName():String {
			return _fontName;
		}
	
		public function set fontName(value:String):void {
			_fontName = value;
		}
	
		public function get bold():Boolean {
			return _bold;
		}
	
		public function set bold(value:Boolean):void {
			_bold = value;
		}
	
		public function get italic():Boolean {
			return _italic;
		}
	
		public function set italic(value:Boolean):void {
			_italic = value;
		}
	
		public function get smallText():Boolean {
			return _smallText;
		}
	
		public function set smallText(value:Boolean):void {
			_smallText = value;
		}
	
		public function get csmTableHint():uint {
			return _csmTableHint;
		}
	
		public function set csmTableHint(value:uint):void {
			_csmTableHint = value;
		}
	
		public function get languageCode():uint {
			return _languageCode;
		}
	
		public function set languageCode(value:uint):void {
			_languageCode = value;
		}
	
		public function get fontAscent():uint {
			return _fontAscent;
		}
	
		public function set fontAscent(value:uint):void {
			_fontAscent = value;
		}
	
		public function get fontDescent():uint {
			return _fontDescent;
		}
	
		public function set fontDescent(value:uint):void {
			_fontDescent = value;
		}
	
		public function get fontLeading():uint {
			return _fontLeading;
		}
	
		public function set fontLeading(value:uint):void {
			_fontLeading = value;
		}
	
		public function get numChars():uint {
			return _charCodes.length;
		}
	
		public function set numChars(value:uint):void {
			_charCodes.length = value;
		}
	
		public function get charCodes():Vector.<uint> {
			return _charCodes;
		}
	
		public function set charCodes(value:Vector.<uint>):void {
			_charCodes = value;
		}
	
		public function get numKernings():uint {
			return _kerningsCharCodes.length / 2;
		}
	
		public function set numKernings(value:uint):void {
			_kerningsCharCodes.length = value / 2;
		}
	
		public function get kerningsCharCodes():Vector.<uint> {
			return _kerningsCharCodes;
		}
	
		public function set kerningsCharCodes(value:Vector.<uint>):void {
			_kerningsCharCodes = value;
		}
	
		public function readKerningRecordAt(bytes:ByteArray, index:uint, offset:uint = 0):uint {
			bytes.position = offset;
			bytes.writeShort(_kerningsCharCodes[index * 2]);
			bytes.writeShort(_kerningsCharCodes[index * 2 + 1]);
			bytes.writeShort(0x0000);
			return 6;
		}
	
		public function readGlyphShapeAt(bytes:ByteArray, index:uint, offset:uint = 0):uint {
			bytes.position = offset;
			bytes.writeByte(0x20);//2 fills and lines
			bytes.writeByte(0x00);//end of shape
			return 2;
		}
	
		public function readAdvanceAt(bytes:ByteArray, index:uint, offset:uint = 0):uint {
			bytes.position = offset;
			bytes.writeShort(0);
			return 2;
		}
	
		public function readAlignZoneAt(bytes:ByteArray, index:uint, offset:uint = 0):uint {
			bytes.position = offset;
			bytes.writeByte(2);
			bytes.writeUnsignedInt(0x00000000);
			bytes.writeUnsignedInt(0x00000000);
			bytes.writeByte(0x03);
			return 10;
		}
	
		public function readBoundAt(bytes:ByteArray, index:uint, offset:uint = 0):uint {
			bytes.position = offset;
			bytes.writeByte(0);
			return 1;
		}
	
		public function append(...args:Array):IFontDataInput {
			throw new IllegalOperationError("Not supported in FontDataInputTest");
			return null;
		}
	}
}
