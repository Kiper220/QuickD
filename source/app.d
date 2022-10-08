import quickd;

int main(){
	debug {}
	else{
		version(Windows){
			import core.sys.windows.windows;
			ShowWindow(GetConsoleWindow(), SW_HIDE);
		}
	}
	try start();
	catch(Exception exc){
		LogMessage message = LogMessage();
		message.message = "Application crashed";
		message.status = LogMessage.Status.fatal;
		message.exception = exc.toString;

		globalLogger.log(message);
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

	/// Create Renderer
	Renderer renderer = new Renderer(window);

	/// Create shader program
	ShaderProgram program = renderer.createShaderProgram();
	{
		Shader fragment = renderer.createFragmentShader();
		Shader vertex = renderer.createVertexShader();
		vertex.setShader(vshader);
		fragment.setShader(fshader);
		vertex.buildShader();
		fragment.buildShader();

		program.bindFragmentShader(fragment);
		program.bindVertexShader(vertex);
		program.link();
	}

	/// Create mesh
	Triangle[2] tr =
		[
			[
				Vector3!float([-1f, -1f, 0.0f]),
				Vector3!float([1f, -1f, 0.0f]),
				Vector3!float([-1f, 1f, 0.0f]),
			],
			[
				Vector3!float([-1f, 1f, 0.0f]),
				Vector3!float([1f,  1f, 0.0f]),
				Vector3!float([1f, -1f, 0.0f])
			]
		];
	TextureCoordinate[2] tc =
		[
			[
				Vector2!float([0f,1f]),
				Vector2!float([1f,1f]),
				Vector2!float([0f,0f]),
			],
			[
				Vector2!float([0f,0f]),
				Vector2!float([1f,0f]),
				Vector2!float([1f,1f]),
			]
		];
	Mesh mesh = new Mesh(tr);

	/// Create model
	Model model = renderer.createModel();
	model.setShaderProgram(program);
	model.setMesh(mesh);
	model.setTextCord(tc);

	Texture texture = renderer.createTexture();
	texture.loadTexture("./resource/images/test.bmp");

	model.setTexture("tex", texture);
	/// Show Window.
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
	window.show();

	while(!close){
		renderer.clear();
		renderer.draw();
		model.render();

		window.swap();
		system.pollAllEvents();
	}
}
