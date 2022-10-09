module quickd.core.graphics.mesh;
import quickd.core.math;

struct Mesh {
    Vector3!float[] vertexArray;
    Vector2!float[] uvArray;
    uint[]          indexBuffer;
}
