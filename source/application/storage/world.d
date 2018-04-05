module application.storage.world;

import std.conv;
import std.stdio;
import std.algorithm;
import std.exception;
import vibe.db.mongo.mongo;
import vibe.data.bson;

import boiler.helpers;
import boiler.testsuite;
import application.Database;
import application.data;

struct NewWorld {
	int seed;
	string name;
	double perlinScale;
	int octaves;
	double persistence;
	double lacunarity;
	SpawnPoint[] spawnpoints;
}

struct World {
	BsonObjectID _id;
	string name;
	int seed;
	double perlinScale;
	int octaves;
	double persistence;
	double lacunarity;
	SpawnPoint[] spawnpoints;
}

struct SpawnPoint {
	Coordinates coordinates;
}

class World_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("world");
	}

	void Create(NewWorld world) {
		try {
			collection.insert(world);
		}
		catch(Exception e) {
			//if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			//}
			throw e;
		}
	}

	void Update(World world) {
		auto selector = Bson(["_id": Bson(world._id)]);
		auto update = Bson([
			"$set": world.serializeToBson()
		]);
		collection.update(selector, update);
	}

	void Delete(BsonObjectID worldId) {
		collection.remove(Bson(["_id": Bson(worldId)]));
	}

	World ById(string id) {
		BsonObjectID oid = BsonObjectID.fromString(id);
		auto conditions = Bson(["_id": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		World world = deserialize!(BsonSerializer, World)(obj);
		return world;
	}

	World[] List() {
		return MongoArray!(World)(collection);
	}
}

class Test : TestSuite {
	Database database;
	World_storage world_storage;

	this() {
		database = GetDatabase("test");
		world_storage = new World_storage(database);
		
		AddTest(&Create_world);
		AddTest(&Find_by_id);
		AddTest(&Update_should_work);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("world");
	}

	void Create_world() {
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

		assertNotThrown(world_storage.Create(world));
	}

	void Find_by_id() {
		NewWorld world = {
			name: "A",
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0
		};

		world_storage.Create(world);
		auto obj = world_storage.List();
		BsonObjectID oid = obj[0]._id;
		string sid = oid.toString();
		auto world2 = world_storage.ById(sid);
		assertEqual(world2.seed, 1);
	}

	void Update_should_work() {
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
		obj[0].seed = 2;
		world_storage.Update(obj[0]);

		auto obj2 = world_storage.List();
		assertEqual(obj2[0].seed, 2);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}