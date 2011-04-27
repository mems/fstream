package fstream.utils {

	import flash.display.BitmapData;
	/**
	 * Compare two objects
	 * @author Memmie Lenglet
	 */
	//TODO add a thrid parameter (a flag) to check :
	//- typeof (xml, number, string, object, function, boolean)
	//- qualified class name (strict mode)
	//- AMF signature
	//- Nested objects
	public function isEqual(value1:*, value2:*, flags:uint = 0):Boolean
	{
		//strict equality
		if(value1 === value2)
			return true;
		/*	
		if(getQualifiedClassName(value1) != getQualifiedClassName(value2))
			return false;
		*/
		
		//special case of Numbers and NaN != NaN
		if(value1 is Number && value2 is Number)
			return isNaN(value1) && isNaN(value2) ? true : value1 == value2;
		//standard compare method (with transtyping) for native types (without "object")
		if(
			(typeof value1 == typeof value2) && ["xml", "number", "string", "boolean", "function"].indexOf(typeof value1) >= 0
			//|| value1 is Function && value2 is Function
			|| value1 is Class && value2 is Class
			|| value1 is Namespace && value2 is Namespace
		)
			return value1 == value2;
		//special case of bitmapdata
		if(value1 is BitmapData && value2 is BitmapData)
			return isEqual$bitmap(BitmapData(value1), BitmapData(value2));
		//special case of DisplayObjectContainer, display list tree
		/*
		if(value1 is DisplayObjectContainer && value2 is DisplayObjectContainer)
			return isEqual$displayObjectContainer(DisplayObjectContainer(value1), DisplayObjectContainer(value2));
		*/
		
		return isEqual$object(Object(value1), Object(value2));
	}
}

import flash.display.BitmapData;
import flash.display.DisplayObjectContainer;
import flash.utils.Dictionary;
import fstream.utils.isEqual;


/*
internal function isEqual$bytes(value1:ByteArray, value2:ByteArray):Boolean
{
	var length:uint = value1.length;
	if(length != value2.length)
		return false;
	
	var i:uint = 0;
	while(i < length && value1[i] == value2[i++]);
	return i == length;
}
*/

internal function isEqual$bitmap(value1:BitmapData, value2:BitmapData):Boolean
{
	var result:Object = value1.compare(value2);
	return result is Number && result == 0;
}

internal function isEqual$displayObjectContainer(value1:DisplayObjectContainer, value2:DisplayObjectContainer):Boolean
{
	return false;
}

internal function isEqual$object(value1:Object, value2:Object):Boolean
{
	var key:Object, value:Boolean = true;
	var keys1:Dictionary = new Dictionary(true);
	var keys2:Dictionary = new Dictionary(true);
	var diff:int = 0;
	for(key in value1)
	{
		diff++;
		keys1[key];
	}
	for(key in value2)
	{
		diff--;
		keys2[key];
	}
	
	if(diff != 0)
		return false;
		
	for(key in keys1)
	{
		if(key in keys2 && isEqual(keys1[key], keys2[key]))
			continue;
		else
			return false;
	}
	
	return true;
}