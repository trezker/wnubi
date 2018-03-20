module boiler.Get;

import std.conv;
import std.stdio;
import std.string;
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

	bool HasAccess(HttpRequest req) {
		return true;
	}

	public void SetActionCreator(string name, ActionCreator actionCreator) {
		actionCreators[name] = actionCreator;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string actionName = req.query["action"].to!string;
			if(actionName in actionCreators) {
				Action action = actionCreators[actionName]();
				if(action.HasAccess(req)) {
					res = action.Perform (req);
				}
				else {
					res = new HttpResponse;
					res.writeBody("<html><head><title>403 Forbidden</title></head><body><h1>403 Forbidden</h1></body></html>", 404);
				}
			}
			else {
				res = new HttpResponse;
				res.writeBody("<html><head><title>404 Not found</title></head><body><h1>404 Not found</h1></body></html>", 404);
			}
		}
		catch(Exception e) {
			res = new HttpResponse;
			res.writeBody("<html><head><title>500 Error</title></head><body><h1>500 Error</h1></body></html>", 500);
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
		res.writeBody("Hello world", 200);
		return res;
	}
}

class ErrorTestHandler : Action {
	bool HasAccess(HttpRequest req) {
		return true;
	}

	public HttpResponse Perform(HttpRequest req) {
		throw(new Exception("Error"));
	}
}

class DataTestHandler : Action {
	bool HasAccess(HttpRequest req) {
		return true;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		ubyte[] data = [1, 2, 3, 45, 243, 43, 123, 53];
		res.writeBody(data, "image/png");
		return res;
	}
}

class Test : TestSuite {
	this() {
		AddTest(&Exceptions_should_return_error_page);
		AddTest(&Call_to_method_that_doesnt_exist_should_fail);
		AddTest(&Call_to_method_that_exists_should_succeed);
		AddTest(&Data_content_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void Exceptions_should_return_error_page() {
		Get get = new Get();
		get.SetActionCreator("test", () => new ErrorTestHandler);
		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?action=test");

		string textoutput = tester.GetResponseText();
		assertEqual(indexOf(textoutput, "500") == -1, false);
	}

	void Call_to_method_that_doesnt_exist_should_fail() {
		Get get = new Get();

		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?action=test");

		string textoutput = tester.GetResponseText();
		assertEqual(indexOf(textoutput, "404") == -1, false);
	}

	void Call_to_method_that_exists_should_succeed() {
		Get get = new Get();
		get.SetActionCreator("test", () => new SuccessTestHandler);

		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?action=test");

		string textoutput = tester.GetResponseText();
		assertEqual(textoutput, "Hello world");
	}

	void Data_content_should_succeed() {
		Get get = new Get();
		get.SetActionCreator("test", () => new DataTestHandler);
		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?action=test");

		string[] headers = tester.GetResponseLines();
		assertEqual(indexOf(headers[0], "200") == -1, false);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}