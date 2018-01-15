module application.Login;

import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.ActionTester;
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

//Login user without parameters should fail
unittest {
	Database database = GetDatabase("test");
	
	try {
		Login m = new Login(new User_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user that doesn't exist should fail
unittest {
	Database database = GetDatabase("test");
	
	try {
		auto tester = TestLogin("testname", "testpass");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user with correct parameters should succeed and set user id in session
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		CreateTestUser("testname", "testpass");

		auto tester = TestLogin("testname", "testpass");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		string id = tester.GetResponseSessionValue!string("id");
		assertNotEqual(id, "");
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user with incorrect password should fail
unittest {
	import application.testhelpers;

	Database database = GetDatabase("test");
	
	try {
		CreateTestUser("testname", "testpass");

		auto tester = TestLogin("testname", "wrong");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}
	finally {
		database.ClearCollection("user");
	}
}
