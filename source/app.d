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

string fshader = import("test_shaders/test1.frag");
string vshader = import("test_shaders/test1.vert");

void start() {
	import std.conv: to;
	import std.stdio;
	import std.functional;

	/// Get WMEventSystem instance for poll events.
	WMEventSystem system = WMEventSystem.getInstance();
	/// Create window, add event to window.
	Window window = new Window;
	window.addEvent(EventType.windowEvent, "applicationClose", toDelegate(&applicationClose));
	window.addEvent(EventType.keyDown, "polyView", toDelegate(&polyView));
	Renderer renderer = new Renderer(window);
	Mesh mesh;
	mesh.vertexArray = [
		Vector3!float([1f, 1f, 0f]),
		Vector3!float([1f, -1f, 0f]),
		Vector3!float([-1f, 1f, 0f]),
		Vector3!float([-1f, -1f, 0f]),
	];
	mesh.indexBuffer = [0, 1, 2, 1, 2, 3];
	mesh.uvArray = [
		Vector2!float([0f, 0f]),
		Vector2!float([0f, 1f]),
		Vector2!float([1f, 0f]),
		Vector2!float([1f, 1f]),
	];

	Shader shader = renderer.createShader();
	shader.setVertexShader(vshader);
	shader.setFragmentShader(fshader);

	shader.compile();

	Texture texture = renderer.createTexture();
	texture.loadTexture("resource/images/test.png");

	Material mat = renderer.createMaterial();
	mat.setShader(shader);

	Model model = renderer.createModel();
	model.setMesh(mesh);
	model.setMaterial(mat);

	Actor actor = new Actor;
	actor.setModel(model);
	Level level = new Level;
	level.addActor("root", actor);

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

	while(!close){
		renderer.render();
		window.swap();
		system.pollAllEvents();
	}
}
