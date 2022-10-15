module quickd.graphics.opengl.gl20;
import quickd.graphics.opengl.api;
import bindbc.opengl.bind.gl20;

import quickd.graphics.renderapi;
import quickd.application.window.nwindow;
import gfm.math.vector;
import quickd.graphics.level2d;
import quickd.graphics.renderapi;

extern(C) @nogc nothrow {
    ubyte* stbi_load(const(char) *filename, int *x, int *y, int *channels_in_file, int desired_channels);
    void stbi_image_free(void *retval_from_stbi_load);
}

class OpenGL20API: OpenGLAPI{
    void makeCurrentWindow(NativeWindow window){
        import bindbc.sdl;
        SDL_GL_MakeCurrent(cast(SDL_Window*)window.getLowLevelWindow(), window.getLowLevelContext());
    }
    void render(vec2!int size){
        import bindbc.opengl;

        if(size != this.projectionSize && this.viewSetting != projectionType)
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
                            [0f,0f,1f,0f],
                            [(cast(float)-size.x/2f),cast(float)size.y/2f-1,0,1f]
                    ])*mat4!float.orthographic
                        (cast(float)-size.x/2f,cast(float)size.x/2f,cast(float)-size.y/2f,cast(float)size.y/2f,-1,1);
                }
                break;
            }

        glClearColor(0,0,0,0);
        glClear(GL_COLOR_BUFFER_BIT);
        if(this.level !is null){
            this.level.render(this);
        }
        glFinish();
    }
    void setLevel(Level level){
        this.level = level;
    }
    void setView(ViewSettings viewSetting){
        this.viewSetting = viewSetting;
    }
    void clear(){
        glClearColor(0,0,0,0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    void finish(){
        glFinish();
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
    Level           level;

    mat4!float      projection;
    vec2!int        projectionSize;
    ViewSettings    projectionType;

    ViewSettings    viewSetting = ViewSettings.windowSizedView;
}
/// Combines material and texture. A new instance can only be obtained from RenderAPI.
class GL20Model: GLModel{
    void render(RenderAPI rapi, Actor actor){
        import std.conv: to;

        GL20Shader shader = material.getShader().to!GL20Shader;
        Texture[string] textures = this.material.getTextures();

        uint prog = shader.getId();
        glUseProgram(prog);
        auto vec3Param = material.getVector3Paramtrs();

        foreach(key, param; vec3Param){
            glUniform3fv(glGetUniformLocation(shader.getId(), key.ptr), 1, cast(float*)&param);
        }
        foreach(i, texture; textures.values){
            glActiveTexture(GL_TEXTURE0 + cast(uint)i);
            glBindTexture(GL_TEXTURE_2D, texture.to!GL20Texture.getId());
        }

        mat4!float projection = rapi.getProjection();
        mat4!float model = actor.getModelMatrix();

        glUniformMatrix4fv(shader.getProjectionLocation(), 1, GL_FALSE, cast(float*)&projection);
        glUniformMatrix4fv(shader.getModelLocation(), 1, GL_FALSE, cast(float*)&model);

        this.mesh.bind();
        glDrawElements(GL_TRIANGLES, cast(int)this.mesh.indexBuffer.length, GL_UNSIGNED_INT, cast(void*)null);
        this.mesh.unbind();

        glUseProgram(0);

    }
    ModelType getModelType(){
        return ModelType.staticModel;
    }
    void setMesh(Mesh mesh){
        import std.conv: to;
        this.mesh = mesh.to!GL20Mesh;
    }
    void setMaterial(Material material){
        import std.conv: to;
        this.material = material.to!GL20Material;
    }
private:

    GL20Mesh            mesh;
    GL20Material        material;

}
class GL20Mesh: GLMesh{
    this(){
        glGenBuffers(3, VBO.ptr);
    }

    void setVertexArray(vec3!float[] vertexArray){
        this.vertexArray = vertexArray;

        glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
        float[] data = (cast(float*)(vertexArray.ptr))[0..vertexArray.length*3];
        glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    void setUVArray(vec2!float[] uvArray){
        this.uvArray = uvArray;

        glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);

        float[] data = (cast(float*)(uvArray.ptr))[0..uvArray.length*2];
        glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, null);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    void setIndexBuffer(uint[] indexBuffer){
        this.indexBuffer = indexBuffer;

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO[2]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.length * uint.sizeof, indexBuffer.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    void bind(){
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);

        glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, null);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO[2]);
    }
    void unbind(){
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    ~this(){
        glDeleteBuffers(3, VBO.ptr);
    }

private:
    vec3!float[]    vertexArray;
    vec2!float[]    uvArray;
    uint[]          indexBuffer;

    uint[3]         VBO;        /// 0 - vertexArray, 1 - uvArray, 3 - indexBuffer.
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

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
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

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glBindTexture(GL_TEXTURE_2D, 0);
        this.size = [0, 0];
    }
    void setTextureId(uint id){
        glDeleteTextures(1, &this.textureId);
        this.textureId = id;
        this.size = [500, 500];
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

private static GL20Mesh     mesh;

private static uint     textVAO;
private static uint[3]  textVBO;

import bindbc.freetype;
FT_Library ft;
private static initText(){
    static bool inited;
    if(!inited){
        synchronized{
            if(!inited){
                mesh = new GL20Mesh;
                mesh.setIndexBuffer([0, 1, 2, 1, 2, 3]);
                mesh.setVertexArray([
                    vec3!float(1, -1, 0),
                    vec3!float(1, 0, 0),
                    vec3!float(0, -1, 0),
                    vec3!float(0, 0, 0),
                ]);
                mesh.setUVArray([
                    vec2!float(1f, 1f),
                    vec2!float(1f, 0f),
                    vec2!float(0f, 1f),
                    vec2!float(0f, 0f),
                ]);
            }
        }
    }
}
class GL20Text: GLText{
    struct Data{
        Character character;
        mat3!float data;
    }
    this(){
        initText();
        this.shader = new GL20Shader;
        shader.setVertexShader(import("shaders/gl20/text/text.vert"));
        shader.setFragmentShader(import("shaders/gl20/text/text.frag"));
        shader.compile();
    }
    void setFont(Font font){
        import std.conv: to;
        this.font = font.to!GL20Font;
    }
    void setText(dstring text){
        this.text = text;
        data = null;
        foreach(ch; text){
            Data dat;
            dat.character = font.getChar(ch);
            data ~= dat;
        }
        this.prepeareText();
    }
    void prepeareText(){
        int maxHeight;
        foreach(ch; data){
            maxHeight = maxHeight > ch.character.bearing.y ? maxHeight: ch.character.bearing.y;
        }
        float offsetX = 0;
        foreach(ref ch; data){
            ch.data.c[2][1] = cast(float)ch.character.bearing.y - maxHeight;
            ch.data.c[2][0] = cast(float)offsetX + ch.character.bearing.x;
            offsetX += cast(float)ch.character.advance/64f;

            ch.data.c[1][0] = cast(float)ch.character.size.x / cast(float)font.getSize().x;
            ch.data.c[1][1] = cast(float)ch.character.size.y / cast(float)font.getSize().y;

            ch.data.c[0][0] = cast(float)ch.character.size.x;
            ch.data.c[0][1] = cast(float)ch.character.size.y;

            ch.data.c[0][2] = cast(float)ch.character.position.x / cast(float)font.getSize().x;
            ch.data.c[1][2] = cast(float)ch.character.position.y / cast(float)font.getSize().y;
        }
        import std.conv: to;
        this.matrixPos = glGetUniformLocation(shader.getId(), "info");
    }
    void render(RenderAPI rapi, Actor actor){
        const uint prog = shader.getId();

        auto projection = rapi.getProjection();
        auto model = actor.getModelMatrix();

        glUseProgram(prog);


        glUniformMatrix4fv(shader.getProjectionLocation(), 1, GL_FALSE, cast(float*)&projection);
        glUniformMatrix4fv(shader.getModelLocation(), 1, GL_FALSE, cast(float*)&model);

        mesh.bind();

        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, this.font.getId());

        foreach(ch; data){
            glUniformMatrix3fv(this.matrixPos, 1, GL_FALSE, cast(float*)&ch.data);

            glDrawElements(GL_TRIANGLES, cast(int)mesh.indexBuffer.length, GL_UNSIGNED_INT, cast(void*)null);
        }

        glDisable(GL_BLEND);
        mesh.unbind();
        glBindTexture(GL_TEXTURE_2D, 0);
    }
private:
    GL20Font      font;
    dstring     text;

    Data[]      data;

    GL20Shader    shader;

    uint        matrixPos;
    uint        texPos;
}
class GL20Font: GLFont{
    shared static this(){
        version(Windows) loadFreeType("libs/freetype.dll");
        else loadFreeType();
        if (FT_Init_FreeType(&ft)){
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            message.message = "Could not init FreeType";
            message.status = LogMessage.Status.fatal;

            globalLogger.log(message);
            assert(false);
        }
    }
    this(){
        glGenTextures(1, &textureId);
    }
    void setFont(string dest){
        if(FT_New_Face(ft, dest.ptr, 0, &face)){
            import quickd.core.logger: globalLogger, LogMessage;
            import std.conv: to;
            LogMessage message = LogMessage();

            message.message = "Freetype failed to load font";
            message.font    = fontDest;
            message.symbol  = dest;
            message.status  = LogMessage.Status.fatal;

            globalLogger.log(message);
            assert(false);
        }
        this.fontDest = dest;
    }
    void setFontSize(ushort size){
        import std.math.rounding: ceil;
        FT_Set_Pixel_Sizes(face, 0, size);

        const double pixel_size = size;

        // Высота и ширина шрифта в пикселях
        int fontHeight = cast(int)ceil(((*face).bbox.yMax - (*face).bbox.yMin) * pixel_size / (*face).units_per_EM);
        int fontWidth = cast(int)ceil(((*face).bbox.xMax - (*face).bbox.xMin) * pixel_size / (*face).units_per_EM);

        this.atlas.setMaxSize(vec2!int([fontWidth, fontHeight]));
    }
    Character getChar(dchar ch){
        auto character = ch in this.characters;
        if(character is null) return loadChar(ch);
        return *character;
    }
    Character loadChar(dchar ch){
        debug if((ch in this.characters) !is null){
            import quickd.core.logger: globalLogger, LogMessage;
            import std.conv: to;
            LogMessage message = LogMessage();

            message.message = "This font is allready loaded";
            message.font    = fontDest;
            message.symbol  = ch.to!string;
            message.status  = LogMessage.Status.error;

            globalLogger.log(message);
            throw new Exception("Font is allready loaded: " ~ ch.to!string);
        }
        if (FT_Load_Char(face, cast(uint)ch, FT_LOAD_RENDER)){
            import quickd.core.logger: globalLogger, LogMessage;
            import std.conv: to;
            LogMessage message = LogMessage();

            message.message = "Freetype failed to load Glyph";
            message.font    = fontDest;
            message.symbol  = ch.to!string;
            message.status  = LogMessage.Status.fatal;

            globalLogger.log(message);
            assert(false);
        }
        const size_t glyphSizeX = (*face).glyph.bitmap.width;
        const size_t glyphSizeY = (*face).glyph.bitmap.rows;
        Character character =
        this.atlas.addChar(
                (*face).glyph.bitmap.buffer[0 .. glyphSizeX*glyphSizeY],
            vec2!int([cast(int)glyphSizeX, cast(int)glyphSizeY]),
            vec2!int([cast(int)(*face).glyph.bitmap_left, cast(int)(*face).glyph.bitmap_top]),
            cast(uint)(*face).glyph.advance.x
        );
        characters[ch] = character;


        glBindTexture(GL_TEXTURE_2D, this.textureId);
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RED,
            this.atlas.size.x,
            this.atlas.size.y,
            0,
            GL_RED,
            GL_UNSIGNED_BYTE,
            this.atlas.buffer.ptr
        );
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glBindTexture(GL_TEXTURE_2D, 0);

        return character;
    }
    vec2!int getSize() const pure{
        return this.atlas.size;
    }
    uint getId(){
        return this.textureId;
    }
    void loadChars(dstring str){
        foreach(ch; str){
            const auto t = this.loadChar(ch);
        }
    }
    ~this(){
        FT_Done_Face(face);
        glDeleteTextures(1, &this.textureId);
    }
    GLShader shader;
private:
    uint                textureId;
    Character[dchar]    characters;
    Atlas               atlas;
    string              fontDest;
    FT_Face             face = null;
}

struct Atlas{
    this(vec2!int maxCharSize){
        this.size = [maxCharSize.x*12,0];
        this.maxCharSize = maxCharSize;
    }
    void setMaxSize(vec2!int maxCharSize){
        this.buffer.length = 0;
        this.yLine = 0;
        this.size = [maxCharSize.x*12,0];

        this.position = [0,0];
        this.maxCharSize = maxCharSize;
    }
    Character addChar(ubyte[] buffer, vec2!int size, vec2!int bearing, uint advance){
        if((position.x + size.x) > this.size.x){
            position.y += yLine + 5;
            position.x = 0;
            yLine = 0;
        }
        if((position.y + maxCharSize.y) > this.size.y){
            this.size.y += position.y + maxCharSize.y*2 - this.size.y + 5;
            this.buffer.length = (this.size.y)*maxCharSize.x*12;
        }
        for(int y = 0; y < size.y; y++){
            for(int x = 0; x < size.x; x++){
                this.buffer[maxCharSize.x*12*(position.y+y) + position.x + x] = buffer[y*size.x + x];
            }
        }
        Character character;
        character.position = this.position;
        character.size = size;
        character.bearing = bearing;
        character.advance = advance;

        this.position.x += size.x + 5;
        yLine = yLine > size.y? yLine: size.y;

        return character;
    }

    ubyte[] buffer;
    uint    yLine;
    vec2!int size;
    private:
    vec2!uint position;
    vec2!uint maxCharSize;
}