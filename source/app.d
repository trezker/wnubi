import std.functional;
import core.stdc.stdlib;
import vibe.appmain;
import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.fileserver;
import vibe.http.websockets : handleWebSockets;
import std.file;
import std.json;
import std.conv;

import boiler.server;

shared static this() {
	auto server = new Server;

	runTask({
		if(!server.Setup()) {
			exit(-1);
		}
	});
	runTask({
		server.Daemon();
	});

	ushort port = 8080;
	if(exists("config.json")) {
		string json = readText("config.json");
		JSONValue[string] document = parseJSON(json).object;
		port = to!ushort(document["port"].integer);
	}
	
	auto settings = new HTTPServerSettings;
	settings.port = port;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	settings.errorPageHandler = toDelegate(&server.Error);
	settings.sessionStore = new MemorySessionStore;

	auto router = new URLRouter;
	router.post("/ajax*", &server.PerformAjax);
	router.get("/get*", &server.PerformGet);
	router.get("/ws", handleWebSockets(&server.Websocket));
	router.get("/source/*", serveStaticFiles("./public/"));
	router.get("/*", &server.Page);

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
