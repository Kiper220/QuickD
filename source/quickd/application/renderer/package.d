module quickd.application.renderer;
public import
quickd.core.graphics.renderapi;
import quickd.core.graphics;
import quickd.application.renderer.opengl;
import quickd.application.window.nwindow;


class Renderer{
public:
    this(NativeWindow window){
        api = new OpenGL;
        this.window = window;
    }
    void makeCurrent(){
        api.makeCurrentWindow(window);
    }
    void clear(){
        api.clear();
    }
    void finish(){
        api.finish();
    }
    void draw(){
        api.draw();
    }
    Model createModel(){
        return api.createModel();
    }
    Texture createTexture(){
        return api.createTexture();
    }
    Shader createVertexShader(){
        return api.createVertexShader();
    }
    Shader createFragmentShader(){
        return api.createFragmentShader();
    }
    ShaderProgram createShaderProgram(){
        return api.createShaderProgram();
    }



private:
    NativeWindow window;
    RenderAPI api;
}