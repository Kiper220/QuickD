module quickd.core.graphics.opengl.api;
import quickd.core.graphics;
import gfm.math.matrix;
import bindbc.opengl;

extern(C) @nogc nothrow ubyte* stbi_load(const(char) *filename, int *x, int *y, int *channels_in_file, int desired_channels);
extern(C) @nogc nothrow void stbi_image_free(void *retval_from_stbi_load);

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

        double k = cast(double)size.x / cast(double)size.y;
        this.projection = mat4!float.orthographic(-k,k,-1,1,-1,1);

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
    void removeLevel(){
        this.level = null;
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
    mat4!float projection;
}
class GLModel: Model{
    this(){
        glGenVertexArrays(1, &meshVAO);
        glGenBuffers(1, &meshVBO);
        glGenBuffers(1, &meshEBO);
        glGenBuffers(1, &meshUVBO);
    }
    void render(RenderAPI rapi, Actor actor){
        synchronized(this){
            import std.conv: to;
            GLShader shader = material.getShader().to!GLShader;

            Texture[string] textures = material.getTextures();

            glUseProgram(shader.getId());
            foreach(i, texture; textures.values){
                glActiveTexture(GL_TEXTURE0 + cast(uint)i);
                glBindTexture(GL_TEXTURE_2D, texture.to!GLTexture.getId());
            }
            mat4!float projection = (cast(GLRenderAPI)rapi).getProjection();
            glUniformMatrix4fv(shader.getProjectionLocation(), 1, GL_FALSE, cast(float*)&projection);

            glBindVertexArray(meshVAO);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshEBO);
            glDrawElements(GL_TRIANGLES, cast(int)mesh.indexBuffer.length, GL_UNSIGNED_INT, cast(void*)null);
            glBindVertexArray(0);
        }
    }
    ModelType getModelType(){
        return ModelType.staticModel;
    }
    void setMesh(Mesh mesh){
        this.mesh = mesh;
        synchronized(this){
            glBindVertexArray(meshVAO);

            glBindBuffer(GL_ARRAY_BUFFER, meshVBO);
            float[] data = (cast(float*)(mesh.vertexArray.ptr))[0..mesh.vertexArray.length*3];
            glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
            glEnableVertexAttribArray(0);


            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshEBO);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indexBuffer.length * uint.sizeof, mesh.indexBuffer.ptr, GL_STATIC_DRAW);

            glBindBuffer(GL_ARRAY_BUFFER, meshUVBO);
            data = (cast(float*)(mesh.uvArray.ptr))[0..mesh.uvArray.length*2];
            glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, null);
            glEnableVertexAttribArray(1);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindVertexArray(0);
        }
    }
    void setMaterial(Material material){
        synchronized(this){
            this.material = material;
        }
    }
private:
    Material material;
    Mesh mesh;

    uint meshVAO;
    uint meshVBO;
    uint meshEBO;
    uint meshUVBO;
}
class GLMaterial: Material{
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
    void setShader(Shader shader){
        synchronized(this){
            this.shader = shader;
        }
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
    Shader shader;
}

class GLTexture: Texture{
    this(){
        glGenTextures(1, &this.textureId);
        glBindTexture(GL_TEXTURE_2D, this.textureId);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

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
        }
        glBindTexture(GL_TEXTURE_2D, this.textureId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, 0);

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
    }
    bool loaded(){
        return this.isLoaded;
    }
    GLuint getId(){
        return this.textureId;
    }
    ~this(){
        glDeleteTextures(1, &this.textureId);
    }
private:
    GLuint textureId;
    bool isLoaded;
}

class GLShader: Shader{
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
        GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        const(char)* ptr = this.vertexSource.ptr;
        glShaderSource(vertexShader, 1, &ptr, null);
        glCompileShader(vertexShader);

        GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
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

            GLchar[512] infoLog;
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

            GLchar[512] infoLog;
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

    GLuint getId(){
        return this.programId;
    }
    GLuint getProjectionLocation(){
        return this.projectionLocation;
    }
    GLuint getViewLocation(){
        return this.viewLocation;
    }
    GLuint getModelLocation(){
        return this.modelLocation;
    }
    ~this(){
        glDeleteProgram(this.programId);
    }
private:
    GLuint programId;
    bool isCompiled;
    string vertexSource;
    string fragmentSource;
    GLint projectionLocation;
    GLint viewLocation;
    GLint modelLocation;
}
