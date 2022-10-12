module quickd.core.graphics.renderapi;
public import
quickd.application.window.nwindow,
gfm.math.vector,
gfm.math.matrix,
gfm.math.quaternion;
import quickd.core.graphics;

enum ModelType{
    staticModel,
    dynamicModel
}
vec3!T qrot(T)(Quaternion!T q, vec3!T v)
{
    return v + 2.0*cross(vec3!T([q.x, q.y, q.z]), cross(vec3!T([q.x, q.y, q.z]),v) + q.w*v);
}

enum ViewSettings{
    unitSizedView,
    proportionalView,
    windowSizedView,
}

/// Interface of RenderAPI
interface RenderAPI{
    void makeCurrentWindow(NativeWindow);
    void render(vec2!int size);
    void setLevel(Level level);
    void removeLevel();
    void setView(ViewSettings viewSetting);
    Text createText();
    Font createFont();
    Model createModel();
    Material createMaterial();
    Texture createTexture();
    Shader createShader();
    mat4!float getProjection();
}
/// Level -- top level of scene tree.
class Level{

    void addActor(string name, Actor actor){                /// Add created actor.
        synchronized(this){
            if((name in this.actors) !is null)
                throw new Exception("Actor by \"" ~ name ~ "\" allready exist.");
            this.actors.require(name, actor);
        }
    }
    void removeActor(string name){                          /// Remove actor by name.
        synchronized(this){
            this.actors.remove(name);
        }
    }
    void removeActor(Actor actor){                          /// Remove actor by actor instance.
        synchronized(this){
            foreach(key, value; this.actors){
                if(value is actor)
                    this.actors.remove(key);
            }
        }
    }
    Actor getChildActor(string name){
        Actor actor;
        synchronized(this){
            actor = *(name in this.actors);
        }
        if(actor is null)
            throw new Exception("Actor by \"" ~ name ~ "\" not exist.");
        return actor;
    }
    Actor[] getActors(){
        Actor[] actors;
        synchronized(this){
            actors = this.actors.values.dup;
        }
        return actors;
    }
    Actor[string] getMapOfActors(){
        Actor[string] actors;
        synchronized(this){
            actors = this.actors.dup;
        }
        return actors;
    }


    void render(RenderAPI rapi){                            /// Unsafe method for multirender!!!!
        synchronized(this){
            foreach(actor; actors.values){
                actor.render(rapi);
            }
        }
    }
private:
    Actor[string] actors;
}
/// Actor -- minimal scene unit
class Actor{
    void addChild(string name, Actor actor){                /// Add created actor.
        synchronized(this){
            if((name in this.childsActor) !is null)
                throw new Exception("Actor by \"" ~ name ~ "\" allready exist.");
            this.childsActor.require(name, actor);
            actor.parent = this;
        }
    }
    void removeChild(string name){                          /// Remove actor by name.
        synchronized(this){
            this.childsActor.remove(name);
        }
    }
    void removeChild(Actor actor){                          /// Remove actor by actor instance.
        synchronized(this){
            foreach(key, value; this.childsActor){
                if(value is actor)
                    this.childsActor.remove(key);
            }
        }
    }

    Actor getChildActor(string name){
        Actor actor;
        synchronized(this){
            actor = *(name in this.childsActor);
        }
        if(actor is null)
            throw new Exception("Actor by \"" ~ name ~ "\" not exist.");
        return actor;
    }
    Actor[] getActors(){
        Actor[] actors;
        synchronized(this){
            actors = this.childsActor.values.dup;
        }
        return actors;
    }
    Actor[string] getMapOfActors(){
        Actor[string] actors;
        synchronized(this){
            actors = this.childsActor.dup;
        }
        return actors;
    }

    void setRenderable(Renderable rend){                             /// Set model for render.   (if not set => not render)
        synchronized(this){
            this.renderable = rend;
        }
    }
    void removeRenderable(){                                     /// Remove model.           (if not set => not render)
        synchronized(this){
            this.renderable = null;
        }
    }
    void render(RenderAPI rapi){                           /// Don't call this.
        synchronized(this){
            if(parent !is null){
                auto parPosition    = this.parent.globPosition;
                auto parScale       = this.parent.globScale;
                auto parRotation    = this.parent.globRotation;
                mat4!float globTransformMatrix = [
                    [  parScale.x,       0,            0,       0],
                    [      0,        parScale.y,       0,       0],
                    [      0,            0,        parScale.z,  0],
                    [parPosition.x,parPosition.y,parPosition.z, 1],
                ];
                mat4!float locTransformMatrix = [
                        [  scale.x,    0,         0,       0],
                        [    0,      scale.y,     0,       0],
                        [    0,        0,       scale.z,   0],
                        [position.x,position.y,position.z, 1],
                ];
                globTransformMatrix *= cast(mat4!float)parRotation;
                globTransformMatrix = locTransformMatrix * globTransformMatrix;
                this.globPosition = cast(float[3])globTransformMatrix.c[3][0..3];
                this.globScale = [globTransformMatrix.c[0][0],globTransformMatrix.c[1][1],globTransformMatrix.c[2][2]];
                this.globRotation = this.rotation * parRotation;
            }else{
                this.globPosition = this.position;
                this.globRotation = this.rotation;
                this.globScale    = this.scale;
            }

            if (this.renderable !is null){
                this.renderable.render(rapi, this);
            }
            foreach (actor; childsActor.values){
                actor.render(rapi);
            }
        }
    }
    vec3!float getGlobalPosition(){
        return this.globPosition;
    }
    vec3!float getGlobalScale(){
        return this.globScale;
    }
    quatf      getGlobalRotation(){
        return this.globRotation;
    }


    vec3!float position = [0,0,0];                              /// Actor local position
    vec3!float scale    = [1,1,1];                              /// Actor local scale
    quatf      rotation = quatf.fromEulerAngles(0,0,0);         /// Actor local rotation
private:
    vec3!float globPosition = [0,0,0];                          /// Actor global position
    vec3!float globScale    = [1,1,1];                          /// Actor global scale
    quatf      globRotation = quatf.fromEulerAngles(0,0,0);     /// Actor global rotation

    Renderable renderable;                /// Actor render model
    Actor parent;               /// Parent actor
    Actor[string] childsActor;  /// Childs actor
}
interface Renderable{
    void render(RenderAPI, Actor);                          /// Don't call this.
}
interface Text: Renderable{
    void setFont(Font font);
    void setText(dstring text);
}
struct Character {
    vec2!int    position;  /// Glyph position(atlas).
    vec2!int    size;      /// Glyph size.
    vec2!int    bearing;   /// Offset of the upper left point of the glyph
    uint        advance;   /// Horizontal offset to the beginning of the next glyph
};
interface Font{
    void setFont(string dest);
    void setFontSize(ushort size);
    Character loadChar(dchar ch);
    void loadChars(dstring str);
}
/// Combines material and texture. A new instance can only be obtained from RenderAPI.
interface Model: Renderable{
    ModelType getModelType();                               /// No implement.
    void test();
    void setMesh(Mesh mesh);                                /// Set mesh.
    void setMaterial(Material material);                    /// Set material.
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
