package fstream.test {

	import flash.text.TextFieldType;
	import flash.text.FontStyle;
	import fstream.system.FontSystem;
	import fstream.utils.SWFFontDataInput;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;

	/**
	 * @author Memmie Lenglet
	 */
	public class RegisterFontExample extends Sprite
	{
		private var _urls:Vector.<String>;
		private var _loaders:Vector.<URLLoader>;
		private var _dispatchers:Vector.<IEventDispatcher>;
		private var _textField:TextField;
		private var _currentLoader:uint;
		
		public function RegisterFontExample()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, stage_resizeHandler);
			
			_textField = new TextField();
			_textField.antiAliasType = AntiAliasType.ADVANCED;
			_textField.type = TextFieldType.INPUT;
			_textField.embedFonts = true;
			_textField.wordWrap = true;
			_textField.multiline = true;
			_textField.width = stage.stageWidth;
			_textField.height = stage.stageHeight;
			addChild(_textField);
			
			_urls = new <String>["assets/font_a-z.swf", "assets/Arial Unicode MS_regular.swf", "assets/ShinGo Pro Medium_regular.swf", "assets/font_maj_a-z.swf"];
			_loaders = new Vector.<URLLoader>(_urls.length);
			_dispatchers = new Vector.<IEventDispatcher>(_loaders.length);
			
			_currentLoader = 0;
			for(var i:uint = 0, length:uint = _loaders.length; i < length; i++)
			{
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE, loader_completeHandler);
				_loaders[i] = loader;
			}
			_loaders[_currentLoader].load(new URLRequest(_urls[_currentLoader]));
			
			
			/*
			var i:uint = 0;
			for each(var url:String in _urls)
			{
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE, loader_completeHandler);
				_loaders[i++] = loader;
				loader.load(new URLRequest(url));
			}
			*/
		}

		private function stage_resizeHandler(event:Event):void
		{
			_textField.width = stage.stageWidth;
			_textField.height = stage.stageHeight;
		}
		
		private function loader_completeHandler(event:Event):void
		{
			var loader:URLLoader = event.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			
			trace("SWF loaded: " + _urls[_loaders.indexOf(loader)]);
			enumerateFonts();
			
			var fontSystem:FontSystem = new FontSystem();
			fontSystem.addEventListener(Event.COMPLETE, fontSystem_completeHandler);
			_dispatchers[_loaders.indexOf(loader)] = fontSystem;
			fontSystem.registerFont(new SWFFontDataInput(loader.data));
			
			if(++_currentLoader < _loaders.length)
				_loaders[_currentLoader].load(new URLRequest(_urls[_currentLoader]));
		}
		/*
		private function loader_completeHandler(event:Event):void
		{
			var loader:URLLoader = event.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			
			trace("SWF loaded: " + _urls[_loaders.indexOf(loader)]);
			enumerateFonts();
			
			var dispatcher:IEventDispatcher = FontSystem.registerFont(new SWFFontDataInput(loader.data));
			_dispatchers[_loaders.indexOf(loader)] = dispatcher;
			dispatcher.addEventListener(Event.COMPLETE, fontSystem_completeHandler);
		}
		*/

		private function fontSystem_completeHandler(event:Event):void
		{
			IEventDispatcher(event.currentTarget).removeEventListener(Event.COMPLETE, fontSystem_completeHandler);
			
			enumerateFonts();
			
			var fonts:Array = Font.enumerateFonts(false);
			_textField.text = "";
			for each(var font:Font in fonts)
			{
				var pos:uint = _textField.length;
				var bold:Boolean = false;
				var italic:Boolean = false;
				switch(font.fontStyle)
				{
					case FontStyle.BOLD_ITALIC:
						bold = true;
						italic = true;
						break;
					case FontStyle.BOLD:
						bold = true;
						break;
					case FontStyle.ITALIC:
						italic = true;
						break;
				}
				_textField.appendText("abcdefghijklmnopqrstuvwxyz\nABCDEFGHIJKLMNOPQRSTUVWXYZ\n");
				_textField.setTextFormat(new TextFormat(font.fontName, 16, 0x000000, bold, italic), pos, _textField.length);
			}
		}
		
		private function enumerateFonts():void
		{
			var output:String = "enumerateFonts:";
			var fonts:Array = Font.enumerateFonts(false);
			for each(var font:Font in fonts)
				output += "\n\tfont class:" + getQualifiedClassName(font) + " super:" + getQualifiedSuperclassName(font) + " fontName:" + font.fontName + " fontStyle:" + font.fontStyle + " hasGlyphs(\"a\"):" + font.hasGlyphs("a") + " hasGlyphs(\"A\"):" + font.hasGlyphs("A");
			trace(output);
		}
	}
}
