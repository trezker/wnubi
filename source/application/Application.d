module application.Application;

import std.stdio;
import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.Ajax;
import boiler.Get;
import boiler.HttpRequest;

import application.Database;
import application.storage.user;
import application.storage.world;
import application.CreateUser;
import application.Login;
import application.Logout;
import application.CurrentUser;
import application.GetMap;
import application.CreateWorld;
import application.UpdateWorld;
import application.ListWorlds;

class Application {
	void SetupActions(Ajax ajax, Get get) {
		Database database = GetDatabase(null);
		auto userStorage = new User_storage(database);
		auto worldStorage = new World_storage(database);

		ajax.SetActionCreator("CreateUser", () => new CreateUser(userStorage));
		ajax.SetActionCreator("Login", () => new Login(userStorage));
		ajax.SetActionCreator("Logout", () => new Logout);
		ajax.SetActionCreator("CurrentUser", () => new CurrentUser(userStorage));

		ajax.SetActionCreator("CreateWorld", () => new CreateWorld(worldStorage));
		ajax.SetActionCreator("UpdateWorld", () => new UpdateWorld(worldStorage));
		ajax.SetActionCreator("ListWorlds", () => new ListWorlds(worldStorage));

		get.SetActionCreator("GetMap", () => new GetMap);
	}

	string RewritePath(HttpRequest request) {
		//writeln(request.path);
		if(!request.session && request.path != "/test" && request.path != "/map") {
			return "/login";
		}
		return request.path;
	}
}
