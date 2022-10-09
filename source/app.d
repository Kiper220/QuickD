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
Shader shader;
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
	Mesh mesh1;
	Mesh mesh2;
	mesh1.vertexArray = [
		vec3!float(1.92, 1.08, 0),
		vec3!float(1.92, -1.08, 0),
		vec3!float(-1.92, 1.08, 0),
		vec3!float(-1.92, -1.08, 0),
	];
	mesh1.indexBuffer = [0, 1, 2, 1, 2, 3];
	mesh1.uvArray = [
		vec2!float(0f, 0f),
		vec2!float(0f, 1f),
		vec2!float(1f, 0f),
		vec2!float(1f, 1f),
	];
	mesh2.vertexArray = [
		vec3!float(1, 1, 0),
		vec3!float(1, -1, 0),
		vec3!float(-1, 1, 0),
		vec3!float(-1, -1, 0),
	];
	mesh2.indexBuffer = [0, 1, 2, 1, 2, 3];
	mesh2.uvArray = [
		vec2!float(1f, 0f),
		vec2!float(1f, 1f),
		vec2!float(0f, 0f),
		vec2!float(0f, 1f),
	];

	shader = renderer.createShader();
	shader.setVertexShader(vshader);
	shader.setFragmentShader(fshader);

	shader.compile();

	Texture texture1 = renderer.createTexture();
	Texture texture2 = renderer.createTexture();
	texture1.loadTexture("resource/images/test.png");
	texture2.loadTexture("resource/images/jar.jpg");

	Material mat1 = renderer.createMaterial();
	Material mat2 = renderer.createMaterial();
	mat1.setShader(shader);
	mat1.addTexture("test", texture1);
	mat2.setShader(shader);
	mat2.addTexture("test", texture2);

	Model model1 = renderer.createModel();
	Model model2 = renderer.createModel();
	model1.setMesh(mesh1);
	model1.setMaterial(mat1);
	model2.setMesh(mesh2);
	model2.setMaterial(mat2);

	Actor actor1 = new Actor;
	Actor actor2 = new Actor;
	actor1.setModel(model1);
	actor2.setModel(model2);

	Level level = new Level;
	level.addActor("root1", actor1);
	level.addActor("root2", actor2);

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
