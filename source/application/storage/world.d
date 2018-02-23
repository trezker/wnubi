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
		//Testing how to pass around id as string and then using it against mongo.
		BsonObjectID oid = obj[0]._id;
		string sid = oid.toString();
		auto objid = world_storage.ById(sid);
		assertEqual(objid["seed"].get!int, 1);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}