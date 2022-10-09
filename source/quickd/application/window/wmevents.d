module quickd.application.window.wmevents;
import gfm.math.vector;
import std.typecons: Tuple, tuple;

////////////////////////////////////
//////// Window Event Types ///////
//////////////////////////////////
struct MouseMotionEvent{
    uint timestamp;
    uint which;
    uint state;
    vec2!int pos;
    vec2!int rel;
}
struct MouseButtonEvent{
    uint timestamp;
    uint which;
    ubyte button;
    ubyte state;
    vec2!int pos;
}

struct Keysym{
    ushort scanCode;
    ushort symCode;
    ushort mod;
}
struct KeyboardEvent{
    uint timestamp;
    ubyte state;
    ubyte repeat;
    Keysym sym;
}
enum WindowEventID : ubyte {
    none,
    shown,
    hidden,
    expose,
    moved,
    resised,
    size_changed,
    minimized,
    maximized,
    restored,
    enter,
    leave,
    focusGained,
    focusLost,
    close,
    takeFocus,
    hitTest,
    iccProfChanged,
    displayChanged,
}
struct WindowEvent {
    uint timestamp;
    WindowEventID event;
    int data1;
    int data2;
}
struct TextInputEvent {
    uint timestamp;
    char[SDL_TEXTINPUTEVENT_TEXT_SIZE] text;
}
string textToString(char[SDL_TEXTEDITINGEVENT_TEXT_SIZE] text){
    string str;
    size_t i = 0;
    while(text[i]) i++;
    str = text[0..i].idup;

    return str;
}
struct WMEvent{
    EventType type;
    union{
        KeyboardEvent    key;
        MouseButtonEvent mouse;
        MouseMotionEvent motion;
        WindowEvent      window;
        TextInputEvent   text;
    }
}
enum EventType {
    empty,

    quit, terminating, lowmemory,appWillenterBackground, appDidenterBackground, appWillenterForeground,
    appDidenterForeground,localeChanged,

    displayEvent,windowEvent, sysWmEvent,

    keyDown , keyUp, textEditing, textInput, keyMapChanged, textEditingExt,

    mouseMotion, mouseButtonDown, mouseButtonUp, mouseWheel,

    joyAxisMotion, joyBallMotion, joyHatMotionN, joyButtonDown, joyButtonUp, joyDeviceAdded,
    joyDeviceRemoved,

    controllerAxisMotion, controllerButtonDown, controllerButtonUp, controllerDeviceAdded,
    controllerDeviceRemoved, controllerDeviceRemapped, controllerTouchpadDown, controllerTouchpadMotion,
    controllerTouchpadUp, controllerSensorUpdate,

    fingerDown, fingerUp, fingerMotion,

    dollarGesture,dollareCord,multigesture,

    clipboardUpdate,

    dropFile, dropText, dropBegin, dropComplete,

    audioDeviceAdded, audioDeviceRemoved,

    sensorUpdate,

    renderTargetsReset, renderDeviceReset,

    userEvent,

    lastEvent
}
import bindbc.sdl;
class WMEventSystem{
private:
    this(){}
public:
    static WMEventSystem getInstance(){
        if(system is null)
            synchronized if(system is null)
                system = new WMEventSystem;
        return system;
    }
    void addWindow(uint winId, void delegate(WMEvent) dg){
        synchronized(this){
            this.listWindows[winId] = dg;
        }
    }
    static void removeWindow(uint winId){
        if(this.system !is null){
            synchronized(this.system){
                this.listWindows.remove(winId);
            }
        }
    }
    void pollAllEvents(){
        auto tupleEvent = this.SDLPollEvent();
        SDL_Event event = tupleEvent[0];
        while(tupleEvent[1]){
            scope(exit){
                tupleEvent = this.SDLPollEvent();
                event = tupleEvent[0];
            }

            WMEvent tmp;
            uint winID;
            if(event.type == SDL_MOUSEMOTION){
                tmp.type = EventType.mouseMotion;
                tmp.motion = MouseMotionEvent(
                    event.motion.timestamp,
                    event.motion.which,
                    event.motion.state,
                    vec2!int([event.motion.x,event.motion.y]),
                    vec2!int([event.motion.xrel,event.motion.yrel])
                );
                winID = event.motion.windowID;
            }
            else if(event.type == SDL_MOUSEBUTTONDOWN || event.type == SDL_MOUSEBUTTONUP){
                tmp.type = event.type == SDL_KEYDOWN? EventType.mouseButtonDown: EventType.mouseButtonUp;
                tmp.mouse = MouseButtonEvent(
                    event.button.timestamp,
                    event.button.which,
                    event.button.button,
                    event.button.state,
                    vec2!int([event.button.x,event.button.y])
                );
                winID = event.button.windowID;
            }
            else if(event.type == SDL_KEYDOWN || event.type == SDL_KEYUP){
                tmp.type = event.type == SDL_KEYDOWN? EventType.keyDown: EventType.keyUp;
                tmp.key = KeyboardEvent(
                    event.key.timestamp,
                    event.key.state,
                    event.key.repeat,
                    Keysym(
                        cast(ushort)event.key.keysym.scancode,
                        cast(ushort)event.key.keysym.sym,
                        event.key.keysym.mod,
                    )
                );
                winID = event.key.windowID;
            }
            else if(event.type == SDL_TEXTINPUT){
                tmp.type = EventType.textInput;
                tmp.text = TextInputEvent(
                    event.text.timestamp,
                    event.text.text
                );
                winID = event.key.windowID;
            }
            else if(event.type == SDL_WINDOWEVENT){
                tmp.type = EventType.windowEvent;
                tmp.window = WindowEvent(
                    event.window.timestamp,
                    cast(WindowEventID)cast(uint)event.window.event,
                    event.window.data1,
                    event.window.data2
                );

                winID = event.key.windowID;
            }
            else if(event.type == SDL_QUIT){
                tmp.type = EventType.quit;
                winID = event.key.windowID;
            }
            else {
                debug{
                    import quickd.core.logger: globalLogger, LogMessage;
                    import std.conv: to;

                    LogMessage message = LogMessage();
                    message.message = "Unknown window event type";
                    message.status = message.Status.debugging;
                    message.event = event.type.to!string;

                    globalLogger.log(message);
                }
                continue;
            }
            if(winID == 0) continue;
            auto dg = winID in listWindows;
            if(dg !is null)
                (*dg)(tmp);
        }
    }
    ~this(){
        this.system = null;
    }

private:

    Tuple!(SDL_Event, bool) SDLPollEvent(){
        SDL_Event event;
        bool isEvent;
        synchronized(this){
            isEvent = cast(bool)SDL_PollEvent(&event);
        }
        return tuple(event, isEvent);
    }
    static WMEventSystem system;
    static void delegate(WMEvent)[uint] listWindows;
    bool textInput;
}

byte ToScanCode(string str)() pure @nogc
if(str.length > 0)
{
    byte code;
    static if(str.length == 1){
        static if(str[0] >= 'a' && str[0] <= 'z')
            code = cast(byte)(str[0] - 'a' + 4);
        else static if(str[0] >= 'A' && str[0] <= 'Z')
            code = cast(byte)(str[0] - 'A' + 4);
        else static if(str[0] >= '0' && str[0] <= '9')
            code = cast(byte)(str[0] - '0' + 30);
        else static if(str[0] >= '0' && str[0] <= '9')
            code = cast(byte)(str[0] - '0' + 30);
        else static if(str[0] == '-')
            code = SDL_SCANCODE_MINUS;
        else static if(str[0] == '=')
            code = SDL_SCANCODE_EQUALS;
        else assert(false, "Unknown scancode");
    }
    else static if(str == "Left Shift")
        code = SDL_SCANCODE_LSHIFT;

    else static if(str == "Right Shift")
        code = SDL_SCANCODE_RSHIFT;

    else static if(str == "Left Ctrl")
        code = SDL_SCANCODE_LCTRL;

    else static if(str == "Right Ctrl")
        code = SDL_SCANCODE_LCTRL;
    else static if(str == "Backspace")
            code = SDL_SCANCODE_BACKSPACE;
    else static if(str == "Return")
            code = SDL_SCANCODE_RETURN;
    else static if(str == "Return2")
            code = SDL_SCANCODE_RETURN2;
    else assert(false, "Unknown scancode");

    return code;
}