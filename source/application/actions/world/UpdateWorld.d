module application.UpdateWorld;

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

class UpdateWorld: Action {
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
			World world = deserialize!(JsonSerializer, World)(request.json);

			world_storage.Update(world);

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

		AddTest(&Update_world_without_parameters_should_fail);
		AddTest(&Update_world_with_parameters_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("world");
	}


	void Update_world_without_parameters_should_fail() {
		UpdateWorld m = new UpdateWorld(new World_storage(database));

		ActionTester tester = new ActionTester(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Update_world_with_parameters_should_succeed() {
		auto world_storage = new World_storage(database);

		NewWorld world = {
			name: "A",
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0,
			spawnpoints: [
				{
					coordinates: {1.0, 2.0}
				}
			]
		};

		world_storage.Create(world);
		auto obj = world_storage.List();
		BsonObjectID oid = obj[0]._id;
		string sid = oid.toString();

		UpdateWorld m = new UpdateWorld(world_storage);
		Json jsoninput = Json.emptyObject;
		jsoninput["_id"] = sid;
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
//	test.Run();
}