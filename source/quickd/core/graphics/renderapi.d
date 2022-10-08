module quickd.core.graphics.renderapi;
public import quickd.application.window.nwindow;
import quickd.core.graphics;
import quickd.core.math;

interface RenderAPI{
    void makeCurrentWindow(NativeWindow);
    void clear();
    void finish();
    void draw();
    Model createModel();
    Texture createTexture();
    Shader createVertexShader();
    Shader createFragmentShader();
    ShaderProgram createShaderProgram();
}
interface Shader{
    void setShader(string shader);
    void buildShader();
}
interface ShaderProgram{
    void bindVertexShader(Shader shader);
    void bindFragmentShader(Shader shader);
    void link();
}
interface Model{
    void setShaderProgram(ShaderProgram);
    void setMesh(Mesh mesh);
    void setTextCord(TextureCoordinate[] cords);
    void setTexture(string name, Texture texture);
    void render();
}
interface Texture{
    void loadTexture(string dest);
    void setTexture(inout(ubyte[]) buffer);
    void setRawtexture(inout(ubyte[]) buffer);
    void setRawtexture(ubyte[] buffer);
}