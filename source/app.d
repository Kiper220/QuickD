import std.stdio;
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
	import quickd;
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
vec3!float[] vertexArray = [
	vec3!float(1, -1, 0),
	vec3!float(1, 0, 0),
	vec3!float(0, -1, 0),
	vec3!float(0, 0, 0),
];
uint[] indexBuffer = [0, 1, 2, 1, 2, 3];
vec2!float[] uvArray = [
	vec2!float(1f, 1f),
	vec2!float(1f, 0f),
	vec2!float(0f, 1f),
	vec2!float(0f, 0f),
];

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

void start(){
	import std.conv: to;
	import std.stdio;
	import std.functional;
	/// Get WMEventSystem instance for poll events.
	WMEventSystem system = WMEventSystem.getInstance();

	Window window = new Window;
	window.addEvent(EventType.windowEvent, "applicationClose", toDelegate(&applicationClose));
	window.addEvent(EventType.keyDown, "polyView", toDelegate(&polyView));

	RenderAPI api = createOpenGLAPI();
	Renderer renderer = new Renderer;
	renderer.setRenderApi(api);
	renderer.setWindow(window);

	Level2D level = new Level2D;
	Actor2D actor1 = new Actor2D;
	Actor2D actor2 = new Actor2D;
	Actor2D actor3 = new Actor2D;

	RenderAPI renderAPI = createOpenGLAPI();


	Text 		text1 		= api.createText();
	Text 		text2 		= api.createText();
	Font 		font		= api.createFont();
	Font 		font2		= api.createFont();
	Shader 		shader		= api.createShader();
	Texture 	texture 	= api.createTexture();
	Material 	material 	= api.createMaterial();
	Mesh		mesh 		= api.createMesh();
	Model 		model 		= api.createModel();

	shader.setFragmentShader(import("shaders/gl20/default/image.frag"));
	shader.setVertexShader(import("shaders/gl20/default/image.vert"));
	shader.compile();

	texture.loadTexture("resource/images/kor.jpg");
	material.setShader(shader);
	material.addTexture("test", texture);
	{
		auto texture_size = texture.getSize();
		material.setVector3Parametr("size", vec3!float(texture_size.x, texture_size.y, 1));
	}

	mesh.setVertexArray(vertexArray);
	mesh.setUVArray(uvArray);
	mesh.setIndexBuffer(indexBuffer);

	model.setMesh(mesh);
	model.setMaterial(material);

	font.setFont("resource/fonts/fifaks 1.0 dev1/Fifaks10Dev1.ttf");
	font2.setFont("resource/fonts/fifaks 1.0 dev1/Fifaks10Dev1.ttf");

	font.setFontSize(40);
	font2.setFontSize(40);

	text1.setFont(font);
	text2.setFont(font2);
	text1.setText("ОЛЕГ, МЫ ЭТО СДЕЛАЛИ!!!! *плак*плак*");

	actor1.setRenderable(model);
	actor2.setRenderable(text1);
	actor3.setRenderable(text2);

	level.addActor2D("actor1", actor1);
	level.addActor2D("actor2", actor2);
	level.addActor2D("fps", actor3);

	actor2.position = vec2!float([20f, 0]);
	actor2.rotation = 45f;

	renderer.setLevel(level);

	window.show();

	import std.datetime;

	auto start = Clock.currTime();
	float min = 10000;
	float max;
	float fps;
	while(!close){
		import std.format;
		system.pollAllEvents();

		text2.setText("%.1f".format(fps).to!dstring ~ "FPS");

		auto offsetSize = text2.getOffsetSize();
		actor3.position = vec2!float([window.getSize().x - offsetSize.x, 0]);
		renderer.render();

		fps = (1000f / (Clock.currTime() - start).total!"msecs");
		start = Clock.currTime();

		min = min < fps? min: fps;
		max = max > fps? max: fps;
	}
	writeln("Max fps: ", max);
	writeln("Min fps: ", min);
}