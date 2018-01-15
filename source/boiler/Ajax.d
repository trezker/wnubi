module boiler.Ajax;

import std.stdio;
import vibe.http.server;
import vibe.data.json;

import boiler.ActionTester;
import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.helpers;
import boiler.testsuite;

alias ActionCreator = Action delegate();

class Ajax: Action {
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
				res.writeBody(serializeToJsonString(json), 200);
			}
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			res = new HttpResponse;
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
		Ajax ajax = new Ajax();

		ActionTester tester = new ActionTester(&ajax.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_doesnt_exist_should_fail() {
		Ajax ajax = new Ajax();

		ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"none\"}");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_exists_should_succeed() {
		Ajax ajax = new Ajax();
		ajax.SetActionCreator("test", () => new SuccessTestHandler);

		ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"test\"}");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}