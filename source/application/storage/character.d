module application.storage.character;

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
import application.data;
import application.storage.user;

struct NewCharacter {
	BsonObjectID userId;
	BsonObjectID worldId;
	Coordinates coordinates;
}

struct Character {
	BsonObjectID _id;
	BsonObjectID userId;
	BsonObjectID worldId;
	Coordinates coordinates;
}

class Character_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("character");
	}

	void Create(NewCharacter character) {
		try {
			collection.insert(character);
		}
		catch(Exception e) {
			//if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			//}
			throw e;
		}
	}

	Character[] ByUser(string userId) {
		BsonObjectID oid = BsonObjectID.fromString(userId);
		auto conditions = Bson(["userId": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		return MongoArray!(Character)(collection, conditions);
	}
/*
	Character ById(string id) {
		BsonObjectID oid = BsonObjectID.fromString(id);
		auto conditions = Bson(["_id": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		return obj;
	}*/
}

class Test : TestSuite {
	Database database;
	Character_storage character_storage;
	User_storage user_storage;

	this() {
		database = GetDatabase("test");
		user_storage = new User_storage(database);
		
		AddTest(&Create_character);
		AddTest(&Find_characters_by_user);
	}

	override void Setup() {
		character_storage = new Character_storage(database);
	}

	override void Teardown() {
		database.ClearCollection("character");
	}

	void Create_character() {
		NewCharacter character = {
			userId: BsonObjectID.fromString("000000000000000000000000"),
			coordinates: {1.0, 2.0}
		};

		assertNotThrown(character_storage.Create(character));
	}

	void Find_characters_by_user() {
		auto userId = "000000000000000000000000";
		NewCharacter character = {
			userId: BsonObjectID.fromString(userId),
			coordinates: {1.0, 2.0}
		};

		character_storage.Create(character);
		character_storage.Create(character);

		auto characters = character_storage.ByUser(userId);

		assertEqual(2, characters.length);
		foreach(e; characters) {
			assertEqual(userId, e.userId.toString());
		}
	}
}

unittest {
	auto test = new Test;
	test.Run();
}
