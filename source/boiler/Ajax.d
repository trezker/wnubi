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

	bool HasAccess(HttpRequest req) {
		return true;
	}

	public void SetActionCreator(string name, ActionCreator actionCreator) {
		actionCreators[name] = actionCreator;
	}

	private HttpResponse BuildFailResponse(int code) {
		auto res = new HttpResponse;
		Json json = Json.emptyObject;
		json["success"] = false;
		res.writeBody(serializeToJsonString(json), code);
		return res;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string actionName = req.json["action"].to!string;
			if(actionName in actionCreators) {
				Action action = actionCreators[actionName]();
				if(action.HasAccess(req)) {
					res = action.Perform (req);
				}
				else {
					res = BuildFailResponse(403);
				}
			}
			else {
				res = BuildFailResponse(404);
			}
		}
		catch(Exception e) {
			res = BuildFailResponse(500);
		}
		return res;
	}
}

class SuccessTestHandler : Action {
	bool HasAccess(HttpRequest req) {
		return true;
	}

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

		ActionTester tester = new ActionTester(&ajax.Perform, "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_doesnt_exist_should_fail() {
		Ajax ajax = new Ajax();

		ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"none\"}", "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void Call_to_method_that_exists_should_succeed() {
		Ajax ajax = new Ajax();
		ajax.SetActionCreator("test", () => new SuccessTestHandler);

		ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"test\"}", "");

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}