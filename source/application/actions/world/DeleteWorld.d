module application.DeleteWorld;

import std.stdio;
import std.datetime;
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
import application.testhelpers;

class DeleteWorld: Action {
	World_storage world_storage;

	this(World_storage world_storage) {
		this.world_storage = world_storage;
	}

	HttpResponse Perform(HttpRequest request) {
		HttpResponse res = new HttpResponse;
		try {
			BsonObjectID worldId = BsonObjectID.fromString(request.json["worldId"].to!string);

			world_storage.Delete(worldId);

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//Write result
			//writeln(e);
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

		AddTest(&Delete_world_without_parameters_should_fail);
		AddTest(&Delete_world_with_all_parameters_should_succeed_and_the_world_should_not_exist_after);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("world");
	}

	void Delete_world_without_parameters_should_fail() {
		DeleteWorld m = new DeleteWorld(new World_storage(database));
		ActionTester tester = new ActionTester(&m.Perform, "");

		Json json = tester.GetResponseJson();
		assertEqual(json["success"].to!bool, false);
	}

	void Delete_world_with_all_parameters_should_succeed_and_the_world_should_not_exist_after() {
		auto world_storage = new World_storage(database);
		
		NewWorld world = {
			name: "A",
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0
		};
		world_storage.Create(world);

		auto worlds = world_storage.List();

		Json jsoninput = Json(["worldId": Json(worlds[0]._id.toString())]);
		DeleteWorld m = new DeleteWorld(new World_storage(database));
		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);

		auto worldsAfterDelete = world_storage.List();

		//writeln(events);
		assertEqual(0, worldsAfterDelete.length);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}