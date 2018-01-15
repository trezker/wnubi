module application.Application;

import std.stdio;
import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.Ajax;
import boiler.HttpRequest;

import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.Logout;
import application.CurrentUser;

class Application {
	void SetupAjaxMethods(Ajax ajax) {
		Database database = GetDatabase(null);
		auto userStorage = new User_storage(database);

		ajax.SetActionCreator("CreateUser", () => new CreateUser(userStorage));
		ajax.SetActionCreator("Login", () => new Login(userStorage));
		ajax.SetActionCreator("Logout", () => new Logout);
		ajax.SetActionCreator("CurrentUser", () => new CurrentUser(userStorage));
	}

	string RewritePath(HttpRequest request) {
		//writeln(request.path);
		if(!request.session && request.path != "/test") {
			return "/login";
		}
		return request.path;
	}
}
