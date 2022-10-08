module quickd.core.library;
/// Struct for declare library version.
struct Version{
    /// all versions from this api version are guaranteed to be backward compatible
    byte    apiVerison      = -1;
    /// all versions from the same api versions and middle versions are guaranteed to be compatible
    short   middleVersion   = 0;
    /// the version used to indicate critical bug fixes
    short   lowerVersion    = 0;
    /// small and synthetic corrections. Bulkheads to newer versions of dependent libraries, etc.
    short   buildVersion    = 0;
    /// branch type
    Type    typeVersion     = Type.develop;

    enum    Type{
        develop = 'd',
        alpha = 'a',
        beta = 'b',
        release = 'r'
    }

    /// Constructor with version string
    this(string ver){
        import std.conv: to;

        /// form - version write format
        const string form = "..-";
        /// elements - tmp array for contain version numbers
        int[4] elements;

        /// check form and elements size corrects (debug only)
        debug static assert(form.length + 1 == elements.length, "Form length size must only = elements count - 1");


        /// loop for parse version string
        foreach(id, ref el; elements){
            size_t i = 0;
            /// run, if need parse 2 last element (exemple: ...->32b<).
            if(id >= form.length){
                /// find version type.
                while(i < ver.length && ver[i] != 'd' && ver[i] != 'a' && ver[i] != 'b' && ver[i] != 'r') i++;
                /// if version type is not last in version string
                if(i + 1 < ver.length)
                    throw new Exception("Version type always last in version string!");

                /// if version type not found, set develop type, becouse unknown code quality level.
                if(i == ver.length || (ver[i] != 'd' && ver[i] != 'a' && ver[i] != 'b' && ver[i] != 'r'))
                    this.typeVersion = Type.develop;
                else
                    this.typeVersion = ver[i].to!Type, ver = ver[0..$-1];

                el = ver.to!int;
                ver = null;
            }
            /// standart loop, to parse 3 first versions (exemple: >5.43.65<-...).
            else {
                /// find form
                while(i < ver.length && ver[i] != form[id]) i++;
                if(i == ver.length || i+1 >= ver.length){
                    throw new Exception("Version string invalid(not full)!");
                }

                el = ver[0..i].to!int;
                ver = ver[i+1..$];
            }
        }
        /// Write version from array to fields.
        apiVerison      = cast(byte)elements[0];
        middleVersion   = cast(short)elements[1];
        lowerVersion    = cast(short)elements[2];
        buildVersion    = cast(byte)elements[3];
    }
    int opCmp(ref Version ver) @safe pure nothrow const
    {
        if(this.apiVerison != ver.apiVerison)
            return this.apiVerison < ver.apiVerison ? -1: 1;
        if(this.middleVersion != ver.middleVersion)
            return this.middleVersion < ver.middleVersion ? -1: 1;
        if(this.lowerVersion != ver.lowerVersion)
            return this.lowerVersion < ver.lowerVersion ? -1: 1;
        if(this.buildVersion != ver.buildVersion)
            return this.buildVersion < ver.buildVersion ? -1: 1;
        return 0;
    }
    bool opEquals(Version right) @safe pure nothrow const
    {
        return this.opCmp(right) == 0;
    }
    

    /// Version struct to string for output.
    string toString() @safe const pure nothrow
    {
        import std.conv;
        return text(
            this.apiVerison, ".",
            this.middleVersion, ".",
            this.lowerVersion, "-",
            this.buildVersion, this.typeVersion);
    }
}
/// Unittest Version
unittest{
    scope(success){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ Version.stringof ~ " — [");
        cwrite("✓".color(fg.green));
        write("]\n");
        stdout.flush();
    }
    scope(failure){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ Version.stringof ~ " — [");
        cwrite("✖".color(fg.red));
        write("]\n");
        stdout.flush();
    }

    Version version1 = Version("1.0.0-4");
    Version version2 = Version(version1.toString());

    if(version1 != version2){
        throw new Exception(
            "Version type is not correctly work!; — " ~
            version1.toString() ~ "!=" ~ version2.toString());
    }
}