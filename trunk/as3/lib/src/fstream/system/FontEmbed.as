package fstream.system {

	import fstream.utils.SWFFontDataInput;
	import fstream.utils.FontDataInputUnion;
	import fstream.utils.IFontDataInput;
	import fstream.utils.SWFFontDataOutput;

	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.Font;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	/**
	 * Internal class used by FontSystem to store data of a specific font before the font will be runtime loaded
	 */
	internal class FontEmbed extends EventDispatcher
	{
		private static var _fonts:Dictionary = new Dictionary(true);
		
		private var _previousLoaderInfo:LoaderInfo;
		private var _loaderInfo:LoaderInfo;
		public var fontData:Vector.<IFontDataInput> = new Vector.<IFontDataInput>();
		private var _className:String;
		public var fontName:String;
		public var fontStyle:String;
		private var _embedding:Boolean = false;
		private var _font:Font;
		
		public function get embedding():Boolean
		{
			return _embedding;
		}
		
		public function get font():Font
		{
			return _font;
		}

		public function embed():void
		{
			if(_embedding)
				throw new Error("Unable to call embed during an embed.");
			
			_font = null;
			_embedding = true;
			
			var loader:Loader = new Loader();
			var finalFontData:Vector.<IFontDataInput> = fontData.concat();//copy
		
			//NOTICE Never reuse the same loader, could be a memory leak. See http://www.senocular.com/?entry=460
			_loaderInfo = loader.contentLoaderInfo;
			_loaderInfo.addEventListener(Event.COMPLETE, eventHandler);
			_loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, eventHandler);
			
			//Search if any font with same name and style exist, to get its LoaderInfo (if available)
			//Overwhile if its LoaderInfo is not available, the font will be overrite (we lost all embedded chars) and its LoaderInfo will not be unloaded.
			{
				for each(var font:Font in Font.enumerateFonts(false))
				{
					if(font.fontName == fontName && font.fontStyle == fontStyle)
						break;
					else
						font = null;
				}
				
				if(font != null && _fonts[font] != null)
				{
					_previousLoaderInfo = _fonts[font];
					finalFontData.unshift(new SWFFontDataInput(_previousLoaderInfo.bytes));
					delete _fonts[font];
				}
			}
			
			var bytes:ByteArray = new ByteArray();
			var swfDataOutput:SWFFontDataOutput = new SWFFontDataOutput(bytes);
			swfDataOutput.writeFont(finalFontData.length > 1 ? new FontDataInputUnion(finalFontData) : finalFontData[0]);
			//get the auto generated className
			_className = swfDataOutput.fontClassName;
			var loaderContext:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));
			// AIR compatibility
			if("allowLoadBytesCodeExecution" in loaderContext) loaderContext["allowLoadBytesCodeExecution"] = true;
			//NOTICE if a generated SWF is corrupted, in some cases no error will be thrown or disptached
			loader.loadBytes(bytes, loaderContext);
		}
		
		private function eventHandler(event:Event):void
		{
			if(!(event is ErrorEvent))
			{
				var fontClass:Class = _loaderInfo.applicationDomain.getDefinition(_className) as Class;
				Font.registerFont(fontClass);
				if(_previousLoaderInfo != null)
					_previousLoaderInfo.loader.unloadAndStop();
				
				//Search instance of fontClass instanciated by FlashPlayer
				for each(var font:Font in Font.enumerateFonts(false))
				{
					if(font.fontName == fontName && font.fontStyle == fontStyle)
					{
						_font = font;
						_fonts[font] = _loaderInfo;
						break;
					}
				}
			}
			//TODO if error and available, restore previousLoaderInfo
			
			_loaderInfo.removeEventListener(Event.COMPLETE, eventHandler);
			_loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, eventHandler);
			_loaderInfo = null;
			_previousLoaderInfo = null;
			_embedding = false;
			_className = null;
			
			dispatchEvent(event);
		}
	}
}
