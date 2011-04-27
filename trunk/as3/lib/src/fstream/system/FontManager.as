package fstream.system {

	import fstream.events.FontErrorEvent;
	import fstream.events.FontStatusEvent;
	import fstream.utils.IFontDataInput;

	import flash.display.Bitmap;
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.text.FontStyle;

	
	/**
	 * 
	 * @author Memmie Lenglet
	 */
	public final class FontManager extends EventDispatcher
	{	
		private var _fontEmbeds:Vector.<FontEmbed> = new Vector.<FontEmbed>();
		
		//Listen exit frame events for waiting all embedFont calls (wait the last moment to update) in current execution frame
		//@see http://blog.joa-ebert.com/2010/10/03/opening-the-blackbox/
		//@see http://www.craftymind.com/2008/04/18/updated-elastic-racetrack-for-flash-9-and-avm2/
		private const HEARTBEAT:EventDispatcher = new Bitmap();
		
		private static var _instance:FontManager;
		private static var _instanceAllowed:Boolean = false;
		
		
		public function FontManager()
		{
			if(!_instanceAllowed)
				Error.throwError(IllegalOperationError, 2012, "FontManager");//2012: %1 class cannot be instantiated.
		}
		
		static public function get fontManager():FontManager
		{
			_instanceAllowed = true;
			_instance = new FontManager();
			_instanceAllowed = false;
			return _instance;
		}
		
		/**
		 * Runtime load the specified font
		 * @see http://www.adobe.com/content/dam/Adobe/en/devnet/swf/pdf/swf_file_format_spec_v10.pdf#nameddest=G5.88507 SWF Structure Summary - The dictionary
		 * Note: If same font with same style (normal, italic, bold or bold-italic) already exist, it will be overrite and all glyphs will be remplaced.
		 */
		public function embedFont(data:IFontDataInput):void
		{
			if(data == null)
				Error.throwError(ArgumentError, 2007, "data");
			
			var fontName:String = data.fontName;
			var bold:Boolean = data.bold;
			var italic:Boolean = data.italic;
			var fontStyle:String = bold && italic ? FontStyle.BOLD_ITALIC : bold ? FontStyle.BOLD : italic ? FontStyle.ITALIC : FontStyle.REGULAR;
			
			var currentFontEmbed:FontEmbed;
			//Search if in current frame an other font waiting for generation
			for each(var fontEmbed:FontEmbed in _fontEmbeds)
			{
				if(!fontEmbed.embedding && fontEmbed.fontName == fontName && fontEmbed.fontStyle == fontStyle)
				{
					currentFontEmbed = fontEmbed;
					break;
				}
			}
			
			//Else not, search if in a previous frame or outside fontsystem a runtime font match
			if(currentFontEmbed == null)
			{
				currentFontEmbed = new FontEmbed();
				currentFontEmbed.fontName = fontName;
				currentFontEmbed.fontStyle = fontStyle;
				currentFontEmbed.addEventListener(Event.COMPLETE, eventHandler);
				currentFontEmbed.addEventListener(ErrorEvent.ERROR, eventHandler);
				_fontEmbeds.push(currentFontEmbed);
			}
			
			//Update FontInfo properties
			currentFontEmbed.fontData.push(data);
			
			//Wait until exit frame in case of other fonts need to be registered
			HEARTBEAT.addEventListener(Event.EXIT_FRAME, heartbeat_exitFrameHandler, false, 0, true);
		}

		private function eventHandler(event:Event):void
		{
			var fontEmbed:FontEmbed = event.currentTarget as FontEmbed;
			fontEmbed.removeEventListener(Event.COMPLETE, eventHandler);
			fontEmbed.removeEventListener(ErrorEvent.ERROR, eventHandler);
			
			//Remove from global list
			_fontEmbeds.splice(_fontEmbeds.indexOf(fontEmbed), 1);
			
			var fontData:IFontDataInput;
			if(event is ErrorEvent)
				for each(fontData in fontEmbed.fontData)
					dispatchEvent(new FontErrorEvent(FontErrorEvent.FONT_ERROR, false, false, ErrorEvent(event).text, fontData));
			else
				for each(fontData in fontEmbed.fontData)
					dispatchEvent(new FontStatusEvent(FontStatusEvent.FONT_STATUS, false, false, fontData, fontEmbed.font));
		}

		/**
		 * 
		 */
		private function heartbeat_exitFrameHandler(event:Event):void
		{
			HEARTBEAT.removeEventListener(Event.EXIT_FRAME, heartbeat_exitFrameHandler);
			
			//NOTICE: unexpected effect can occure if embed dispatch a synchrone event
			for each(var fontEmbed:FontEmbed in _fontEmbeds)
				if(!fontEmbed.embedding)
					fontEmbed.embed();
		}
	}
}


