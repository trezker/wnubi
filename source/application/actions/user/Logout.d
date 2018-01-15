module application.Logout;

import std.stdio;
import vibe.http.server;
import vibe.data.json;

import boiler.ActionTester;
import boiler.testsuite;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

import application.Database;
import application.storage.user;
import application.testhelpers;

class Logout: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			req.TerminateSession();

			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

class Test : TestSuite {
	Database database;

	this() {
		database = GetDatabase("test");

		AddTest(&Logout_should_succeed_and_session_should_not_contain_a_user_id);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("user");
	}

	void Logout_should_succeed_and_session_should_not_contain_a_user_id() {
		CreateTestUser("testname", "testpass");

		auto tester = TestLogin("testname", "testpass");

		Logout logoutHandler = new Logout();
		tester.Request(&logoutHandler.Perform);
		
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		string id = tester.GetResponseSessionValue!string("id");
		assertEqual(id, "");
	}
}

unittest {
	auto test = new Test;
	test.Run();
}