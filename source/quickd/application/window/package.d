module quickd.application.window;
public import
quickd.application.window.nwindow;

class Window: NativeWindow{
public:
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