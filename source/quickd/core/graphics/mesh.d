module quickd.core.graphics.mesh;
public import gfm.math.vector;

struct Mesh {
    vec3!float[] vertexArray;
    vec2!float[] uvArray;
    uint[]          indexBuffer;
}
