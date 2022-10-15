module quickd.graphics.level;
import quickd.graphics.renderapi;

interface Level{
    void render(RenderAPI api);
}
interface Actor{
    void setRenderable();
    void render(RenderAPI);
    void setEnable(bool state);
}