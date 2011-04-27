package fstream.events {

	import fstream.utils.IFontDataInput;

	import flash.events.Event;
	import flash.text.Font;


	/**
	 * @author Memmie Lenglet
	 */
	public class FontStatusEvent extends Event {

		public static const FONT_STATUS:String = "fontStatus";
		private var _data:IFontDataInput;
		private var _font:Font;

		public function FontStatusEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, data:IFontDataInput = null, font:Font = null) {
			super(type, bubbles, cancelable);
			_font = font;
			_data = data;
		}

		public function get data():IFontDataInput
		{
			return _data;
		}

		public function get font():Font
		{
			return _font;
		}
	}
}
