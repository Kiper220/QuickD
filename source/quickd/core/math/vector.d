module quickd.core.math.vector;

struct Vector(T, size_t S, string M = "") {
import std.traits: isFloatingPoint, isIntegral, isNumeric;
static assert(isNumeric!T, "Mathematical vector template can be only arithmetical type");
static assert(M.length < S + 1, "Match string can be only lower than axes");

    this(string m)(Vector!(T, S, m) vector){
        this.data = vector.data;
    }
    this(A, string m)(Vector!(A, S, m) vector)
    if(isNumeric!A){
        foreach(i, el; vector.data)
            this.data[i] = cast(T)el;
    }
    this(A)(A value)
    if(isNumeric!A){
        foreach(i, ref el; this.data)
            el = value;
    }

    this(A)(A[] data)
    if(isNumeric!A){
        assert(data.length == S, "Error array length.");

        foreach(i, el; data)
            this.data[i] = cast(T)el;
    }

    this(string str){
        import std.conv;

        if(str[0] != '(')
            throw new Exception("Error parsing!");
        str = str[1..$];

        foreach(i, ref el; this.data){
            while(str[0] == ' ') str = str[1 .. $];

            size_t j = 0;
            while(str[j] != ',' && str[j] != ')') j++;

            if(str[j] == ')' && this.data.length != i + 1)
                throw new Exception("Error parsing!");
            else
                el = str[0..j].to!T;

            str = str[j+1 .. $];
        }
        while(str.length != 0 && str[0] == ' ') str = str[1 .. $];
        if(str.length != 0)
            throw new Exception("Error parsing!");
    }

    this(T[] data){
        assert(data.length == S, "Error array length.");

        foreach(i, el; data)
            this.data[i] = el;
    }

    Vector opUnary(string op)()
    if(op == "-"){
        Vector vector;
        foreach(i, el; this.data)
            vector.data[i] = -el;
        return vector;
    }

    ref Vector opAssign(A)(A value)
    if(isNumeric!A){
        foreach(i, ref el; this.data)
            el = value;
        return this;
    }
    ref Vector opAssign(A, string m)(Vector!(A, S, m) vector)
    if(isNumeric!A){
        foreach(i, el; vector.data)
            this.data[i] = cast(T)el;
        return this;
    }
    ref Vector opAssign(A)(A[S] data)
    if(isNumeric!A){
        foreach(i, el; data)
            this.data[i] = cast(T)el;
        return this;
    }

    ref opOpAssign(string op, A, string m)(Vector!(A, S, m) vector)
    if(op == "+" && isNumeric!A)
    {
        foreach(i, ref el; this.data)
            el += cast(T) vector.data[i];
    }
    ref opOpAssign(string op, A, string m)(Vector!(A, S, m) vector)
    if(op == "-" && isNumeric!A)
    {
        foreach(i, ref el; this.data)
            el -= cast(T) vector.data[i];
    }

    ref Vector opIndexAssign(A)(A value, size_t el)
    if(isNumeric!A){
        this.data[el] = cast(T)value;
        return this;
    }

    Vector!(A, S, m) opCast(A, m)() const
    if(isNumeric!A){
        Vector!(A, S, m) vector;
        foreach(i, el; this.data)
            vector[i] = cast(A)el;

        return vector;
    }
    string toString() const{
        import std.conv: to;

        string str = "(";
        foreach(el; this.data[0 .. $ - 1])
            str ~= el.to!string ~ ", ";
        str ~= this.data[$-1].to!string ~ ")";

        return str;
    }

    bool opEquals(A, m)(Vector!(A, S, m) vector) const /// compares values
    if(isNumeric!A){
        foreach(i, el; this.data)
            if(el != vector.data[i])
                return false;

        return true;
    }
    int opCmp(A, m)(Vector!(A, S, m) vector) const
    if(isNumeric!A){
        const real th = this.mod;
        const real vc = vector.mod;
        if(th < vc) return -1;
        if(th > vc) return 1;
        return 0;
    }
    int opApply(int delegate(ref T) dg)
    { 
        foreach(ref value; this.data){
            if(dg(value)){
                break;
            }
        }
        return 0;
    } 
    

    real mod() const pure{
        import std.math: sqrt;

        real sum = 0;
        foreach(el; data)
            sum += el*el;
        return sqrt(sum);
    }
    void norm(){
        static if(isFloatingPoint!T){
            const real m = this.mod;
            if (m != 0)
                foreach (ref el; this.data)
                    el /= m;
        }else{
            static if(isFloatingPoint!T){
                const float m = cast(float)this.mod;
                if (m != 0)
                    foreach (ref el; this.data)
                        el /= m;
            }
        }
    }
    void opDispatch(string name)(T value)
    if(name.length == 1)
    {
        foreach(i,el; M){
            if(name[0] == el){
                this.data[i] = value;
                return;
            }
        }
        assert(false, name ~ " - unknown property.");
    }
    ref T opDispatch(string name)()
    if(name.length == 1)
    {
        foreach(i,el; M){
            if(name[0] == el)
                return this.data[i];
        }
        assert(false, name ~ " - unknown property.");
    }

    T[] opDispatch(string name)()
    if(name.length > 1){
        T[] arr = new T[name.length];
        foreach(i, ref arrEl; arr){
            bool set = false;
            foreach(j,el; M)
                if(name[i] == el)
                    arrEl = this.data[j], set = true;

            if(!set) assert(false, name[0] ~ " - unknown property.");
        }
        return arr;
    }



private:
    T[S] data;
}
alias Vector2(T) = Vector!(T, 2, "xy");
alias Vector3(T) = Vector!(T, 3, "xyz");
alias Vector4(T) = Vector!(T, 4, "xyzw");
alias RGB(T) = Vector!(T, 3, "rgb");
alias RGBA(T) = Vector!(T, 4, "rgba");