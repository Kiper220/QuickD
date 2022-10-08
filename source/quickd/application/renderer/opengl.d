module quickd.application.renderer.opengl;
import quickd.core.graphics.renderapi;
import quickd.core.graphics;
import quickd.core.math;
import bindbc.sdl;
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
                assert(glVersion >= GLSupport.gl41, "This version OpenGL not supported: " ~ glVersion.to!string);
                inited = true;
            }
        }
    }
}

class OpenGL: RenderAPI {
public:
    this(){
        initOpenGL();
    }

    void makeCurrentWindow(NativeWindow window){
        SDL_GL_MakeCurrent(cast(SDL_Window*)window.getLowLevelWindow(), window.getLowLevelContext());
    }
    void clear(){
        glClearColor(0,0,0,0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    void finish() {
        glFinish();
    }
    void draw(){}

    Model createModel(){
        return new GLModel;
    }
    Texture createTexture(){
        return new GLTexture;
    }
    Shader createVertexShader(){
        return new GLVertexShader;
    }
    Shader createFragmentShader(){
        return new GLFragmentShader;
    }
    ShaderProgram createShaderProgram(){
        return new GLShaderProgram;
    }

    ~this(){}
private:

}
class GLVertexShader: Shader{
    this(){
        shaderId = glCreateShader(GL_VERTEX_SHADER);
    }
    void setShader(string shader){
        this.shader = cast(const(GLchar)*) shader;
    }
    void buildShader(){
        glShaderSource(this.shaderId, 1, &this.shader, null);
        glCompileShader(this.shaderId);

        GLint success;
        glGetShaderiv(this.shaderId, GL_COMPILE_STATUS, &success);
        if(!success){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            GLchar[512] infoLog;
            glGetShaderInfoLog(this.shaderId, 512, null, infoLog.ptr);
            size_t i = 0;
            while(i < 512 && infoLog[i] != '\0') i++;

            message.message = "Vertex compile shader error.";
            message.compile_message = infoLog[0..i].idup;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);

            assert(false, "Vertex compile shader error:\n" ~ infoLog[0..i]);
        }
    }
    GLuint getId(){
        return shaderId;
    }
    ~this(){
        glDeleteShader(shaderId);
    }

private:
    const(GLchar)* shader;
    GLuint shaderId;
}
class GLFragmentShader: Shader{
    this(){
        this.shaderId = glCreateShader(GL_FRAGMENT_SHADER);
    }
    void setShader(string shader){
        this.shader = cast(const(GLchar)*) shader;
    }
    void buildShader(){
        glShaderSource(this.shaderId, 1, &this.shader, null);
        glCompileShader(this.shaderId);

        GLint success;
        glGetShaderiv(this.shaderId, GL_COMPILE_STATUS, &success);
        if(!success){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            GLchar[512] infoLog;
            glGetShaderInfoLog(this.shaderId, 512, null, infoLog.ptr);
            size_t i = 0;
            while(i < 512 && infoLog[i] != '\0') i++;

            message.message = "Fragment compile shader error.";
            message.compile_message = infoLog[0..i].idup;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);

            assert(false, "Fragment compile shader error:\n" ~ infoLog[0..i]);
        }
    }
    GLuint getId(){
        return shaderId;
    }
    ~this(){
        glDeleteShader(shaderId);
    }

private:
    const(GLchar)* shader;
    GLuint shaderId;
}
class GLShaderProgram: ShaderProgram{
    this(){
        this.shaderProgram = glCreateProgram();
    }
    void bindVertexShader(Shader shader){
        import std.conv: to;
        auto sh = shader.to!GLVertexShader;
        glAttachShader(this.shaderProgram, sh.getId());
        return;
    }
    void bindFragmentShader(Shader shader){
        import std.conv: to;
        auto sh = shader.to!GLFragmentShader;
        glAttachShader(this.shaderProgram, sh.getId());
        return;
    }
    void link(){
        glLinkProgram(shaderProgram);
    }
    GLuint getId(){
        return shaderProgram;
    }
    ~this(){
        glDeleteProgram(shaderProgram);
    }
private:
    GLuint shaderProgram;
}
class GLModel: Model{
public:
    this(){
        glGenBuffers(1, &meshVBO);
        glGenVertexArrays(1, &VAO);
        glGenBuffers(1, &textCordVBO);
    }
    void setShaderProgram(ShaderProgram program){
        import std.conv: to;
        this.program = program.to!GLShaderProgram;
    }
    void setMesh(Mesh mesh){
        float[] data = (cast(float*)((cast(Triangle[])mesh).ptr))[0..(cast(Triangle[])mesh).length * 9];

        glBindVertexArray(VAO);
        glBindBuffer(GL_ARRAY_BUFFER, meshVBO);

        glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
        glEnableVertexAttribArray(0);

        glBindVertexArray(0);

        this.triangleCount = data.length / 9;
    }
    void setTextCord(TextureCoordinate[] cords){
        float[] data = (cast(float*)(cords.ptr))[0..cords.length * 6];

        glBindVertexArray(VAO);
        glBindBuffer(GL_ARRAY_BUFFER, textCordVBO);

        glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, null);
        glEnableVertexAttribArray(1);

        glBindVertexArray(0);
        import std.stdio;
    }
    void setTexture(string name, Texture texture){
        import std.conv: to;

        GLTexture tex = texture.to!GLTexture;

        this.textureId = tex.getId();
    }
    void render(){
        glUseProgram(program.getId());
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId);

        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLES, 0, cast(int) this.triangleCount * 3);
        glBindVertexArray(0);
    }
    ~this(){
        glDeleteBuffers(1, &meshVBO);
        glDeleteVertexArrays(1, &VAO);
    }
private:
    GLShaderProgram program;
    ulong triangleCount;
    GLuint meshVBO;
    GLuint VAO;
    GLuint textCordVBO;
    GLuint textureId;
    int uniformId;
}
class GLTexture: Texture{
public:
    void loadTexture(string dest){
        import bindbc.sdl.image;
        import bindbc.opengl;


        SDL_Surface* textureImage;
        textureImage = SDL_LoadBMP(dest.ptr);

        if(!textureImage){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            message.message = "Error load image.";
            message.image = dest;
            message.status = LogMessage.Status.error;

            globalLogger.log(message);

            assert(false, "Error load image." ~ dest);
        }

        this.size.x = (*textureImage).w;
        this.size.y = (*textureImage).h;
        import std.stdio;

        glGenTextures(1 , &this.textureId);
        glBindTexture(GL_TEXTURE_2D , this.textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, this.size.x, this.size.y, 0, GL_BGR, GL_UNSIGNED_BYTE, (*textureImage).pixels);
        glGenerateMipmap(GL_TEXTURE_2D);

        glBindTexture(GL_TEXTURE_2D, 0);

        SDL_FreeSurface(textureImage);
    }
    void setTexture(inout(ubyte[]) buffer){
        //none
    }
    void setRawtexture(inout(ubyte[]) buffer){
        //none
    }
    void setRawtexture(ubyte[] buffer){
        //none
    }
    Vector2!int getSize(){
        return this.size;
    }
    GLuint getId(){
        return textureId;
    }
private:
    GLuint textureId;
    Vector2!int size;
}