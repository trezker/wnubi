module application.ListCharacters;

import std.stdio;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.character;
import application.testhelpers;

class ListCharacters: Action {
	Character_storage character_storage;

	this(Character_storage character_storage) {
		this.character_storage = character_storage;
	}

	bool HasAccess(HttpRequest req) {
		return true;
	}

	HttpResponse Perform(HttpRequest request) {
		HttpResponse res = new HttpResponse;
		try {
			auto id = request.session.get!string("id");
			Character[] characters = character_storage.ByUser(id);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			json["characters"] = serialize!(JsonSerializer, Character[])(characters);
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			writeln(e);
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

		AddTest(&List_characters_should_list_all_characters_for_user);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("character");
	}

	void List_characters_should_list_all_characters_for_user() {
		string username = "testname";
		CreateTestUser(database, username, "testpass");
		auto tester = TestLogin(database, username, "testpass");
		string userId = tester.GetResponseSessionValue!string("id");

		auto character_storage = new Character_storage(database);

		NewCharacter character = {
			userId: BsonObjectID.fromString(userId),
			coordinates: {1.0, 2.0}
		};

		character_storage.Create(character);
		character_storage.Create(character);

		ListCharacters m = new ListCharacters(character_storage);

		tester.Request(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		Character[] characters = deserialize!(JsonSerializer, Character[])(jsonoutput["characters"]);
		assertEqual(characters.length, 2);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}