module quickd.core.graphics.renderapi;
public import quickd.application.window.nwindow;
import quickd.core.graphics;
import quickd.core.math;

enum ModelType{
    staticModel,
    dynamicModel
}

/// Interface of RenderAPI
interface RenderAPI{
    void makeCurrentWindow(NativeWindow);
    void render();
    void setLevel(Level level);
    void removeLevel();
    Model createModel();
    Material createMaterial();
    Texture createTexture();
    Shader createShader();
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


    void render(){                                          /// Unsafe method for multirender!!!!
        synchronized(this){
            foreach(actor; actors.values){
                actor.render();
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

    void setModel(Model model){                             /// Set model for render.   (if not set => not render)
        this.model = model;
    }
    void removeModel(){                                     /// Remove model.           (if not set => not render)
        this.model = null;
    }
    void render(){
        this.model.render(this);
    }                                                       /// Don't call this.
private:
    Vector3!float position;     /// Actor local position
    Vector3!float scale;        /// Actor local scale
    Vector3!float rotation;     /// Actor local rotation

    Model model;                /// Actor render model
    Actor parent;               /// Parent actor
    Actor[string] childsActor;  /// Childs actor
}
/// Combines material and texture. A new instance can only be obtained from RenderAPI.
interface Model{
    void render(Actor actor);                               /// Don't call this.
    ModelType getModelType();                               /// No implement.
    void setMesh(Mesh mesh);                                /// Set mesh.
    void setMaterial(Material material);                    /// Set material.
}
/// Сombines shader and textures. A new instance can only be obtained from RenderAPI.
interface Material{
    void addTexture(string textureName, Texture texture);   /// Add texture by name.
    void renameTexture(string oldName, string newName);     /// Rename texture from oldName to newName.
    void setShader(Shader shader);                          /// Set shader.
    Shader getShader();                                     /// Get shader.
    Texture[string] getTextures();                          /// Get all textures.
    void removeTexture(string textureName);                 /// Remove texture by name.
}
/// Texture loader. A new instance can only be obtained from RenderAPI.
interface Texture{
    void loadTexture(string src);                           /// Load texture by name.
    void unloadTexture();                                   /// Unload texture.
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
