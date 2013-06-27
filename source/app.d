import vibe.d;

import std.algorithm: remove, countUntil;
import std.stdio: writeln;


class WebApplication {
	private {
		WebChat webchat;
	}

	this(URLRouter router) {
		webchat = new WebChat();

		router.get("/", &chat);
		router.get("/login", &logout);
		router.post("/login", &login);
		router.get("/ws", &webchat.wsHandler);
		router.get("/static/*", serveStaticFiles("./static/", new HTTPFileServerSettings("/static/")));
	}

	private void chat(HTTPServerRequest req, HTTPServerResponse res) {
		if (!req.session) {
			res.redirect("/login");
		}
		res.renderCompat!("chat.dt", HTTPServerRequest, "req")(req);
	}

	private void logout(HttpServerRequest req, HttpServerResponse res) {
		if (req.session) {
			res.terminateSession();
		}
		res.renderCompat!("login.dt")();
	}

	private void login(HttpServerRequest req, HttpServerResponse res) {
		auto session = res.startSession();
		session["username"] = req.form["username"];
		res.redirect("/");
	}

	private class WebChat {
		private {
			WebSocket[] userSockets;
		}

		private void wsHandler(HttpServerRequest req, HttpServerResponse res) {
			auto callback = handleWebSockets((socket) {
				userSockets ~= socket;
				while( socket.connected ) {
					if( socket.dataAvailableForRead() ) {
						auto data = socket.receive();
						synchronized {
							foreach (sock; userSockets) {
								if (sock != socket) 
									sock.send(cast(string)data);
							}
						}
					}		
				}
				userSockets = userSockets.remove(userSockets.countUntil(socket));		
			});
			callback(req, res);
		}
	}
}


shared static this() {
	auto router = new URLRouter;
	auto app = new WebApplication(router);
	
	auto settings = new HTTPServerSettings;
	settings.sessionStore = new MemorySessionStore();
	settings.port = 8080;
	
	listenHTTP(settings, router);	
}
