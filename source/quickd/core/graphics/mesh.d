module quickd.core.graphics.mesh;
import quickd.core.math.vector;


alias Triangle = Vector3!float[3];
alias TextureCoordinate = Vector2!float[3];

class Mesh{
    this(){}

    this(Triangle[] data){
        this.data = data;
    }
    this(Triangle data){
        this.data ~= data;
    }

    Triangle[] opAssign(Triangle[] data){
        this.data = data;
        return data;
    }
    Triangle[] opOpAssign(string op)(Triangle[] data){
        this.data ~= data;
        return this.data;
    }
    triangle[] opOpAssign(string op)(triangle value){
        this.data ~= value;
        return this.data;
    }
    ref Triangle opIndexAssign(Triangle value, size_t index){
        this.data[index] = value;
        return this.data[index];
    }

    Triangle[] opCast(){
        return this.data;
    }
    override string toString() {
        import std.conv: to;
        return this.data.to!string;
    }
private:
    Triangle[] data;
}