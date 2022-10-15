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

void start(){
	import quickd;
	import std.stdio;
	Level2D level = new Level2D;
	Actor2D actor1 = new Actor2D;
	Actor2D actor2 = new Actor2D;
	Actor2D actor3 = new Actor2D;
	Actor2D actor4 = new Actor2D;
	Actor2D actor5 = new Actor2D;

	level.addActor2D("actor1", actor1);
	actor1.addActor2D("actor54", actor2);
	actor1.addActor2D("actor45", actor3);
	actor3.addActor2D("actor23", actor4);
	actor4.addActor2D("actor23", actor5);

	actor4.position = vec2!float([5f, 0]);
	foreach(i; 0..180){
		actor1.rotation = i;
	}

}