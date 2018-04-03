module application.CreateCharacter;

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
import application.storage.world;

class CreateCharacter: Action {
	Character_storage character_storage;
	World_storage world_storage;

	this(Character_storage character_storage, World_storage world_storage) {
		this.character_storage = character_storage;
		this.world_storage = world_storage;
	}

	bool HasAccess(HttpRequest req) {
		return true;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			string worldId = req.json["worldId"].to!string;

			World world = world_storage.ById(worldId);
			writeln(world);

			auto latitude = world.spawnpoints[0].coordinates.latitude;
			auto longitude = world.spawnpoints[0].coordinates.longitude;
			NewCharacter character = {
				coordinates: {latitude, longitude}
			};
			character_storage.Create(character);

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
	Character_storage character_storage;
	World_storage world_storage;

	this() {
		database = GetDatabase("test");
		character_storage = new Character_storage(database);
		world_storage = new World_storage(database);

		AddTest(&Create_character_without_parameters_should_fail);
		AddTest(&Create_character_with_parameters_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("user");
		database.ClearCollection("world");
	}


	void Create_character_without_parameters_should_fail() {
		CreateCharacter m = new CreateCharacter(character_storage, world_storage);

		ActionTester tester = new ActionTester(&m.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Create_character_with_parameters_should_succeed() {
		CreateCharacter m = new CreateCharacter(character_storage, world_storage);

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

		Json jsoninput = Json.emptyObject;
		jsoninput["worldId"] = obj[0]._id.toString();

		ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput), "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}