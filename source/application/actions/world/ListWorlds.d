module application.ListWorlds;

import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.world;

class ListWorlds: Action {
	World_storage world_storage;

	this(World_storage world_storage) {
		this.world_storage = world_storage;
	}

	bool HasAccess(HttpRequest req) {
		return true;
	}

	HttpResponse Perform(HttpRequest request) {
		HttpResponse res = new HttpResponse;
		try {
			World[] worlds = world_storage.List();

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			json["worlds"] = serialize!(JsonSerializer, World[])(worlds);
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

		AddTest(&List_worlds_should_list_all_worlds);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("world");
	}

	void List_worlds_should_list_all_worlds() {
		auto world_storage = new World_storage(database);

		NewWorld world = {
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0
		};

		world_storage.Create(world);
		world_storage.Create(world);

		ListWorlds m = new ListWorlds(world_storage);

		ActionTester tester = new ActionTester(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
		World[] worlds = deserialize!(JsonSerializer, World[])(jsonoutput["worlds"]);
		assertEqual(worlds.length, 2);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}