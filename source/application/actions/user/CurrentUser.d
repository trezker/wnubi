module application.CurrentUser;

import std.stdio;
import vibe.http.server;
import vibe.data.bson;

import boiler.ActionTester;
import boiler.testsuite;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.storage.user;

import std.typecons;

class CurrentUser: Action {
	User_storage user_storage;

	this(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	HttpResponse Perform(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		try {
			string username = "";
			if(request.session) {
				auto id = request.session.get!string("id");
				auto user = user_storage.UserById(id);
				username = user["username"].get!string;
			}

			Json json = Json.emptyObject;
			json["success"] = true;
			json["username"] = username;
			response.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			response.writeBody(serializeToJsonString(json), 200);
		}
		return response;
	}
}

//CurrentUser should return the name of logged in user
unittest {
	import application.testhelpers;
	import application.Database;

	Database database = GetDatabase("test");
	
	try {
		string username = "testname";
		CreateTestUser(username, "testpass");
		auto tester = TestLogin(username, "testpass");

		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		tester.Request(&currentUser.Perform);
		
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		assertEqual(jsonoutput["username"].to!string, username);
	}
	finally {
		database.ClearCollection("user");
	}
}

//CurrentUser should give no name if not logged in
unittest {
	import application.testhelpers;
	import application.Database;
	import application.Login;

	Database database = GetDatabase("test");
	
	try {
		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		ActionTester tester = new ActionTester(&currentUser.Perform);
		
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		assertEqual(jsonoutput["username"].to!string, "");
	}
	finally {
		database.ClearCollection("user");
	}
}
