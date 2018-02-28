module application.storage.world;

import std.conv;
import std.stdio;
import std.algorithm;
import std.exception;
import dauth;
import vibe.db.mongo.mongo;
import vibe.data.bson;

import boiler.helpers;
import boiler.testsuite;
import application.Database;

struct NewWorld {
	int seed;
	double perlinScale;
	int octaves;
	double persistence;
	double lacunarity;
}

struct World {
	BsonObjectID _id;
	int seed;
	double perlinScale;
	int octaves;
	double persistence;
	double lacunarity;
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
			collection.insert(
				Bson([
					"seed": Bson(world.seed),
					"perlinScale": Bson(world.perlinScale),
					"octaves": Bson(world.octaves),
					"persistence": Bson(world.persistence),
					"lacunarity": Bson(world.lacunarity)
				])
			);
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
			"$set": Bson([
				"seed": Bson(world.seed),
				"perlinScale": Bson(world.perlinScale),
				"octaves": Bson(world.octaves),
				"persistence": Bson(world.persistence),
				"lacunarity": Bson(world.lacunarity)
			])
		]);
		collection.update(selector, update);
	}

	Bson ById(string id) {
		BsonObjectID oid = BsonObjectID.fromString(id);
		auto conditions = Bson(["_id": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		return obj;
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
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0
		};

		assertNotThrown(world_storage.Create(world));
	}

	void Find_by_id() {
		NewWorld world = {
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
		auto objid = world_storage.ById(sid);
		assertEqual(objid["seed"].get!int, 1);
	}

	void Update_should_work() {
		NewWorld world = {
			seed: 1,
			perlinScale: 1.0,
			octaves: 1,
			persistence: 1.0,
			lacunarity: 1.0
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