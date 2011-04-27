package fstream.events
{

	import fstream.utils.IFontDataInput;
	import flash.events.ErrorEvent;


	/**
	 * @author Memmie Lenglet
	 */
	public class FontErrorEvent extends ErrorEvent
	{
		public static const FONT_ERROR:String = "fontError";
		private var _data:IFontDataInput;

		public function FontErrorEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, text:String = "", data:IFontDataInput = null)
		{
			super(type, bubbles, cancelable, text);
			_data = data;
		}

		public function get data():IFontDataInput
		{
			return _data;
		}
	}
}
