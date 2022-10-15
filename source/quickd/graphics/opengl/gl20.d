module quickd.graphics.opengl.gl20;
import quickd.graphics.opengl.api;
import bindbc.opengl.bind.gl20;

import quickd.graphics.renderapi;
import quickd.application.window.nwindow;
import gfm.math.vector;
import quickd.graphics.level2d;
import quickd.graphics.renderapi;

extern(C) @nogc nothrow ubyte* stbi_load(const(char) *filename, int *x, int *y, int *channels_in_file, int desired_channels);
extern(C) @nogc nothrow void stbi_image_free(void *retval_from_stbi_load);

class OpenGL20API: OpenGLAPI{
    void makeCurrentWindow(NativeWindow){
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
                        [1f,0f,0f,0f],
                        [0f,1f,0f,0f],
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
        return new GL20Text;
    }
    Font createFont(){
        return new GL20Font;
    }
    Model createModel(){
        return new GL20Model;
    }
    Mesh createMesh(){
        return new GL20Mesh;
    }
    Material createMaterial(){
        return new GL20Material;
    }
    Shader createShader(){
        return new GL20Shader;
    }
    Texture createTexture(){
        return new GL20Texture;
    }
    mat4!float getProjection(){
        return this.projection;
    }
private:
    NativeWindow    window;
    Level           level;

    mat4!float      projection;

    ViewSettings    viewSetting = ViewSettings.windowSizedView;
}
/// Combines material and texture. A new instance can only be obtained from RenderAPI.
class GL20Model: GLModel{
    void render(RenderAPI rapi, Actor actor){

    }
    ModelType getModelType(){
        return ModelType.staticModel;
    }
    void setMesh(Mesh mesh){
        this.mesh = mesh;
    }
    void setMaterial(Material material){
        this.material = material;
    }
private:

    Mesh            mesh;
    Material        material;

}
class GL20Mesh: GLMesh{

}
/// Сombines shader and textures. A new instance can only be obtained from RenderAPI.
class GL20Material: GLMaterial{
    void setShader(Shader shader){
        synchronized(this){
            this.shader = shader;
        }
    }
    void addTexture(string textureName, Texture texture){
        synchronized(this){
            if((textureName in this.textures) !is null)
                throw new Exception("Texture by \"" ~ textureName ~ "\" allready exist.");
            this.textures.require(textureName, texture);
        }
    }
    void renameTexture(string oldName, string newName){
        synchronized(this){
            if((newName in this.textures) !is null)
                throw new Exception("Texture by \"" ~ newName ~ "\" allready exist.");

            auto old = oldName in this.textures;

            if(old is null)
                throw new Exception("Texture by \"" ~ newName ~ "\" is't exist.");

            this.textures[newName] = *old;
            this.textures.remove(oldName);
        }
    }
    void setVector3Parametr(string name, vec3!float par){
        vec3Param[name] = par;
    }
    void removeVector3Parametr(string name){
        vec3Param.remove(name);
    }
    vec3!float[string] getVector3Paramtrs(){
        return this.vec3Param;
    }
    void removeTexture(string textureName){
        this.textures.remove(textureName);
    }
    Shader getShader(){
        return this.shader;
    }
    Texture[string] getTextures(){
        return this.textures;
    }

private:
    Texture[string] textures;
    vec3!float[string] vec3Param;
    Shader shader;
}
/// Texture loader. A new instance can only be obtained from RenderAPI.
class GL20Texture: GLTexture{
    this(){
        glGenTextures(1, &this.textureId);
        glBindTexture(GL_TEXTURE_2D, this.textureId);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    void loadTexture(string src){
        int width, height, nrChannels;
        const ubyte *data = stbi_load(src.ptr, &width, &height, &nrChannels, 4);

        if(!data){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            message.message = "Cannot load image.";
            message.image = src;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);
            throw new Exception("Cannot load image: " ~ src ~ ";");
        }
        glBindTexture(GL_TEXTURE_2D, this.textureId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glBindTexture(GL_TEXTURE_2D, 0);

        this.size = [width, height];
        stbi_image_free(cast(void*)data);
    }
    void unloadTexture(){
        glDeleteTextures(1, &this.textureId);
        glGenTextures(1, &this.textureId);
        glBindTexture(GL_TEXTURE_2D, this.textureId);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glBindTexture(GL_TEXTURE_2D, 0);
        this.size = [0, 0];
    }
    void setTextureId(uint id){
        glDeleteTextures(1, &this.textureId);
        this.textureId = id;
    }
    bool loaded(){
        return this.isLoaded;
    }
    uint getId(){
        return this.textureId;
    }
    vec2!int getSize(){
        return this.size;
    }
    ~this(){
        glDeleteTextures(1, &this.textureId);
    }
private:
    uint textureId;
    vec2!int size;
    bool isLoaded;
}
/// Shader compiler. A new instance can only be obtained from RenderAPI.
class GL20Shader: GLShader{
    this(){
        this.programId = glCreateProgram();
    }
    void setVertexShader(string vertexShader){
        this.vertexSource = vertexShader;
    }
    void setFragmentShader(string fragmentShader){
        this.fragmentSource = fragmentShader;
    }

    void compile(){
        uint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        const(char)* ptr = this.vertexSource.ptr;
        glShaderSource(vertexShader, 1, &ptr, null);
        glCompileShader(vertexShader);

        uint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        ptr = this.fragmentSource.ptr;
        glShaderSource(fragmentShader, 1, &ptr, null);
        glCompileShader(fragmentShader);

        int vsSuccess;
        int fsSuccess;

        glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &vsSuccess);
        glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &fsSuccess);

        if(!vsSuccess){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            char[512] infoLog;
            glGetShaderInfoLog(vertexShader, 512, null, infoLog.ptr);
            size_t i = 0;
            while(i < 512 && infoLog[i] != '\0') i++;

            message.message = "Vertex shader compile error.";
            message.compile_message = infoLog[0..i].idup;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);
        }
        if(!fsSuccess){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            char[512] infoLog;
            glGetShaderInfoLog(fragmentShader, 512, null, infoLog.ptr);
            size_t i = 0;
            while(i < 512 && infoLog[i] != '\0') i++;

            message.message = "Fragment shader compile error.";
            message.compile_message = infoLog[0..i].idup;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);
        }
        if(!vsSuccess || !fsSuccess){
            throw new Exception("Shader program compile error.");
        }

        glAttachShader(this.programId, vertexShader);
        glAttachShader(this.programId, fragmentShader);
        glLinkProgram(this.programId);                        /// TODO: Add check link error.

        this.projectionLocation = glGetUniformLocation(this.programId, "projection");
        this.modelLocation = glGetUniformLocation(this.programId, "model");
        this.viewLocation = glGetUniformLocation(this.programId, "view");

        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);

        this.vertexSource = null;
        this.fragmentSource = null;
        this.isCompiled = true;
    }
    bool hasSource(){
        return vertexSource.ptr != null || fragmentSource.ptr != null;
    }
    bool oldShader(){
        return !isCompiled || vertexSource.ptr != null || fragmentSource.ptr != null;
    }
    bool compiled(){
        return isCompiled;
    }

    uint getId(){
        return this.programId;
    }
    uint getProjectionLocation(){
        return this.projectionLocation;
    }
    uint getViewLocation(){
        return this.viewLocation;
    }
    uint getModelLocation(){
        return this.modelLocation;
    }
    ~this(){
        glDeleteProgram(this.programId);
    }
private:
    uint programId;
    bool isCompiled;
    string vertexSource;
    string fragmentSource;
    uint projectionLocation;
    uint viewLocation;
    uint modelLocation;
}

class GL20Text: GLText{
    void render(RenderAPI rapi, Actor actor){

    }
    void setFont(Font font){

    }
    void setText(dstring text){

    }
}
class GL20Font: GLFont{
    void setFont(string dest){

    }
    void setFontSize(ushort size){

    }
    Character loadChar(dchar ch){
        return Character();
    }
    void loadChars(dstring str){

    }
}