package fstream.net {

	import flash.text.Font;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;


	/**
	 * Class handling font loading
	 * NOTE: In HTTP with IE, GET requests are limited to a max length of 2048 chars
	 * @see http://support.microsoft.com/kb/208427
	 * @author Memmie Lenglet
	 */
	public class FontLoader extends EventDispatcher
	{	
		//Listen exit frame events for waiting all embedFont calls (wait the last moment to update) in current execution frame
		//@see http://blog.joa-ebert.com/2010/10/03/opening-the-blackbox/
		//@see http://www.craftymind.com/2008/04/18/updated-elastic-racetrack-for-flash-9-and-avm2/
		static private const HEARTBEAT:EventDispatcher = new Bitmap();
		
		static private var _globalLoaders:Vector.<GlobalFontLoader> = new Vector.<GlobalFontLoader>();
		
		private var _globalLoader:GlobalFontLoader;
		private var _maxRequests:uint = GlobalFontLoader.defaultMaxRequests;
		private var _font:Font;

		public function FontLoader(request:FontRequest = null)
		{
			if(request != null)
				load(request);
		}
		
		public function get font():Font
		{
			return _font;
		}
		
		/**
		 * Max simultaneous requests
		 */
		public function get maxRequests():uint
		{
			return _globalLoader != null ? _globalLoader.maxRequests : _maxRequests;
		}
		
		public function set maxRequests(value:uint):void
		{
			_maxRequests = value;
			if(_globalLoader)
				_globalLoader.maxRequests = value;
		}
		
		static public function get defaultMaxRequests():uint
		{
			return GlobalFontLoader.defaultMaxRequests;
		}
		
		static public function set defaultMaxRequests(value:uint):void
		{
			GlobalFontLoader.defaultMaxRequests = value;
		}
		
		public function load(request:FontRequest):void
		{
			var fontName:String = request.fontName;
			if(fontName == "" || fontName == null)
				Error.throwError(ArgumentError, 2007, "fontName");
			var fontStyle:String = request.fontStyle;
			if(fontStyle == "" || fontStyle == null)
				Error.throwError(ArgumentError, 2007, "fontStyle");
			var chars:String = request.chars;
//			if(chars == "" || chars == null)
//				Error.throwError(ArgumentError, 2007, "chars");
			
			_font = null;
			
			//Previous GlobalFontLoader
			close();
			
			if(chars == "" || chars == null)
			{
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			for each(var globalLoader:GlobalFontLoader in _globalLoaders)
			{
				if(!globalLoader.loading && globalLoader.request.fontName == fontName && globalLoader.request.fontStyle == fontStyle)
				{
					globalLoader.request.chars += chars;
					_globalLoader = globalLoader;
					break;
				}
			}
			
			if(_globalLoader == null)
			{
				_globalLoader = new GlobalFontLoader();
				_globalLoader.maxRequests = _maxRequests;
				_globalLoader.request = request.clone();
				_globalLoader.addEventListener(Event.COMPLETE, font_eventHandler);
				_globalLoader.addEventListener(IOErrorEvent.IO_ERROR, font_eventHandler);
				_globalLoaders.push(_globalLoader);
			}
			
			_globalLoader.addEventListener(Event.COMPLETE, eventHandler);
			_globalLoader.addEventListener(Event.COMPLETE, eventHandler);
			
			//Wait until exit frame in case of other font requested
			HEARTBEAT.addEventListener(Event.EXIT_FRAME, heartbeat_exitFrameHandler, false, 0, true);
		}
		
		public function close():void
		{
			if(_globalLoader != null)
			{
				if(_globalLoader.loading)
					_globalLoader.close();
				_globalLoader.removeEventListener(Event.COMPLETE, eventHandler);
				_globalLoader.removeEventListener(IOErrorEvent.IO_ERROR, eventHandler);
				_globalLoaders.splice(_globalLoaders.indexOf(_globalLoader), 1);
				_globalLoader = null;
			}
		}

		private function eventHandler(event:Event):void
		{
			_globalLoader.removeEventListener(Event.COMPLETE, eventHandler);
			_globalLoader.removeEventListener(IOErrorEvent.IO_ERROR, eventHandler);
			_font = _globalLoader.font;
			_globalLoader = null;
			dispatchEvent(event);
		}
		
		/*
		 * Make font requests processing (filter, sort, match with current fonts, etc.)
		 */
		static private function heartbeat_exitFrameHandler(event:Event):void
		{
			HEARTBEAT.removeEventListener(Event.EXIT_FRAME, heartbeat_exitFrameHandler);

			for each(var globalLoader:GlobalFontLoader in _globalLoaders)
			{
				if(!globalLoader.loading)
					globalLoader.load();
			}
		}

		static private function font_eventHandler(event:Event):void
		{
			var globalLoader:GlobalFontLoader = event.currentTarget as GlobalFontLoader;
			globalLoader.removeEventListener(Event.COMPLETE, font_eventHandler);
			globalLoader.removeEventListener(IOErrorEvent.IO_ERROR, font_eventHandler);
			_globalLoaders.splice(_globalLoaders.indexOf(globalLoader), 1);
		}
	}
}

