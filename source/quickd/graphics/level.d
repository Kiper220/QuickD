module quickd.graphics.level;
import quickd.graphics.renderapi;
import gfm.math.matrix;

interface Level{
    void render(RenderAPI api);
}
interface Actor{
    void        setRenderable(Renderable renderable);
    void        render(RenderAPI);
    mat4!float  getModelMatrix();
    void        setEnable(bool state);
}