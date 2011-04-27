package fstream.test
{
	import fstream.utils.dump;
	import flash.utils.ByteArray;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.events.Event;
	import flash.net.URLLoader;
	import fstream.utils.IFontDataInput;
	import fstream.utils.SWFFontDataInput;
	import flash.display.Sprite;

	/**
	 * @author Memmie Lenglet
	 */
	public class SWFFontDataInputExample extends Sprite
	{
		private var _bytesLoader:URLLoader = new URLLoader();
		
		public function SWFFontDataInputExample()
		{
			_bytesLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_bytesLoader.addEventListener(Event.COMPLETE, bytesLoader_completeHandler);
			_bytesLoader.load(new URLRequest("assets/Arial Unicode MS_regular.swf"));
		}

		private function bytesLoader_completeHandler(event:Event):void {
			var fontDataInput:IFontDataInput = new SWFFontDataInput(_bytesLoader.data);
			trace("SWFFont:");
			trace("\tfontName: " + fontDataInput.fontName);
			trace("\tbold: " + fontDataInput.bold);
			trace("\titalic: " + fontDataInput.italic);
			trace("\tlanguageCode: " + fontDataInput.languageCode);
			trace("\tsmallText: " + fontDataInput.smallText);
			trace("\tcsmTableHint: " + fontDataInput.csmTableHint);
			trace("\tfontAscent: " + fontDataInput.fontAscent);
			trace("\tfontDescent: " + fontDataInput.fontDescent);
			trace("\tfontLeading: " + fontDataInput.fontLeading);
			trace("\tnumChars: " + fontDataInput.numChars);
			trace("\tcharCodes: " + fontDataInput.charCodes);
			trace("\tnumKernings: " + fontDataInput.numKernings);
			trace("\tkerningsCharCodes: " + fontDataInput.kerningsCharCodes);
			
			var advance:ByteArray = new ByteArray();
			fontDataInput.readAdvanceAt(advance, 0);
			trace("\tadvance(0):");
			dump(advance);
			
			var alignZone:ByteArray = new ByteArray();
			fontDataInput.readAlignZoneAt(alignZone, 0);
			trace("\talignZone(0):");
			dump(alignZone);
			
			var bound:ByteArray = new ByteArray();
			fontDataInput.readBoundAt(bound, 0);
			trace("\tbound(0):");
			dump(bound);
			
			var glyphShape:ByteArray = new ByteArray();
			fontDataInput.readGlyphShapeAt(glyphShape, 0);
			trace("\tglyphShape(0):");
			dump(glyphShape);
			
			/*
			var kerningRecord:ByteArray = new ByteArray();
			fontDataInput.readKerningRecordAt(kerningRecord, 0);
			trace("\tkerningRecord(0):");
			dump(kerningRecord);
			*/
		}
	}
}
