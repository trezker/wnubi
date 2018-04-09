module application.testhelpers;

import boiler.ActionTester;
import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import std.datetime;
import vibe.data.json;
import vibe.data.bson;


void CreateTestUser(Database database, string name, string password) {
	CreateUser m = new CreateUser(new User_storage(database));
	Json jsoninput = Json.emptyObject;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput), "");

	database.Sync();
}

ActionTester TestLogin(Database database, string name, string password) {
	Login login = new Login(new User_storage(database));

	Json jsoninput = Json.emptyObject;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	return new ActionTester(&login.Perform, serializeToJsonString(jsoninput), "");
}

