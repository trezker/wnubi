module application.CreateWorld;

import std.stdio;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.storage.world;

class CreateWorld: Action {
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
			NewWorld world = deserialize!(JsonSerializer, NewWorld)(request.json);

			world_storage.Create(world);

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

		AddTest(&Create_world_without_parameters_should_fail);
		AddTest(&Create_world_with_parameters_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("world");
	}


	void Create_world_without_parameters_should_fail() {
		CreateWorld m = new CreateWorld(new World_storage(database));

		ActionTester tester = new ActionTester(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Create_world_with_parameters_should_succeed() {
		CreateWorld m = new CreateWorld(new World_storage(database));
		Json jsoninput = Json.emptyObject;
		jsoninput["name"] = "A";
		jsoninput["seed"] = 0;
		jsoninput["perlinScale"] = 1.0;
		jsoninput["octaves"] = 1;
		jsoninput["persistence"] = 1.0;
		jsoninput["lacunarity"] = 1.0;
		jsoninput["spawnpoints"] = Json.emptyArray;

		ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput), "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}