module boiler.Get;

import std.stdio;
import vibe.http.server;
import vibe.data.json;

import boiler.ActionTester;
import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.helpers;
import boiler.testsuite;

alias ActionCreator = Action delegate();

class Get: Action {
	private ActionCreator[string] actionCreators;

	public void SetActionCreator(string name, ActionCreator actionCreator) {
		actionCreators[name] = actionCreator;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string actionName = req.json["action"].to!string;
			if(actionName in actionCreators) {
				Action action = actionCreators[actionName]();
				res = action.Perform (req);
			}
			else {
				res = new HttpResponse;
				Json json = Json.emptyObject;
				json["success"] = false;
				//TODO: 404
				res.writeBody(serializeToJsonString(json), 200);
			}
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			res = new HttpResponse;
				//TODO: 404
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

class SuccessTestHandler : Action {
	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		Json json = Json.emptyObject;
		json["success"] = true;
		//TODO: file content
		res.writeBody(serializeToJsonString(json), 200);
		return res;
	}
}


class Test : TestSuite {
	this() {
		AddTest(&Call_without_parameters_should_fail);
		AddTest(&Call_to_method_that_doesnt_exist_should_fail);
		AddTest(&Call_to_method_that_exists_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void Call_without_parameters_should_fail() {
		Get get = new Get();

		ActionTester tester = new ActionTester(&get.Perform);

		//TODO: detect 404
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_doesnt_exist_should_fail() {
		Get get = new Get();

		ActionTester tester = new ActionTester(&get.Perform, "{\"action\": \"none\"}");

		//TODO: detect 404
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_exists_should_succeed() {
		Get get = new Get();
		get.SetActionCreator("test", () => new SuccessTestHandler);

		ActionTester tester = new ActionTester(&get.Perform, "{\"action\": \"test\"}");

		//TODO: detect file content
		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}