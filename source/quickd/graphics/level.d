module quickd.graphics.level;

interface Level{
    void render();
}
interface Actor{
    void setRenderable();
    void render();
    void setEnable(bool state);
}