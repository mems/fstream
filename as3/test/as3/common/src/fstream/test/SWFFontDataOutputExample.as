package fstream.test {

	import fstream.utils.IFontDataInput;
	import fstream.utils.SWFFontDataInput;
	import fstream.utils.SWFFontDataOutput;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.ByteArray;

	/**
	 * @author Memmie Lenglet
	 */
	public class SWFFontDataOutputExample extends Sprite
	{
		private var _bytesLoader:URLLoader = new URLLoader();
		private var _loader:Loader;
		private static const QNAME:String = "fstream.fonts.EmbeddedFont";
		
		public function SWFFontDataOutputExample()
		{
			_bytesLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_bytesLoader.addEventListener(Event.COMPLETE, bytesLoader_completeHandler);
			_bytesLoader.load(new URLRequest("assets/Arial Unicode MS_regular.swf"));
		}

		private function bytesLoader_completeHandler(event:Event):void {
			var fontDataInput:IFontDataInput = new SWFFontDataInput(_bytesLoader.data);
			trace("Loaded SWF font:");
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
			/*var fontDataInput:FontDataInputTest = new FontDataInputTest();
			fontDataInput.fontName = "FontNameTest";
			fontDataInput.charCodes = new <uint>[0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15];
			fontDataInput.kerningsCharCodes = new <uint>[0, 1, 0, 2, 0, 3, 1, 2, 2, 1];*/
			var generatedBytes:ByteArray = new ByteArray();
			var fontDataOutput:SWFFontDataOutput = new SWFFontDataOutput(generatedBytes);
			fontDataOutput.fontClassName = QNAME;
			fontDataOutput.writeFont(fontDataInput);
			/*
			generatedBytes.position = 0;
			var reader:IFontDataInput = new SWFFontDataInput(generatedBytes);
			trace("\tfontName: " + reader.fontName);
			trace("\tbold: " + reader.bold);
			trace("\titalic: " + reader.italic);
			trace("\tlanguageCode: " + reader.languageCode);
			trace("\tsmallText: " + reader.smallText);
			trace("\tcsmTableHint: " + reader.csmTableHint);
			trace("\tfontAscent: " + reader.fontAscent);
			trace("\tfontDescent: " + reader.fontDescent);
			trace("\tfontLeading: " + reader.fontLeading);
			trace("\tnumChars: " + reader.numChars);
			trace("\tcharCodes: " + reader.charCodes);
			trace("\tnumKernings: " + reader.numKernings);
			trace("\tkerningsCharCodes: " + reader.kerningsCharCodes);
			
			var bytes:ByteArray = new ByteArray();
			fontDataOutput = new SWFFontDataOutput(bytes);
			fontDataOutput.writeFont(reader, "fstream.fonts.EmbeddedFont");
			
			trace(bytes.length + " bytes generated.");
			
			_fileReference = new FileReference();
			_fileReference.save(bytes, "output2.swf");
			
			/*
			trace(generatedBytes.length + " bytes generated.");
			var fileReference:FileReference = new FileReference();
			fileReference.save(generatedBytes, "output.swf");
			*/
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loader_completeHandler);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
			_loader.loadBytes(generatedBytes);
		}
		
		private function loader_errorHandler(event:IOErrorEvent):void {
			trace("error");
		}

		private function loader_completeHandler(event:Event):void {
			trace("complete");
			trace("actionScriptVersion: " + _loader.contentLoaderInfo.actionScriptVersion);
			trace("bytesTotal: " + _loader.contentLoaderInfo.bytesTotal);
			trace("contentType: " + _loader.contentLoaderInfo.contentType);
			trace("frameRate: " + _loader.contentLoaderInfo.frameRate);
			trace("height: " + _loader.contentLoaderInfo.height);
			trace("swfVersion: " + _loader.contentLoaderInfo.swfVersion);
			trace("width: " + _loader.contentLoaderInfo.width);
			var embeddedFontClass:Class = _loader.contentLoaderInfo.applicationDomain.getDefinition(QNAME) as Class;
			trace("embedded font class object [for " + QNAME + "]: " + embeddedFontClass);
			enumerateFonts();
			Font.registerFont(embeddedFontClass);
			enumerateFonts();
		}
		
		private function enumerateFonts():void
		{
			var output:String = "enumerateFonts:";
			var fonts:Array = Font.enumerateFonts(false);
			for each(var font:Font in fonts)
				output += "\n\tfontName:" + font.fontName + " fontStyle:" + font.fontStyle + " hasGlyphs(0x20):" + font.hasGlyphs(String.fromCharCode(0x20));
			trace(output);
		}
	}
}