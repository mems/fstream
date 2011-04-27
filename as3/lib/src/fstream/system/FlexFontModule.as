package fstream.system
{
	import mx.core.IFlexModuleFactory;
	import flash.text.Font;
	import flash.utils.Dictionary;
	
	/**
	* The FlexModuleFactory for use Font to IFontContextComponent
	* @author Memmie Lenglet
	* @see mx.core.IFontContextComponent
	* @see mx.core.IFlexModuleFactory
	*/
	public class FlexFontModule implements IFlexModuleFactory
	{
		private static var fonts:Dictionary = new Dictionary(true);
		private var _font:Font;
		
		public function FlexFontModule(font:Font):void
		{
			_font = font;
		}
		
		public static function getFontContext(arg:*):IFlexModuleFactory
		{
			var font:Font;
			if(arg is Font)
				font = arg as Font;
			else
				return null;
			
			if(fonts[font])
				return fonts[font];
			
			var instance:FlexFontModule = new FlexFontModule(font);
			fonts[font] = instance;
			return instance;
		}
		
		public function create(... parameters):Object
		{
			return _font;
		}
		
		public function info():Object
		{
			return {"fonts": Font.enumerateFonts(false)};
		}
		
		public function get preloadedRSLs():Dictionary
		{
			return new Dictionary();
		}
		
		public function allowInsecureDomain(... domains):void
		{
			
		}
		
		public function allowDomain(... domains):void
		{
			
		}
		
		public function callInContext(fn:Function, thisArg:Object, argArray:Array, returns:Boolean = true):*
		{
			return undefined;
		}
		
		public function getImplementation(interfaceName:String):Object
		{
			return null;
		}
		
		public function registerImplementation(interfaceName:String, impl:Object):void
		{
			
		}
	}
	
}