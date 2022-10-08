module quickd.core.seralization.container;

/**
* TODO: Add support for multidimensional arrays and enums. Refine class support and standardize their reading/writing.
* Transfer memory management from GC to manual due to a special structure for the perfomance (only internal buffers)
*/
/**
* DataContainer - struct, what contain type data like bin object. All array don't contain like array and write in data
* with her size. Push places element to end of byte buffer. Pull takes away from end of byte buffer. First In, Last Out.
* DataContainer is always a copy of memory and does not change at the behest of external factors(exemple block).
*********
* Use DataContainer as a type converter, not the main storage - this is its main task. It is not recommended to write
* too little or quite a lot of information to the DataContainer, because usually the DataContainer is usually used as
* the minimum cell of the data warehouse and in this case a large number of small cells or a small number of them, but
* very heavy, can affect performance
**/
struct DataContainer{
    import std.traits: isBasicType;

    /// Init standart exceptions (debug only).
    debug static this(){
        this.invalidBuffer = new Exception(
            "A corrupted data buffer or a data buffer without debugging information.\n"~
            "The data buffer with and without debugging information is incompatible with each other.\n"~
            "- For \"debug\" build and \"release\" build need rebuild buffer of data!!!");
        this.typeListOver = new Exception("The list of arguments is over!");
        this.invalidType = new Exception("The order of arguments is broken");
    }

    /// Easy to use write interface
    void write(A...)(A args)
    if (args.length > 1){
        foreach(variable; args)
            this.write(variable);
    }
    /// Easy to use read interface
    void read(A...)(ref A args)
    if (args.length > 1){
        foreach(ref variable; args)
            this.read(variable);
    }
    /// Easy to use readn interface
    void readn(A...)(ref A args)
    if (args.length > 1){
        foreach(ref variable; args)
            static if(is(typeof(variable) == class))
                readn(variable);
            else
                read(variable);
    }

    /// Write variable with basic type to byte array (basic type)
    void write(T)(T data)
    if(isBasicType!T)
    {
        /// Places data to end buffer.
        ubyte* tmp = (cast(ubyte*)&data);
        buffer ~= tmp[0..T.sizeof];
        /// Add debug info to type list.(debug)
        debug this.typeList ~= T.stringof;
    }
    /// Write array with basic type to byte array (basic type)
    void write(T)(T[] data)
    if(isBasicType!T)
    {
        /// Get array size.
        size_t length = data.length;
        /// Prepare pointer for write.
        ubyte* tmp = (cast(ubyte*)data.ptr);

        buffer.length += length*data[0].sizeof + length.sizeof; // Resize buffer
        buffer[$-length*data[0].sizeof-length.sizeof..$-length.sizeof] = tmp[0..length*data[0].sizeof]; // Write
        buffer[$-length.sizeof..$] = (cast(ubyte*)&length)[0..length.sizeof]; // Write

        /// Add debug info to type list.(debug)
        debug this.typeList ~= T.stringof;
    }
    /// Write Struct/Class/Interface to byte array.
    void write(T)(T data)
    if(is(T == struct) || is(T == class) || is(T == interface))
    {
        data.save(this);
    }
    /// Write array of Struct/Class/Interface to byte array.
    void write(T)(T[] data)
    if(is(T == struct) || is(T == class) || is(T == interface))
    {
        auto size = data.length;
        foreach(ref el;data){
            el.save(this);
        }
        this.write(size);
    }

    /// Read variable from byte array to basic type variable
    void read(T)(ref T data)
    if(isBasicType!T)
    {
        /// Type check (debug only)
        debug{
            if(this.typeList.length == 0)
                throw typeListOver;
            if(this.typeList[$-1] != T.stringof)
                throw invalidType;
            this.typeList.length--;
        }
        /// Get variable pointer and write to data.
        T* tmp = (cast(T*)(this.buffer[$-T.sizeof..$].ptr));
        data = tmp[0];
        /// Resize buffer
        this.buffer.length = this.buffer.length - T.sizeof;
    }

    /// Read array from byte array to basic type array variable
    void read(T)(ref T[] data)
    if(isBasicType!T)
    {
        /// Type check (debug only)
        debug{
            assert(this.typeList.length != 0, "The list of arguments is over!");
            assert(this.typeList[$-1] == T.stringof, "The order of arguments is broken!");
            this.typeList = this.typeList[0..$-1];
        }
        /// Get array length
        size_t length = (cast(size_t*)(this.buffer[$-size_t.sizeof..$].ptr))[0];
        /// Calculate array bounds in buffer and write array to data.
        data = (cast(T*)(this.buffer[$-size_t.sizeof - T.sizeof*length..$-size_t.sizeof].ptr))[0..length].dup;
        /// Resize buffer
        this.buffer.length = this.buffer.length - size_t.sizeof - T.sizeof*length;
    }
    /// Read Struct/Class/Interface from byte array.
    void read(T)(T data)
    if(is(T == struct) || is(T == class) || is(T == interface))
    {
        data.load(this);
    }
    /// Read array Struct/Class/Interface from byte array.
    void read(T)(T[] data)
    if(is(T == struct) || is(T == class) || is(T == interface))
    {
        size_t length;
        this.read(length);

        assert(length == data.length, "Error. Array length not equal size of buffer array");

        foreach_reverse(ref el; data)
            el.load(this);
    }
    /// Read array Class with allocate array and class from byte array.
    void readn(T)(T[] data)
    if(is(T == class))
    {
        immutable(size_t) length = this.read();
        data.length = length;

        foreach_reverse(ref el; data){
            el = new T;
            el.load(this);
        }
    }
    /// Read array Struct with allocate array from byte array.
    void readn(T)(T[] data)
    if(is(T == struct))
    {
        immutable(size_t) length = this.read();
        data.length = length;

        foreach_reverse(ref el; data)
            el.load(this);
    }

    /// Load from fixate buffer.
    void setBuffer(immutable(ubyte)[] buffer){
        /// buffer length == 0 equel clear inner buffer.
        if(buffer.length == 0){
            this.buffer.length = 0;
            debug this.typeList.length = 0;
        }
        /// In debug mode
        debug{
            import std.conv: to;
            if(buffer.length < size_t.sizeof){
                throw invalidBuffer;
            }
            string dbg;
            size_t length;

            length = (cast(size_t*)(buffer[$-size_t.sizeof..$].ptr))[0];
            /// if buffer size lower size of debug info string.
            if(buffer.length < size_t.sizeof + length){
                throw invalidBuffer;
            }

            char* tmp = cast(char*)(buffer[$ - size_t.sizeof - length .. $-size_t.sizeof].ptr);
            dbg = tmp[0..length].dup;

            this.typeList = dbg.to!(string[]);
            buffer = buffer[0..$ - size_t.sizeof - length];
            /// if buffer of data length == 0, but typeList is'nt empty, need write warning.
            if(buffer.length == 0 && this.typeList.length != 0){
                import std.stdio: writeln;
                writeln(
                    "Warning: Container set buffer with typeList by ",
                    this.typeList.length, "elements, but length buffer of data is 0.");
            }
        }
        this.buffer = buffer.dup;
    }

    /// Return buffer data. Thread-unsafe!!! In debug mode return fixateBuffer and Thread-safe!!!!
    ubyte[] getBuffer(){
        debug return cast(ubyte[])fixateBuffer();
        else return this.buffer;
    }

    /// Fixate and return buffer. Recomend use for save buffer data.
    immutable(ubyte)[] fixateBuffer(){
        /// Write debug info
        debug
        {
            import std.conv: to;

            /// Write dbg info like string.
            string dbg = typeList.to!string;
            size_t length = dbg.length;

            /// Allocate fixate buffer.
            ubyte[] tmp = new ubyte[this.buffer.length + dbg.length + length.sizeof];

            /// Write data to fixate buffer
            tmp[0..this.buffer.length] = this.buffer;
            tmp[this.buffer.length..this.buffer.length+dbg.length] = cast(ubyte[])dbg;
            tmp[this.buffer.length+dbg.length..$] = (cast(ubyte*)&length)[0..length.sizeof];

            /// Return array. Since this array will not appear anywhere else, you can safely cast in immutable(ubyte)[]
            return cast(immutable(ubyte)[])tmp;
        }
        /// Release mode without debug info
        else{
            // Dupliucate buffer for fixate datas.
            immutable(ubyte)[] tmp = this.buffer.dup;
            return tmp;
        }
    }

private:
    /// Buffer
    ubyte[] buffer;
    /// Stanndart Exceptions (debug only).
    debug static Exception invalidBuffer;
    debug static Exception invalidType;
    debug static Exception typeListOver;
    /// Typelist (debug only).
    debug string[] typeList;
}

/// Unittest Version
unittest{
    scope(success){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ DataContainer.stringof ~ " — [");
        cwrite("✓".color(fg.green));
        write("]\n");
        stdout.flush();
    }
    scope(failure){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ DataContainer.stringof ~ " — [");
        cwrite("✖".color(fg.red));
        write("]\n");
        stdout.flush();
    }

    struct Test{
        this(int i) {
            this.i = i;
        }

        void save(ref DataContainer container){
            container.write(i);
        }
        void load(ref DataContainer container){
            container.read(i);
        }

        int i;
    }
    DataContainer container;
    immutable(ubyte)[] resource;
    {
        DataContainer tmp;
        string message = "Hello, World!\n";
        Test[5] test;
        foreach(i, ref el; test){
            el = Test(cast(int)i);
        }
        tmp.write(test, message);
        resource = tmp.fixateBuffer();
    }
    container.setBuffer(resource);

    Test[5] test2;
    string message;
    container.read(message, test2);

    foreach(i, ref el; test2)
        if(i != el.i)
            goto bad_work;

    if(message != "Hello, World!\n")
        goto bad_work;

    return;

    bad_work:
    throw new Exception("DataContainer type is not correctly work!;");
}
