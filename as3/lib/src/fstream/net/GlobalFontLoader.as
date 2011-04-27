package fstream.net
{

	import fstream.events.FontStatusEvent;
	import fstream.events.FontErrorEvent;
	import fstream.system.FontManager;
	import fstream.utils.FontDataInputUnion;
	import fstream.utils.IFontDataInput;
	import fstream.utils.SWFFontDataInput;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.ByteArray;
	
	/**
	 * Internal class shared by multiple FontLoader to store a global font request and handle loading of multiple url requests
	 * @author Memmie Lenglet
	 */
	internal class GlobalFontLoader extends EventDispatcher
	{
		private static var _defaultMaxRequests:uint = 4;
		public var request:FontRequest;
		private var _loaders:Vector.<URLLoader> = new Vector.<URLLoader>();
		private var _requests:Vector.<URLRequest> = new Vector.<URLRequest>();
		private var _loading:Boolean = false;
		private var _content:Vector.<IFontDataInput> = new Vector.<IFontDataInput>();
		private var _fontData:IFontDataInput;
		private var _maxRequests:uint;
		private var _font:Font;
		
		public function get loading():Boolean
		{
			return _loading;
		}
		
		public function get font():Font
		{
			return _font;
		}
		
		//http://kb.mozillazine.org/Network.http.pipelining.maxrequests http://en.wikipedia.org/wiki/HTTP_pipelining
		public function set maxRequests(value:uint):void
		{
			_maxRequests = Math.max(value, 1);
		}
		
		public function get maxRequests():uint
		{
			return _maxRequests;
		}
		
		static public function get defaultMaxRequests():uint
		{
			return _defaultMaxRequests;
		}
		
		static public function set defaultMaxRequests(value:uint):void
		{
			_defaultMaxRequests = Math.max(value, 1);
		}
		
		public function load():void
		{
			_font = null;
			
			close();
			
			//Prepare requests and loaders
			_requests = request.urlRequests.concat();
			
			if(_requests.length > 0)//start loading
			{
				_loading = true;
				loadRequests();
			}
			else
			{
				_loading = false;
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function loadRequests():void
		{
			var numRequests:uint = Math.min(Math.max(_maxRequests - _loaders.length, 0), _requests.length);
			if(numRequests == 0)
				return;
			var requests:Vector.<URLRequest> = _requests.splice(0, numRequests);
			for(var i:uint = _loaders.length, y:uint = 0, length:uint = (_loaders.length += numRequests); i < length; i++, y++)
			{
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE, load_eventHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR, load_eventHandler);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, load_eventHandler);
				_loaders[i] = loader;
				loader.load(requests[y]);
			}
		}

		private function load_eventHandler(event:Event):void
		{
			var loader:URLLoader = URLLoader(event.currentTarget);
			var index:uint = _loaders.indexOf(loader);
			loader.removeEventListener(Event.COMPLETE, load_eventHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, load_eventHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, load_eventHandler);
			
			if(!(event is ErrorEvent))
			{
				var fontData:IFontDataInput;
				var bytes:ByteArray = loader.data as ByteArray;
				var header:uint = bytes.readUnsignedInt();
				bytes.position = 0;
				//CWS FWS ZWS
				if(header >> 8 == 0x435753 || header >> 8 == 0x465753 || header >> 8 == 0x5A5753)
				{
					try
					{
						fontData = new SWFFontDataInput(bytes);
					}
					catch(error:Error)
					{
						
					}
				}
				//Detect others supported formats
				//if()
					//...
				else
					trace("Warning: Invalid font data.");
				
				if(fontData != null)
					_content.push(fontData);
			}

			_loaders.splice(index, 1);
			
			//Last font has been loaded
			if(_requests.length == 0 && _loaders.length == 0)
				registerFont();
			//Load next
			else
				loadRequests();
		}
		
		private function registerFont():void
		{
			if(_content.length == 0)
			{
				_loading = false;
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Content not found."));
			}
			else
			{
				_fontData = _content.length > 1 ? new FontDataInputUnion(_content) : _content[0];
				
				var fontManager:FontManager = FontManager.fontManager;
				fontManager.addEventListener(FontStatusEvent.FONT_STATUS, font_eventHandler);
				fontManager.addEventListener(FontErrorEvent.FONT_ERROR, font_eventHandler);
				fontManager.embedFont(_fontData);
			}
		}
		
		private function font_eventHandler(event:Event):void
		{
			if(event["data"] != _fontData)
				return;
			
			var fontManager:FontManager = FontManager.fontManager;
			fontManager.removeEventListener(FontStatusEvent.FONT_STATUS, font_eventHandler);
			fontManager.removeEventListener(FontErrorEvent.FONT_ERROR, font_eventHandler);
			
			_fontData = null;
			_content.length = 0;
			_loading = false;
			
			if(event is ErrorEvent)
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ErrorEvent(event).text));
			}
			else
			{
				_font = FontStatusEvent(event).font;
				dispatchEvent(new Event(Event.COMPLETE));
			}
			
		}

		public function close():void
		{
			var fontManager:FontManager = FontManager.fontManager;
			fontManager.removeEventListener(FontStatusEvent.FONT_STATUS, font_eventHandler);
			fontManager.removeEventListener(FontErrorEvent.FONT_ERROR, font_eventHandler);
			
			for each(var loader:URLLoader in _loaders)
			{
				loader.removeEventListener(Event.COMPLETE, load_eventHandler);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, load_eventHandler);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, load_eventHandler);
				try
				{
					loader.close();
				}
				catch (error:Error)
				{
					
				}
			}
			
			_fontData = null;
			_loaders.length = _requests.length = _content.length = 0;
			_loading = false;
		}
	}
}
