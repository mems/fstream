import avmplus.System;
import avmplus.FileSystem;
import C.stdlib.*;

const USAGE:String = <![CDATA[usage: %cmd options file

This script generate SWF chunks of a font, by calling flex-fontkit.jar of Flex SDK.

Supported font file types are TrueType, OpenType, TrueType Collection and Datafork TrueType.

OPTIONS:
   -h	 	   Show this message
   -b	 	   Embeds the font’s bold face.
   -i	 	   Embeds the font’s italic face.
   -u          Ouput uncompressed SWF
   -a alias    Sets the font’s alias. The default is the font’s family name.
   -c length   Sets the number of chars in each SWF chunks. The default is 100.
   
Require RedTamarin %minversion, available here: http://code.google.com/p/redtamarin/
Require FLEX_HOME environment variable, defining location of Flex SDK folder.]]>;

const INVALID_FILE:uint = 2;
const ARG_ERROR:uint = 10;
const INVALID_API:uint = 20;
const MIN_VERSION:Array = [0, 3, 0];//0.3.0



function usage()
{
	trace(USAGE.replace("%cmd", System.programFilename).replace("%minversion", MIN_VERSION.join(".")));
}

/*
Check RedTamarin version
*/
var redTamarinVersion:Array = System.getRedtamarinVersion().split(".");
if(parseInt(redTamarinVersion[2]) < MIN_VERSION[2]
	&& parseInt(redTamarinVersion[1]) < MIN_VERSION[1]
	&& parseInt(redTamarinVersion[0]) < MIN_VERSION[0])
{
	trace("Require RedTamarin shell equal or greated than %minversion. Current version is %currentversion\n".replace("%minversion", MIN_VERSION.join(".")).replace("%currentversion", redTamarinVersion.join(".")));
	usage();
	System.exit(INVALID_API);
}
/*
Check FLEX_HOME env var
*/
if(getenv("FLEX_HOME") == "" || getenv("FLEX_HOME") == null)
{
	trace("Require environment variable FLEX_HOME. To define it, use this command:\n\tset FLEX_HOME=\"" + FileSystem.normalizePath("path/to/flex") + "\"\n");
	usage();
	System.exit(INVALID_API);
}
/*
TODO check if java and jar of fontSWF are available
*/

var javaCmd:String = "java -Dsun.io.useCanonCaches=false -Xms32m -Xmx512m"
var fontSWFJarCmd:String = " -jar \"%flexhome/lib/flex-fontkit.jar\" -3".replace("%flexhome", getenv("FLEX_HOME"));
var chunkLength:uint = 100;
var alias:String = null;
var bold:Boolean = false, italic:Boolean = false;
var file:String = null;

/*
Parse args
*/
var argv:Array = System.argv;//C argv[0] is not included (start at 0 without path of current exec)
var argc:uint = argv.length;
for(var i:uint = 0; i < argc; i++)
{
	var arg:String = argv[i];
	//Help
	if(arg == "-h" || arg == "-help" || arg == "--help" || arg == "-?")
	{
		usage();
		System.exit();
	}
	//Bold flag
	else if(arg == "-b" || arg == "-bold" || arg == "--bold")
	{
		bold = true;
	}
	//Italic flag
	else if(arg == "-i" || arg == "-italic" || arg == "--italic")
	{
		bold = true;
	}
	//Alias
	else if(arg == "-a" || arg == "-alias" || arg == "--alias")
	{
		if(i < argc - 1)
		{
			alias = argv[++i];
		}
		else
		{
			trace("%arg requires an argument\n".replace("%arg", arg));
			usage();
			System.exit(ARG_ERROR);
		}
	}
	//
	else if(arg == "-c" || arg == "-chunk" || arg == "--chunk")
	{
		if(i < argc - 1)
		{
			chunkLength = argv[++i];
		}
		else
		{
			trace("%arg requires an argument\n".replace("%arg", arg));
			usage();
			System.exit(ARG_ERROR);
		}
	}
	//Uncompressed flag
	/*
	http://opensource.adobe.com/svn/opensource/flex/sdk/trunk/modules/swfutils/src/java/flash/swf/MovieEncoder.java -> http://opensource.adobe.com/svn/opensource/flex/sdk/trunk/modules/swfutils/src/java/flash/swf/Header.java
	http://www.rgagnon.com/javadetails/java-0150.html
	*/
	else if(arg == "-u" || arg == "-uncompressed" || arg == "--uncompressed")
	{
		javaCmd += " -Dflex.swf.uncompressed=\"true\"";
	}
	//No more optional arguments, next is file
	else if(arg == "--")
	{
		if(i == argc - 2)
		{
			file = argv[++i];
		}
		else if(i >= argc - 1)
		{
			trace("file is required.\n");
			usage();
			System.exit(ARG_ERROR);
		}
		else
		{
			trace("Can't handle more than one file at the same time.\n");
			usage();
			System.exit(ARG_ERROR);
		}
	}
	//Other arguments
	else if(arg.charAt() == "-")
	{
		trace("Invalid option: $arg\n".replace("%arg", arg));
		usage();
		System.exit(ARG_ERROR);
	}
	//Assumed as file (only one)
	else
	{
		//Is last argument
		if(i == argc - 1)
		{
			file = argv[i];
		}
		else
		{
			trace("Can't handle more than one file at the same time.\n");
			usage();
			System.exit(ARG_ERROR);
		}
	}
}

/*
File argument not found or file not exist
*/
if(file == null || file == "" || !FileSystem.isRegularFile(file))
{
	trace("Invalid file.\n");
	usage();
	System.exit(INVALID_FILE);
}

/*
Alias is set
*/
if(alias != null && alias != "")
	fontSWFJarCmd += " -a " + alias;

/*
Bold
*/
if(bold)
	fontSWFJarCmd += " -b";

/*
Italic
*/
if(italic)
	fontSWFJarCmd += " -i";

var max:uint = 0xFFFF;
var i:uint = 0;
while(last < max)
{
	var first:uint = i++ * chunkLength;
	last = first + chunkLength - 1;
	var range:String = "U+" + ("000" + first.toString(16).toUpperCase()).substr(-4, 4) + "-U+" + ("000" + last.toString(16).toUpperCase()).substr(-4, 4);
	var cmd:String = javaCmd + fontSWFJarCmd + "-u \"%range\" -o \"%range\" \"%file\"".replace("%range", range).replace("%file", file);
	trace(System.popen(cmd));
}