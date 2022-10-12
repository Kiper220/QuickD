module quickd.core.graphics.actor.sprite;
public import quickd.core.graphics.renderapi;
public import quickd.core.graphics.mesh;

private static void initSprite(RenderAPI api){
    if(Sprite.imageShader is null)
        synchronized{
            if(Sprite.imageShader is null){
                Sprite.imageShader = api.createShader();
                Sprite.imageShader.setVertexShader(import("shaders/default/image.vert"));
                Sprite.imageShader.setFragmentShader(import("shaders/default/image.frag"));
                Sprite.imageShader.compile();
            }
        }
}

class Sprite: Actor{
    this(RenderAPI api){
        initSprite(api);
        Mesh mesh1;
        mesh1.vertexArray = [
            vec3!float(1, -1, 0),
            vec3!float(1, 0, 0),
            vec3!float(0, -1, 0),
            vec3!float(0, 0, 0),
        ];
        mesh1.indexBuffer = [0, 1, 2, 1, 2, 3];
        mesh1.uvArray = [
            vec2!float(1f, 1f),
            vec2!float(1f, 0f),
            vec2!float(0f, 1f),
            vec2!float(0f, 0f),
        ];

        this.prepeareModel = api.createModel();
        this.texture = api.createTexture();
        this.prepeareMaterial = api.createMaterial();

        this.prepeareMaterial.setShader(imageShader);
        this.prepeareMaterial.addTexture("tex",this.texture);

        this.prepeareModel.setMaterial(this.prepeareMaterial);
        this.prepeareModel.setMesh(mesh1);
    }
    void setImage(string imageName){
        if(isLoaded){
            this.removeRenderable();
        }
        this.texture.loadTexture(imageName);
        auto size = this.texture.getSize();
        this.prepeareMaterial.setVector3Parametr("size", vec3!float([size.x, size.y, 1f]));
        this.setRenderable(prepeareModel);
        isLoaded = true;
    }
    void removeImage(){
        if(isLoaded){
            this.removeRenderable();
            this.texture.unloadTexture();
            this.prepeareMaterial.removeVector3Parametr("size");
        }
        isLoaded = false;
    }
    static Shader imageShader;
private:
    bool isLoaded;
    Model prepeareModel;
    Material prepeareMaterial;
    Texture texture;
};