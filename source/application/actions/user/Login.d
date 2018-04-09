module application.Login;

import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.ActionTester;
import application.testhelpers;
import boiler.testsuite;
import boiler.helpers;
import application.storage.user;
import application.Database;
import application.testhelpers;

class Login: Action {
	User_storage user_storage;

	this(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	bool HasAccess(HttpRequest req) {
		return true;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			//Read parameters
			string username = req.json["username"].to!string;
			string password = req.json["password"].to!string;

			//Get user
			auto obj = user_storage.UserByName(username);
			if(obj == Bson(null)) {
				Json json = Json.emptyObject;
				json["success"] = false;
				json["info"] = "Invalid login";
				res.writeBody(serializeToJsonString(json), 200);
				return res;
			}

			//Verify password
			if(!isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string))) {
				Json json = Json.emptyObject;
				json["success"] = false;
				json["info"] = "Invalid login password";
				res.writeBody(serializeToJsonString(json), 200);
				return res;
			}

			//Initiate session
			auto session = req.StartSession();
			BsonObjectID oid = obj["_id"].get!BsonObjectID;
			string userID = oid.toString();
			session.set("id", userID);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//Write result
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

		AddTest(&Login_user_without_parameters_should_fail);
		AddTest(&Login_user_that_doesnt_exist_should_fail);
		AddTest(&Login_user_with_correct_parameters_should_succeed_and_set_user_id_in_session);
		AddTest(&Login_user_with_incorrect_password_should_fail);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("user");
	}

	void Login_user_without_parameters_should_fail() {
		Login m = new Login(new User_storage(database));

		ActionTester tester = new ActionTester(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Login_user_that_doesnt_exist_should_fail() {
		auto tester = TestLogin(database, "testname", "testpass");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Login_user_with_correct_parameters_should_succeed_and_set_user_id_in_session() {
		CreateTestUser(database, "testname", "testpass");

		auto tester = TestLogin(database, "testname", "testpass");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		string id = tester.GetResponseSessionValue!string("id");
		assertNotEqual(id, "");
	}

	void Login_user_with_incorrect_password_should_fail() {
		CreateTestUser(database, "testname", "testpass");

		auto tester = TestLogin(database, "testname", "wrong");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}
