module quickd.application.window.nwindow;

import bindbc.sdl;
import quickd.core.math.vector;
public import quickd.application.window.wmevents;

////////////////////////////////////
/////// Load and init sdl2. ///////
//////////////////////////////////
shared static this(){
    import bindbc.sdl:
    SDLSupport, sdlSupport, loadSDL,
    SDL_INIT_EVERYTHING, SDL_INIT_TIMER,
    SDL_Init, SDL_GetError;
    import std.stdio: writeln;

    /// for comfortable dlang string
    static string cStringToDString(const char* str){
        size_t i = 0;
        while(str[i]) i++;

        string ret = cast(string)(str[0..i]);
        return ret;
    }

    /// Load sdl2
    version(Windows){
        const auto sdl =  loadSDL("libs/SDL2.dll");
    }
    else
        const auto sdl = loadSDL();


    /// Check SDL2 version
    if(sdl != sdlSupport) {
        if(SDLSupport.badLibrary) {
            writeln("Loaded SDL version is very low. Minimum requared SDL 2.0.22!");
            throw new Exception("SDL very low version!");
        }
        else {
            throw new Exception("SDL2 not found!");
        }
    }
    /// Init video and audio
    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO) != 0)
        throw new Exception("SDL initialize error" ~ cStringToDString(SDL_GetError()));
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetSwapInterval(1);
}

////////////////////////////////////////////////////////////////////////
/// Native SDL2 window. In this version QuickD only opengl context. ///
//////////////////////////////////////////////////////////////////////

class NativeWindow{
public:
    /// Default constructor. Window create by automatic, but hidden.
    this(string windowName = "Untitled", Vector2!int position = undefined, Vector2!int size = [640, 480]){
        this.window = SDL_CreateWindow( windowName.ptr, position.x,
                                        position.y, size.x, size.y,
                                        SDL_WINDOW_OPENGL|SDL_WINDOW_HIDDEN|SDL_WINDOW_RESIZABLE);
        this.context = SDL_GL_CreateContext(this.window);
        this.evSystem = WMEventSystem.getInstance();
        this.winId = SDL_GetWindowID(this.window);
        this.evSystem.addWindow(winId, &this.proccessEvent);
        debug {
            import quickd.core.logger: globalLogger, LogMessage;
            import std.conv: to;
            LogMessage message = LogMessage();

            message.message = "Created new native window.";
            message.window_name = windowName;
            message.context = "OpenGL";
            message.position = position.toString;
            message.size = size.toString;
            message.status = message.Status.debugging;

            globalLogger.log(message);

            this.windowName = windowName;
        }
    }
    /// For show window
    void show(){
        SDL_ShowWindow(this.window);

        debug {
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            message.message = "Native window show on the screen.";
            message.window_name = this.windowName;
            message.visible = "ON";
            message.status = message.Status.debugging;

            globalLogger.log(message);
        }
    }
    /// For hide window
    void hide(){
        SDL_HideWindow(this.window);

        debug {
            import quickd.core.logger: globalLogger, LogMessage;
            LogMessage message = LogMessage();

            message.message = "Native window hidden from the screen.";
            message.window_name = windowName;
            message.visible = "OFF";
            message.status = message.Status.debugging;

            globalLogger.log(message);
        }
    }
    /// Set text input mode.
    void input(bool on){
        on? SDL_StartTextInput(): SDL_StopTextInput();
    }
    /// For swap gl buffer.
    void swap(){
        SDL_GL_SwapWindow(this.window);
    }
    /// Call back for wmevents.
    void proccessEvent(WMEvent event){
        foreach (el; eventList[event.type]){
            el(event);
        }
    }
    /// Add window event callback.
    void addEvent(EventType type, string name, void delegate(WMEvent) event){
        this.eventList[type][name] = event;
    }
    /// Remove window event callback.
    void removeEvent(EventType type, string name){
        this.eventList[type].remove(name);
    }
    /// Get sdl2 window
    void* getLowLevelWindow(){
        return this.window;
    }
    /// Get sdl2 context
    SDL_GLContext getLowLevelContext(){
        return this.window;
    }

    /// Destroy window and gl context.
    ~this(){
        WMEventSystem.removeWindow(this.winId);
        SDL_GL_DeleteContext(context);
        SDL_DestroyWindow(window);
    }
    /// Forwarding sdl constant.
    alias centered = SDL_WINDOWPOS_CENTERED;
    alias undefined = SDL_WINDOWPOS_UNDEFINED;

private:
    WMEventSystem evSystem;
    debug string windowName;
    SDL_Window* window;     /// native window ptr
    uint winId;
    SDL_GLContext context;  /// glcontext struct

    void delegate(WMEvent)[string][EventType.lastEvent] eventList;
}