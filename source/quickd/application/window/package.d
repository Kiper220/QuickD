module quickd.application.window;
import gfm.math.vector;
public import
quickd.application.window.nwindow;

class Window: NativeWindow{
public:
    this(string windowName = "Untitled", vec2!int position = undefined, vec2!int size = [640, 480]){
        super(windowName, position, size);
    }
    override void input(bool on){
        if(!textMode && on && focused){
            super.input(on);
        }else if(textMode && !on && focused){
            super.input(on);
        }
        this.textMode = on;
    }


private:
    bool textMode;
    bool focused;
}