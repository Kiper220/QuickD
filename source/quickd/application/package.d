module quickd.application;
public import
quickd.application.window,
quickd.application.renderer;

class Application{
public

    void setName(string name){
        this.name = name;
    }

private:
    string name = "Untitled Application";
}