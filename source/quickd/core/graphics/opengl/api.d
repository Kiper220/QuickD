module quickd.core.graphics.opengl.api;
import quickd.core.graphics.opengl.model;
import quickd.core.graphics.opengl.text;
import quickd.core.graphics;
import gfm.math.matrix;
import bindbc.opengl;

static void initOpenGL(){
    /// Load OpenGL and check version
    import bindbc.opengl: loadOpenGL, GLSupport;
    import std.conv: to;
    static bool inited;
    if(!inited){
        synchronized{
            if(!inited){
                const auto glVersion = loadOpenGL();
                assert(glVersion >= GLSupport.gl33, "This version OpenGL not supported: " ~ glVersion.to!string);
                inited = true;
                glEnable(GL_DEPTH_TEST);
                glDepthFunc(GL_LESS);
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1);      // TODO: Fix font.
            }
        }
    }
}



class GLRenderAPI: RenderAPI{
    this(){
        initOpenGL();
    }
    void makeCurrentWindow(NativeWindow window){
        import bindbc.sdl;
        SDL_GL_MakeCurrent(cast(SDL_Window*)window.getLowLevelWindow(), window.getLowLevelContext());
    }
    void render(vec2!int size){
        import bindbc.opengl;

        switch(this.viewSetting){
            default:
            case ViewSettings.unitSizedView:
            {
                this.projection = mat4!float.orthographic(-1,1,-1,1,-1,1);
            }
            break;
            case ViewSettings.proportionalView:
            {
                if(size.x > size.y){
                    double k = cast(double)size.y / cast(double)size.x;
                    this.projection = mat4!float.orthographic(-1,1,-k,k,-1,1);
                }else{
                    double k = cast(double)size.x / cast(double)size.y;
                    this.projection = mat4!float.orthographic(-k,k,-1,1,-1,1);
                }
            }
            break;
            case ViewSettings.windowSizedView:
            {
                this.projection = mat4!float([
                    [1,0,0f,0],
                    [0,1,0f,0],
                    [0,0,1,0f],
                    [(cast(float)-size.x)/4f,cast(float)size.y/4f-1,0,1f]
                ])*mat4!float.orthographic
                    (cast(float)-size.x/4f,cast(float)size.x/4f,cast(float)-size.y/4f,cast(float)size.y/4f,-1,1);
            }
            break;
        }
        glClearColor(0,0,0,0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        if(level !is null){
            level.render(this);
        }
        glFinish();
    }
    void setLevel(Level level){
        this.level = level;
    }
    void setView(ViewSettings viewSetting){
        this.viewSetting = viewSetting;
    }
    void removeLevel(){
        this.level = null;
    }
    Text createText(){
        return new GLText;
    }
    Font createFont(){
        return new GLFont;
    }
    Model createModel(){
        return new GLModel;
    }
    Material createMaterial(){
        return new GLMaterial;
    }
    Texture createTexture(){
        return new GLTexture;
    }
    Shader createShader(){
        return new GLShader;
    }
    mat4!float getProjection(){
        return this.projection;
    }
private:
    Level level;
    ViewSettings viewSetting;
    mat4!float projection;
}
