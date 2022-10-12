import quickd;

shared static this() {
	import core.stdc.signal;
	nothrow @nogc @system
	extern(C) void handleSegv(int) {
		assert(false, "Segmentation fault.");
	}
	signal(SIGSEGV, &handleSegv);
}

int main(){
	debug {}
	else{
		version(Windows){
			import core.sys.windows.windows;
			ShowWindow(GetConsoleWindow(), SW_HIDE);
		}
	}

	try {
		start();
	}
	catch(Throwable th){
		LogMessage message = LogMessage();
		message.message = "Application crashed";
		message.status = LogMessage.Status.fatal;
		message.exception = th.toString;

		globalLogger.log(message);
		version(Windows){
			import std.stdio;
			writeln("To finish, press enter: ");
			readf("\n");
		}
		return 231;
	}
	return 0;
}

bool close;

void applicationClose(WMEvent event){
	if(event.type == EventType.windowEvent && event.window.event == WindowEventID.close){
		close = true;
	}
	if(event.type == EventType.windowEvent && event.window.event == WindowEventID.resised){
		import bindbc.opengl;
		glViewport(0, 0, event.window.data1, event.window.data2);

		//import gfm.math.matrix;
		//shader.setProjection(mat4!float.orthographic());
		//
	}
}
void polyView(WMEvent event){
	static int state;
	import bindbc.opengl;
	if(event.key.sym.scanCode == ToScanCode!"P" && !event.key.repeat){
		switch(state){
			case 0:
				state++;
				glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
				break;

			case 1:
				state++;
				glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
				break;
			case 2:
				state = 0;
				glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
				break;
			default:
				state = 0;
				break;
		}
	}
}
string fshader = import("shaders/default/image.frag");
string vshader = import("shaders/default/image.vert");

void start() {
	import std.conv: to;
	import std.stdio;
	import std.functional;
	import std.datetime;

	/// Get WMEventSystem instance for poll events.
	WMEventSystem system = WMEventSystem.getInstance();
	/// Create window, add event to window.
	Window window = new Window;
	window.addEvent(EventType.windowEvent, "applicationClose", toDelegate(&applicationClose));
	window.addEvent(EventType.keyDown, "polyView", toDelegate(&polyView));
	Renderer renderer = new Renderer(window);
	renderer.setView(ViewSettings.windowSizedView);


	Font font = renderer.createFont();
	Text text = renderer.createText();
	//font.setFont("resource/fonts/fifaks 1.0 dev1/Fifaks10Dev1.ttf");
	font.setFont("/usr/share/fonts/noto/NotoSerif-Regular.ttf");

	font.setFontSize(50);

	text.setFont(font);
	font.loadChars("hg");
	text.setText("Привет мир!");

	Level level = new Level;
	Actor actor = new Actor;
	actor.setRenderable(text);
	/*Sprite sp = new Sprite(renderer.getRenderAPI);
	sp.position = [0,0,0.0001f];
	sp.setImage("resource/images/kor.jpg");*/

	level.addActor("sprite1", actor);

	renderer.setLevel(level);

	/// Log memory usage.
	{
		import core.memory;
		GC.collect();
		float used = cast(float)GC.stats.usedSize / 1024f / 1024f;

		LogMessage message = LogMessage();
		message.message = "Init memory usage";
		message.status = LogMessage.Status.trace;
		message.used = used.to!string ~ "MB";
		globalLogger.log(message);
	}
	/// Show Window.
	window.show();
	auto time = Clock.currTime();
	float secs = 0;


	while(!close){
		secs += (Clock.currTime() - time).total!"nsecs" / 1_000_000_000f;
		time = Clock.currTime();
		renderer.render();

		window.swap();
		system.pollAllEvents();
	}
}
