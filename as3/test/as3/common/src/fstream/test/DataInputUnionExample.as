package fstream.test {

	import fstream.utils.FontDataInputUnion;
	import fstream.utils.IFontDataInput;
	import fstream.utils.isEqual;

	import flash.display.Sprite;


	/**
	 * @author Memmie Lenglet
	 */
	public class DataInputUnionExample extends Sprite
	{
		public function DataInputUnionExample()
		{
			var fontData1:FontDataInputDefault = new FontDataInputDefault();
			fontData1.fontName = "FontNameTest1";
			fontData1.charCodes = new <uint>[0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15];
			fontData1.kerningsCharCodes = new <uint>[0, 1, 0, 2, 0, 3, 1, 2, 1, 2, 2, 1];
			
			var fontData2:FontDataInputDefault = new FontDataInputDefault();
			fontData2.fontName = "FontNameTest2";
			fontData2.charCodes = new <uint>[5, 6, 7, 8, 9, 10, 11, 12, 16, 17, 18, 19];
			fontData2.kerningsCharCodes = new <uint>[0, 1, 0, 2, 2, 0, 15, 16, 15, 0];
			
			var fontDataUnion:FontDataInputUnion = new FontDataInputUnion(new <IFontDataInput>[fontData1, fontData2]);
			
			trace("charcodes");
			var charCodes:Vector.<uint> = fontDataUnion.charCodes;
			trace(charCodes);
			trace("valid: ", isEqual(charCodes, new <uint>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]));
			
			trace("kerningsCharCodes");
			var kerningsCharCodes:Vector.<uint> = fontDataUnion.kerningsCharCodes;
			trace(kerningsCharCodes);
			trace("valid: ", isEqual(kerningsCharCodes, new <uint>[0, 1, 0, 2, 0, 3, 1, 2, 2, 0, 2, 1, 15, 0, 15, 16]));
		}
	}
}
