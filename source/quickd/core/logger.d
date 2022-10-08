module quickd.core.logger;

import std.string;
import std.array;
import std.file;
import std.format;
import std.datetime;
import std.stdio;
import std.conv;
import std.traits;
import colorize;
import std.typecons;
import std.system;

static Logger globalLogger;
shared static this(){
    globalLogger = new Logger("globalLog");
}

class Logger{
    public:
    this(string loggerName = "None", bool forceLogs = false){
        if(loggerName.empty)
            this.loggerName = "None";
        else
            this.loggerName = loggerName;

        if(forceLogs && "./logs".exists){
            "./logs".rmdirRecurse;
        }

        timeLog = Clock.currTime;
        string time = "%s.%s.%s".format(timeLog.day, timeLog.month, timeLog.year);
        if(time.exists){
            time ~= "_%sh".format(timeLog.hour);
        }

        string directory = "./logs/" ~ time;

        try{
            bool created = false;
            foreach (directories; this.dirs)
            {
                if(directories == directory){
                    created = true;
                    break;
                }
            }
            if(!created){
                this.dirs ~= directory;
                if(directory.exists)
                    if(directory.isDir)
                        rmdirRecurse(directory);
                mkdirRecurse(directory);
            }
        }catch(Exception ex){}

        short counting = 0;

        string nlogName = this.loggerName;
        while((directory ~ "/" ~ nlogName ~ ".html").exists && (directory ~ "/" ~ nlogName ~ ".html").isFile){
            counting++;
            nlogName = this.loggerName ~ "#" ~ (counting+1).to!string;
        }

        if(counting == 0)
            logFile = File(directory ~ "/" ~ this.loggerName ~ ".html", "w");
        else
            logFile = File(directory ~ "/" ~ this.loggerName ~ "#" ~ (counting+1).to!string ~ ".html", "w");

        logFile.writeln(logHeader.format(time), logStyles);
        this.pos = logFile.size();

        LogMessage message;
        message.status = message.Status.trace;
        message.message = "Loggin start in " ~ time ~ '!';
        this.log(message);
    }
    void log(LogMessage message){

        string text_color;
        switch(message.status){
            case LogMessage.Status.fatal:
            text_color = "light_red";
            break;
            case LogMessage.Status.error:
            text_color = "red";
            break;
            case LogMessage.Status.warning:
            text_color = "yellow";
            break;
            case LogMessage.Status.trace:
            text_color = "blue";
            break;
            case LogMessage.Status.debugging:
            text_color = "magenta";
            break;
            default:
            text_color = "light_white";
        }
        auto time = Clock.currTime;
        auto strTime = "%s-%s-%s %s:%s:%s".format(time.year, time.month, time.day, time.hour, time.minute, time.second);
        cwritefln("[%s] %s: %s".color(text_color), strTime,
        message.status.to!string, message.message);

        string logNewText;
        {
            string logModuleText = "\"%s\" - line %u".format(message.moduleName, message.moduleLine);
            logNewText ~= q"{<p preffix="%s">%s</p>}".format("Log module", logModuleText);
            cwritefln("\t˪ %s: %s".color(text_color),"Log module", logModuleText);
        }
        foreach(key, value; message){
            logNewText ~= q"{<p preffix="%s">%s</p>}".format(key, value);
            cwritefln("\t˪ %s: %s".color(text_color), key, value);
        }
        logNewText = logBlock.format(message.status.to!string, message.message, logNewText);
        log_text = logNewText ~ log_text;

        logFile.seek(pos);
        logFile.write(log_text);
        stdout.flush;
    }
    ~this(){
        logFile.writeln(logFooter);
        logFile.close;
    }

    private:
    ulong               pos;
    string              log_text;

    static uint         noneLoggerCount;
    File                logFile;
    SysTime             timeLog;
    string              loggerName = "None";
    string              directory;
    static const string logBlock = import("web/logs/logBlock.html");
    static const string logHeader = import("web/logs/logHeader.html");
    static const string logFooter = import("web/logs/logFooter.html");
    static const string logStyles = import("web/logs/logStyle.html");
    static string[]     dirs;
}

struct LogMessage{
    enum Status
    {
        fatal,
        error,
        warning,
        trace,
        info,
        debugging,
    }
    static LogMessage opCall(string moduleName=__MODULE__,ulong moduleLine=__LINE__){
        LogMessage m;
        m.moduleNameString = moduleName;
        m.moduleLineLong = moduleLine;
        return m;
    }
    static LogMessage opCall(string message,string moduleName=__MODULE__,ulong moduleLine=__LINE__){
        LogMessage m;
        m.message = message;
        m.moduleNameString = moduleName;
        m.moduleLineLong = moduleLine;
        return m;
    }
    static LogMessage opCall(Tuple!(string, string[string]) data,string moduleName=__MODULE__,ulong moduleLine=__LINE__){
        LogMessage m;
        m.message = data[0];
        m.logData = data[1];
        m.moduleNameString = moduleName;
        m.moduleLineLong = moduleLine;
        return m;
    }
    ref auto opAssign(string op)(string value) @safe @property pure nothrow{
        this.message = value;
        return this;
    }
    ref auto opAssign(string op)(Tuple!(string, string[string]) value) @safe @property pure nothrow
    if(op == "="){
        this.message = value[0];
        this.logData = value[1];
        return this;
    }
    ref auto opAssign(string op)(string[string] value) @safe @property pure nothrow
    if(op == "="){
        this.logData = value;
        return this;
    }
    auto opIndexAssign(T)(T value, string index) @safe @property pure nothrow
    {
        try{
            static if(isNarrowString!T)
                this.logData[index] = value.to;
            else
                this.logData[index] = value.to!string;
        }
        catch(Exception ex){
            logData["Logger error:"] ~= ex.msg ~ " ";
        }
        return value;
    }
    ref auto opIndex(string index) @safe @property pure nothrow
    {
        if(index == "message")
            return this.messageTitle;
        return this.logData[index];
    }
    ref auto opOpAssign(string op, T)(Tuple!(string, T) value) @safe @property pure nothrow
    if(op == "~="){
        try{
            static if(isNarrowString!T)
                this.logData[value[0]] = value[1];
            else
                this.logData[value[0]] = value[1].to!string;
        }
        catch(Exception ex){
            logData["Logger error:"] ~= ex.msg ~ " ";
        }
        return this;
    }
    auto opOpAssign(string op, T)(T value, string index) @safe @property pure nothrow
    if(op == "~="){
        try{
            static if(isNarrowString!T)
                this.logData[index] ~= value;
            else
                this.logData[index] ~= value.to!string;
        }
        catch(Exception ex){
            logData["Logger error:"] ~= ex.msg ~ " ";
        }
        return this;
    }

    int opApply(scope int delegate(ref string key, ref string value) dg)
    {
        int result = 0;
        foreach (key, value; logData){
            result = dg(key, value);
            if(result)
                break;
        }

        return 1;
    }

    string message() const @safe @property pure nothrow
    {
        return this.messageTitle;
    }
    void message(T)(T value) @safe @property nothrow
    {
        try{
            this.messageTitle = value.to!string;
        }catch(Exception ex){
            this.messageTitle = "None";
        }
    }
    string moduleName() const @safe @property pure nothrow
    {
        return this.moduleNameString;
    }
    ulong moduleLine() const @safe @property pure nothrow
    {
        return this.moduleLineLong;
    }
    Status status() const @safe @property pure nothrow
    {
        return this.messageStatus;
    }
    void status(T)(T value) @safe @property nothrow
    {
        try{
            this.messageStatus = value.to!Status;
        }catch(Exception ex){
            this.messageStatus = Status.info;
        }
    }


    ref string opDispatch(string field)() @safe @property pure nothrow
    {
        string fieldStr = field.replace("_", " ").capitalize;
        return *logData[fieldStr];
    }
    void opDispatch(string field, T)(T value) @safe @property nothrow
    {
        try{
            string fieldStr = field.replace("_", " ").capitalize;
            static if(isNarrowString!T)
                logData[fieldStr] = value;
            else
                logData[fieldStr] = value.to!string;
        }catch(Exception ex){
            logData["Logger error:"] ~= ex.msg ~ " ";
        }
    }

    string toString() const @safe pure nothrow
    {
        try{
            return (tuple(messageTitle, logData)).to!string;
        }catch(Exception ex) {
            return "";
        }
    }

    private:
    string          messageTitle    = "None";
    string          moduleNameString;
    ulong           moduleLineLong;
    string[string]  logData;
    Status          messageStatus   = Status.info;
}