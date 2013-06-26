import vibe.d;

void index(HTTPServerRequest req, HTTPServerResponse res) {
	res.renderCompat!("index.dt", HTTPServerRequest, "req")(req);
}

void handleRequest(WebSocket socket) {
	while( socket.connected ) {
		if( socket.dataAvailableForRead() ) {
			auto data = socket.receive();
			socket.send(cast(string) data);
		}
	}
}

shared static this() {
	auto router = new URLRouter;
	router.get("/", &index);
	router.get("/ws", handleWebSockets(&handleRequest));
	router.get("/static/*", serveStaticFiles("./static/", new HTTPFileServerSettings("/static/")));

	auto settings = new HTTPServerSettings;
	settings.port = 8000;

	listenHTTP(settings, router);
}
