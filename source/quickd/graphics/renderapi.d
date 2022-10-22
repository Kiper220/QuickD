module quickd.graphics.renderapi;
import quickd.application.window.nwindow;
import quickd.graphics.level2d;
import gfm.math.matrix;

enum ViewSettings{
    unitSizedView,
    proportionalView,
    windowSizedView,
}
enum ModelType{
    staticModel,
    dynamicModel
}

interface RenderAPI{
    void makeCurrentWindow(NativeWindow);
    void render(vec2!int size);
    void setLevel(Level level);
    void removeLevel();
    void setView(ViewSettings viewSetting);
    void clear();
    void finish();
    Text createText();
    Font createFont();
    Model createModel();
    Mesh createMesh();
    Material createMaterial();
    Texture createTexture();
    Shader createShader();
    mat4!float getProjection();
}

class Renderer{

    this(){

    }
    void setRenderApi(RenderAPI renderAPI){
        this.renderAPI = renderAPI;
    }
    void setWindow(NativeWindow window){
        this.window = window;
    }
    void setLevel(Level level){
        this.renderAPI.setLevel(level);
    }
    void render(){
        this.renderAPI.render(window.getSize());
        window.swap();
    }

private:
    NativeWindow window;
    RenderAPI renderAPI;
    mat4!float projection = mat4!float.identity();
}

import bindbc.opengl;
private static bool         isGLLoaded;
private static GLSupport    glVersion;

RenderAPI createOpenGLAPI(){
    if(!isGLLoaded){
        synchronized{
            if(!isGLLoaded){
                isGLLoaded = true;
                import quickd.core.logger: globalLogger, LogMessage;
                import std.conv: to;

                glVersion = loadOpenGL();
                assert(glVersion >= 20, "OpenGL version is lower that support: " ~ glVersion.to!string ~ " < 20");

                LogMessage message = LogMessage();

                message.message = "Loaded opengl";
                message.gl_version = glVersion.to!string;
                message.status = message.Status.trace;

                globalLogger.log(message);
            }
        }
    }
    import std.conv: to;
    assert(glVersion >= 20, "OpenGL version is lower that support: " ~ glVersion.to!string ~ " < 20");

    switch(glVersion){
        default:
        case GLSupport.gl20:{
            import quickd.graphics.opengl.gl20;
            return new OpenGL20API;
        }
    }

}
interface Renderable{
    void render(RenderAPI, Actor);                          /// Don't call this.
}
/// Combines material and texture. A new instance can only be obtained from RenderAPI.
interface Model: Renderable{
    ModelType getModelType();                               /// No implement.
    void setMesh(Mesh mesh);                                /// Set mesh.
    void setMaterial(Material material);                    /// Set material.
}
interface Mesh{
    void setVertexArray(vec3!float[] vertexArray);
    void setUVArray(vec2!float[] uvArray);
    void setIndexBuffer(uint[] indexBuffer);
}
/// Сombines shader and textures. A new instance can only be obtained from RenderAPI.
interface Material{
    void addTexture(string textureName, Texture texture);   /// Add texture by name.
    void renameTexture(string oldName, string newName);     /// Rename texture from oldName to newName.
    void setVector3Parametr(string name, vec3!float par);   /// Set vector parametr
    void removeVector3Parametr(string name);
    void setShader(Shader shader);                          /// Set shader.
    Shader getShader();                                     /// Get shader.
    Texture[string] getTextures();                          /// Get all textures.
    void removeTexture(string textureName);                 /// Remove texture by name.
}
/// Texture loader. A new instance can only be obtained from RenderAPI.
interface Texture{
    void loadTexture(string src);                           /// Load texture by name.
    void unloadTexture();                                   /// Unload texture.
    vec2!int getSize();
    void setTextureId(uint);
}
/// Shader compiler. A new instance can only be obtained from RenderAPI.
interface Shader{
    void setVertexShader(string vertexShader);              /// Set vertex shader source code.
    void setFragmentShader(string fragmentShader);          /// Set fragment shader source code.

    void compile();                                         /// Compile.
    bool hasSource();
    bool oldShader();                                       /// If compiled shader, but have new vertex/fragment shader.
    bool compiled();                                        /// If compiled shader.
}

interface Text: Renderable{
    void setFont(Font font);
    void setFontSize(uint size);
    void setText(dstring text);
    vec2!int getOffsetSize();
}
interface Font{
    void setFont(string dest);
    vec2!int getSize(uint id) const pure;
    Character getChar(uint id, dchar ch);
}
struct Character {
    vec2!int    position;  /// Glyph position(atlas).
    vec2!int    size;      /// Glyph size.
    vec2!int    bearing;   /// Offset of the upper left point of the glyph
    uint        advance;   /// Horizontal offset to the beginning of the next glyph
}