module quickd.core.graphics.opengl.text;
import quickd.core.graphics.opengl.model;

import quickd.core.graphics.renderapi;
import quickd.core.graphics;
import gfm.math.vector;
import bindbc.opengl;
import bindbc.freetype;

private static Mesh     mesh;

private static uint     textVAO;
private static uint[3]  textVBO;

FT_Library ft;
private static initText(){
    static bool inited;
    if(!inited){
        synchronized{
            if(!inited){
                inited = true;
                mesh.vertexArray = [
                    vec3!float(1, -1, 0),
                    vec3!float(1, 0, 0),
                    vec3!float(0, -1, 0),
                    vec3!float(0, 0, 0),
                ];
                mesh.indexBuffer = [0, 1, 2, 1, 2, 3];
                mesh.uvArray = [
                    vec2!float(1f, 1f),
                    vec2!float(1f, 0f),
                    vec2!float(0f, 1f),
                    vec2!float(0f, 0f),
                ];
            }
            {
                glGenVertexArrays(1, &textVAO);
                glGenBuffers(3, textVBO.ptr);
                glBindVertexArray(textVAO);

                glBindBuffer(GL_ARRAY_BUFFER, textVBO[0]);
                float[] data = (cast(float*)(mesh.vertexArray.ptr))[0..mesh.vertexArray.length*3];
                glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
                glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
                glEnableVertexAttribArray(0);

                glBindBuffer(GL_ARRAY_BUFFER, textVBO[1]);
                data = (cast(float*)(mesh.uvArray.ptr))[0..mesh.uvArray.length*2];
                glBufferData(GL_ARRAY_BUFFER, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
                glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, null);
                glEnableVertexAttribArray(1);

                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, textVBO[2]);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indexBuffer.length * uint.sizeof, mesh.indexBuffer.ptr, GL_STATIC_DRAW);

                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindVertexArray(0);
            }
        }
    }
}

class GLText: Text{
    this(){
        initText();
        this.shader = new GLShader;
        shader.setVertexShader(import("shaders/text/text.vert"));
        shader.setFragmentShader(import("shaders/text/text.frag"));
        shader.compile();
        this.material = new GLMaterial;
        material.setShader(shader);
    }
    void setFont(Font font){
        import std.conv: to;
        this.font = font.to!GLFont;
    }
    void setText(dstring text){
        this.text = text;
    }
    void render(RenderAPI api, Actor actor){
        import std.conv: to;
        GLShader shader = this.material.getShader().to!GLShader;
        GLuint prog = shader.getId();
        glUseProgram(prog);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, this.font.getId());

        mat4!float projection = api.getProjection();

        mat4!float model = mat4!float.identity();
        vec3!float pos = actor.getGlobalPosition;
        vec3!float scale = actor.getGlobalScale;

        model = cast(mat4!float)(actor.getGlobalRotation) *(mat4!float([
                [   0,      0,       0,     0f],
                [   0,      0,       0,     0f],
                [   0,      0,       0,     0f],
                [ pos.x,   pos.y,  pos.z,   1f]
        ]) + mat4!float([
                [ scale.x,  0,       0,     0f],
                [   0,    scale.y,   0,     0f],
                [   0,      0,     scale.z, 0f],
                [   1,      1,       1,     1f]
        ]));

        glUniformMatrix4fv(shader.getProjectionLocation(), 1, GL_FALSE, cast(float*)&projection);
        glUniformMatrix4fv(shader.getModelLocation(), 1, GL_FALSE, cast(float*)&model);

        glBindVertexArray(textVAO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, textVBO[2]);


        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable( GL_BLEND );

        float advance = 0;
        foreach(ch; this.text){
            Character character = this.font.getChar(ch);
            vec3!float size;
            vec3!float position;
            size.x = cast(float)character.size.x;
            size.y = cast(float)character.size.y;
            size.z = 1;
            position.x = cast(float)character.position.x / cast(float)font.getSize().x;
            position.y = cast(float)character.position.y / cast(float)font.getSize().y;
            position.z = 0;
            float ypos = 0;
            vec2!float mod = [advance, ypos];


            glUniform2fv(glGetUniformLocation(prog, "mod"), 1, cast(float*)&mod);
            glUniform3fv(glGetUniformLocation(prog, "size"), 1, cast(float*)&size);
            glUniform3fv(glGetUniformLocation(prog, "texture_pos"), 1, cast(float*)&position);
            glUniform3fv(glGetUniformLocation(prog, "font"), 1, cast(float*)&position);
            size.x /= cast(float)font.getSize().x;
            size.y /= cast(float)font.getSize().y;

            glUniform3fv(glGetUniformLocation(prog, "texSize"), 1, cast(float*)&size);

            glDrawElements(GL_TRIANGLES, cast(int)mesh.indexBuffer.length, GL_UNSIGNED_INT, cast(void*)null);
            advance += character.advance/64f;
        }
        glDisable(GL_BLEND);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        glUseProgram(0);
    }
private:
    GLFont font;
    dstring text;

    GLShader shader;
    GLMaterial material;
}
class GLFont: Font{
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
    vec2!int getSize(){
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