module quickd.core.graphics.renderer;
public import quickd.core.graphics.renderapi;
import quickd.core.graphics.opengl.api;
import quickd.application.window.nwindow;


class Renderer{
    public:
    this(NativeWindow window){
        api = new GLRenderAPI;
        this.window = window;
    }
    void makeCurrent(){
        api.makeCurrentWindow(window);
    }
    void render(){
        api.render(this.window.getSize);
    }
    void setLevel(Level level){
        this.api.setLevel(level);
    }
    void setView(ViewSettings viewSetting){
        this.api.setView(viewSetting);
    }
    void removeLevel(){
        this.api.removeLevel();
    }
    Text createText(){
        return api.createText();
    }
    Font createFont(){
        return api.createFont();
    }
    Model createModel(){
        return api.createModel();
    }
    Material createMaterial(){
        return api.createMaterial();
    }
    Texture createTexture(){
        return api.createTexture();
    }
    Shader createShader(){
        return api.createShader();
    }
    RenderAPI getRenderAPI(){
        return this.api;
    }

    private:
    NativeWindow window;
    RenderAPI api;
}