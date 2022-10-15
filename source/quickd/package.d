module quickd;
import std.format;
public import
quickd.core,
quickd.application,
quickd.graphics;


/// QuickD library version. Use to check the compatibility of the api
immutable Version quickDVersion = Version("-127.0.0-0");
string generateVersionString(string str) pure{
    string output;
    string[] buffer;

    import std.uni: toUpper;

    str = str.toUpper;

    foreach(character; str){
        assert(character <= 'Z' && character >= 'A' || character <= '9' && character >= '0' || character == '-'
        || character == '.',
        "version string can contain 'A'..'Z' || '0'..'9' || '-' && '.'. ");
        if(character <= 'Z' && character >= 'A'){
            buffer ~= consoleCharacters[character - 'A'];
        }else if(character <= '9' && character >= '0'){
            buffer ~= consoleCharacters[character - '0' + 26];
        }else if(character == '.'){
            buffer ~= consoleCharacters[$-1];
        }else if(character == '-'){
            buffer ~= consoleCharacters[$-2];
        }
    }
    foreach(l; 0..6){
        foreach(g, ref glyph; buffer){
            foreach(c, ref character; glyph){
                if(character == '\n'){
                    if(c < glyph.length)
                        glyph = glyph[c+1..$];
                    break;
                }
                output ~= character;
            }
        }
        output ~= '\n';
    }
    return output;
}
import std.array: split;
string[] versionString = generateVersionString("QUICKD").split('\n');
;///https://fsymbols.com/generators/tarty/


shared static this(){
    import std.conv: to;

    LogMessage message = LogMessage();
    message.message = "QuickD version " ~ quickDVersion.to!string ~ ".";

    string full;
    dstring[] ver = generateVersionString(quickDVersion.to!string).to!dstring.split('\n');
    dstring[] name = generateVersionString("QUICKD").to!dstring.split('\n');
    uint length = cast(uint) (ver[0].length > name[0].length? ver[0].length + 8: name[0].length + 8);
    import std.string: center;

    full ~= "".center(length, '░').to!string ~ '\n';

    foreach(ref nameS; name){
        full ~= nameS.center(length, '░').to!string ~ '\n';
    }
    full ~=
    "".center((ver[0].length < name[0].length? ver[0].length + 8: name[0].length + 8), '═').center(length,'░').to!string
    ~ '\n';
    full ~= "".center(length, '░').to!string ~ '\n';

    foreach(ref verS; ver){
        full ~= verS.center(length, '░').to!string ~ '\n';
    }


    message.console = full;
    globalLogger.log(message);
    message = LogMessage();

    if(quickDVersion.typeVersion == Version.Type.develop){
        message.message =   "This version of QuickD is the \"develop\" version. "~
                            "If you are not a QuickD developer, then use it only at your own risk :)";
        message.Version = quickDVersion;
        message.status = LogMessage.Status.warning;
        globalLogger.log(message);
    }
}
static private immutable(string[]) consoleCharacters = [
q"{░█████╗░
██╔══██╗
███████║
██╔══██║
██║░░██║
╚═╝░░╚═╝}",
q"{██████╗░
██╔══██╗
██████╦╝
██╔══██╗
██████╦╝
╚═════╝░}",
q"{░█████╗░
██╔══██╗
██║░░╚═╝
██║░░██╗
╚█████╔╝
░╚════╝░}",
q"{██████╗░
██╔══██╗
██║░░██║
██║░░██║
██████╔╝
╚═════╝░}",
q"{███████╗
██╔════╝
█████╗░░
██╔══╝░░
███████╗
╚══════╝}",
q"{███████╗
██╔════╝
█████╗░░
██╔══╝░░
██║░░░░░
╚═╝░░░░░}",
q"{░██████╗░
██╔════╝░
██║░░██╗░
██║░░╚██╗
╚██████╔╝
░╚═════╝░}",
q"{██╗░░██╗
██║░░██║
███████║
██╔══██║
██║░░██║
╚═╝░░╚═╝}",
q"{██╗
██║
██║
██║
██║
╚═╝}",
q"{░░░░░██╗
░░░░░██║
░░░░░██║
██╗░░██║
╚█████╔╝
░╚════╝░}",

q"{██╗░░██╗
██║░██╔╝
█████═╝░
██╔═██╗░
██║░╚██╗
╚═╝░░╚═╝}",
q"{██╗░░░░░
██║░░░░░
██║░░░░░
██║░░░░░
███████╗
╚══════╝}",
q"{███╗░░░███╗
████╗░████║
██╔████╔██║
██║╚██╔╝██║
██║░╚═╝░██║
╚═╝░░░░░╚═╝}",
q"{███╗░░██╗
████╗░██║
██╔██╗██║
██║╚████║
██║░╚███║
╚═╝░░╚══╝}",
q"{░█████╗░
██╔══██╗
██║░░██║
██║░░██║
╚█████╔╝
░╚════╝░}",
q"{██████╗░
██╔══██╗
██████╔╝
██╔═══╝░
██║░░░░░
╚═╝░░░░░}",
q"{░██████╗░
██╔═══██╗
██║██╗██║
╚██████╔╝
░╚═██╔═╝░
░░░╚═╝░░░}",
q"{██████╗░
██╔══██╗
██████╔╝
██╔══██╗
██║░░██║
╚═╝░░╚═╝}",
q"{░██████╗
██╔════╝
╚█████╗░
░╚═══██╗
██████╔╝
╚═════╝░}",
q"{████████╗
╚══██╔══╝
░░░██║░░░
░░░██║░░░
░░░██║░░░
░░░╚═╝░░░}",
q"{██╗░░░██╗
██║░░░██║
██║░░░██║
██║░░░██║
╚██████╔╝
░╚═════╝░}",
q"{██╗░░░██╗
██║░░░██║
╚██╗░██╔╝
░╚████╔╝░
░░╚██╔╝░░
░░░╚═╝░░░}",
q"{░██╗░░░░░░░██╗
░██║░░██╗░░██║
░╚██╗████╗██╔╝
░░████╔═████║░
░░╚██╔╝░╚██╔╝░
░░░╚═╝░░░╚═╝░░}",
q"{██╗░░██╗
╚██╗██╔╝
░╚███╔╝░
░██╔██╗░
██╔╝╚██╗
╚═╝░░╚═╝}",
q"{██╗░░░██╗
╚██╗░██╔╝
░╚████╔╝░
░░╚██╔╝░░
░░░██║░░░
░░░╚═╝░░░}",
q"{███████╗
╚════██║
░░███╔═╝
██╔══╝░░
███████╗
╚══════╝}",
q"{░█████╗░
██╔══██╗
██║░░██║
██║░░██║
╚█████╔╝
░╚════╝░}",
q"{░░███╗░░
░████║░░
██╔██║░░
╚═╝██║░░
███████╗
╚══════╝}",
q"{██████╗░
╚════██╗
░░███╔═╝
██╔══╝░░
███████╗
╚══════╝}",
q"{██████╗░
╚════██╗
░█████╔╝
░╚═══██╗
██████╔╝
╚═════╝░}",
q"{░░██╗██╗
░██╔╝██║
██╔╝░██║
███████║
╚════██║
░░░░░╚═╝}",
q"{███████╗
██╔════╝
██████╗░
╚════██╗
██████╔╝
╚═════╝░}",
q"{░█████╗░
██╔═══╝░
██████╗░
██╔══██╗
╚█████╔╝
░╚════╝░}",
q"{███████╗
╚════██║
░░░░██╔╝
░░░██╔╝░
░░██╔╝░░
░░╚═╝░░░}",
q"{░█████╗░
██╔══██╗
╚█████╔╝
██╔══██╗
╚█████╔╝
░╚════╝░}",
q"{░█████╗░
██╔══██╗
╚██████║
░╚═══██║
░█████╔╝
░╚════╝░}",
q"{░█████╗░
██╔══██╗
██║░░██║
██║░░██║
╚█████╔╝
░╚════╝░}",
q"{░░░░░░
░░░░░░
█████╗
╚════╝
░░░░░░
░░░░░░}",
q"{░░░
░░░
░░░
░░░
██╗
╚═╝}"
];
