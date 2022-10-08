module quickd;
import std.format;
public import
quickd.core,
quickd.application;

/// QuickD library version. Use to check the compatibility of the api
immutable Version quickDVersion = Version("-128.0.0-0");

shared static this(){
    import std.conv: to;

    LogMessage message = LogMessage();
    message.message = "QuickD version " ~ quickDVersion.to!string ~ ".";
    globalLogger.log(message);

    if(quickDVersion.typeVersion == Version.Type.develop){
        message.message =   "This version of QuickD is the \"develop\" version. "~
                            "If you are not a QuickD developer, then use it only at your own risk :)";
        message.Version = quickDVersion;
        message.status = LogMessage.Status.warning;
        globalLogger.log(message);
    }
}