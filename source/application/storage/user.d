module application.storage.user;

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

class User_storage {
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("user");
	}

	void Create(string username, string password) {
		try {
			collection.insert(
				Bson([
					"username": Bson(username),
					"password": Bson(password)
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

	Bson UserByName(string username) {
		auto condition = Bson(["username": Bson(username)]);
		auto obj = collection.findOne(condition);
		return obj;
	}

	Bson UserById(string id) {
		BsonObjectID oid = BsonObjectID.fromString(id);
		auto conditions = Bson(["_id": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		return obj;
	}

}

class Test : TestSuite {
	Database database;
	User_storage user_storage;

	this() {
		database = GetDatabase("test");
		user_storage = new User_storage(database);
		
		AddTest(&Create_user);
		AddTest(&Unique_username);
		AddTest(&User_not_found);
		AddTest(&Find_user);
		AddTest(&Find_user_id);
		AddTest(&Hashing);
	}

	override void Setup() {
	}

	override void Teardown() {
		database.ClearCollection("user");
	}

	void Create_user() {
		User_storage us = new User_storage(database);
		assertNotThrown(us.Create("name", "pass"));
	}

	void Unique_username() {
		User_storage us = new User_storage(database);
		
		assertNotThrown(us.Create("name", "pass"));
		assertNotThrown(us.Create("name", "pass"));
		
		Bson query = Bson(["username" : Bson("name")]);
		auto result = database.GetCollection("user").find(query);
		Json json = parseJsonString(to!string(result));
		assertEqual(1, json.length);
	}

	void User_not_found() {
		auto username = "name"; 
		auto obj = user_storage.UserByName(username);
		assertEqual(obj, Bson(null));
	}

	void Find_user() {
		User_storage us = new User_storage(database);
		auto username = "name"; 
		us.Create("wrong", "");
		us.Create(username, "");
		auto obj = us.UserByName(username);

		assertEqual(obj["username"].get!string, username);
	}

	void Find_user_id() {
		auto username = "name"; 
		user_storage.Create("wrong", "");
		user_storage.Create(username, "");
		auto obj = user_storage.UserByName(username);
		//Testing how to pass around id as string and then using it against mongo.
		BsonObjectID oid = obj["_id"].get!BsonObjectID;
		string sid = oid.toString();
		auto objid = user_storage.UserById(sid);

		assertEqual(objid["username"].get!string, username);
	}

	void Hashing() {
		char[] pass = "aljksdn".dup;
		string hashString = makeHash(toPassword(pass)).toString();
		pass = "aljksdn".dup;
		assert(isSameHash(toPassword(pass), parseHash(hashString)));
		pass = "alksdn".dup;
		assert(!isSameHash(toPassword(pass), parseHash(hashString)));
	}
}

unittest {
	auto test = new Test;
	test.Run();
}