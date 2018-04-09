module application.CurrentUser;

import std.stdio;
import vibe.http.server;
import vibe.data.bson;

import application.testhelpers;
import application.Database;
import application.Login;
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

	bool HasAccess(HttpRequest req) {
		return true;
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

class Test : TestSuite {
	Database database;

	this() {
		database = GetDatabase("test");

		AddTest(&CurrentUser_should_return_the_name_of_logged_in_user);
		AddTest(&CurrentUser_should_give_no_name_if_not_logged_in);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("user");
	}

	void CurrentUser_should_return_the_name_of_logged_in_user() {
		string username = "testname";
		CreateTestUser(database, username, "testpass");
		auto tester = TestLogin(database, username, "testpass");

		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		tester.Request(&currentUser.Perform, "");
		
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		assertEqual(jsonoutput["username"].to!string, username);
	}

	void CurrentUser_should_give_no_name_if_not_logged_in() {
		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		ActionTester tester = new ActionTester(&currentUser.Perform, "");
		
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		assertEqual(jsonoutput["username"].to!string, "");
	}
}

unittest {
	auto test = new Test;
	test.Run();
}