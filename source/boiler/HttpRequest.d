module boiler.HttpRequest;

import std.conv;
import std.stdio;
import std.array;
import std.string;

import vibe.http.session;
import vibe.http.server;
import vibe.data.json;

import vibe.utils.string;
import vibe.utils.dictionarylist;
import vibe.inet.url;

import boiler.helpers;
import boiler.HttpResponse;
import boiler.testsuite;

alias FormFields = DictionaryList!(string, true, 16);
alias InetHeaderMap = DictionaryList!(string, false, 12);

interface Action {
	public HttpResponse Perform(HttpRequest req);
	public bool HasAccess(HttpRequest req);
}

class HttpRequest {
	private SessionStore sessionstore;
	Session session;
	Json json;
	string path;
	string querystring;
	FormFields query;
	InetHeaderMap headers;

	this(SessionStore sessionstore) {
		this.sessionstore = sessionstore;
	}

	void SetJsonFromString(string jsonstring) {
		json = parseJsonString(jsonstring);
	}

	Session StartSession() {
		if(!session) {
			session = sessionstore.create();
		}
		return session;
	}

	void TerminateSession() {
		if(session) {
			sessionstore.destroy(session.id);
			session = Session.init;
		}
	}
}

//Function lifted from vibe webform.d
void parseURLEncodedForm(string str, ref FormFields params)
@safe {
	import vibe.textfilter.urlencode;
	while (str.length > 0) {
		// name part
		auto idx = str.indexOf("=");
		if (idx == -1) {
			idx = vibe.utils.string.indexOfAny(str, "&;");
			if (idx == -1) {
				params.addField(formDecode(str[0 .. $]), "");
				return;
			} else {
				params.addField(formDecode(str[0 .. idx]), "");
				str = str[idx+1 .. $];
				continue;
			}
		} else {
			auto idx_amp = vibe.utils.string.indexOfAny(str, "&;");
			if (idx_amp > -1 && idx_amp < idx) {
				params.addField(formDecode(str[0 .. idx_amp]), "");
				str = str[idx_amp+1 .. $];
				continue;
			} else {
				string name = formDecode(str[0 .. idx]);
				str = str[idx+1 .. $];
				// value part
				for( idx = 0; idx < str.length && str[idx] != '&' && str[idx] != ';'; idx++) {}
				string value = formDecode(str[0 .. idx]);
				params.addField(name, value);
				str = idx < str.length ? str[idx+1 .. $] : null;
			}
		}
	}
}

private void parseCookies(string str, ref CookieValueMap cookies)
@safe {
	import std.encoding : sanitize;
	import std.array : split;
	import std.string : strip;
	import std.algorithm.iteration : map, filter, each;
	import vibe.http.common : Cookie;
	() @trusted { return str.sanitize; } ()
		.split(";")
		.map!(kv => kv.strip.split("="))
		.filter!(kv => kv.length == 2) //ignore illegal cookies
		.each!(kv => cookies.add(kv[0], kv[1], Cookie.Encoding.raw) );
}

HttpRequest CreateHttpRequest(URL url, InetHeaderMap headers, string content, SessionStore sessionstore) {
	import vibe.textfilter.urlencode;
	HttpRequest request = new HttpRequest(sessionstore);
	request.headers = headers;

	if(headers.get("Content-Type") == "application/json") {
		request.SetJsonFromString(content);
	}

	if(headers.get("Cookie") != "") {
		CookieValueMap cookies;
		parseCookies(headers["Cookie"], cookies);

		foreach (val; cookies.getAll("session_id")) {
			request.session = sessionstore.open(val);
			if (request.session) break;
		}
	}

	request.path = urlDecode(url.path.toString);
	request.querystring = url.queryString;
	parseURLEncodedForm(request.querystring, request.query);
	
	return request;
}

HttpRequest CreateHttpRequestFromVibeHttpRequest(HTTPServerRequest viberequest, SessionStore sessionstore) {
	HttpRequest request = new HttpRequest(sessionstore);

	if(viberequest.json.type != Json.Type.undefined)
		request.SetJsonFromString(serializeToJsonString(viberequest.json));

	foreach (val; viberequest.cookies.getAll("session_id")) {
		request.session = sessionstore.open(val);
		if (request.session) break;
	}

	request.path = viberequest.path;
	request.querystring = viberequest.queryString;
	request.query = viberequest.query;
	
	return request;
}

void RenderVibeHttpResponseFromRequestAndResponse(HTTPServerResponse viberesponse, HttpRequest request, HttpResponse response) {
	if(request.session) {
		viberesponse.setCookie("session_id", request.session.id);
	}

	foreach (key, value; response.headers) {
		viberesponse.headers[key] = value;
	}

	if(response.content_type) {
		if(response.content) {
			viberesponse.writeBody(response.content, response.content_type);
		} else {
			viberesponse.writeBody(response.data, response.content_type);
		}
	}
	else {
		if(response.content) {
			viberesponse.writeBody(response.content, response.code);
		} else {
			viberesponse.writeBody(response.data, response.code);
		}
	}
}

class Test : TestSuite {
	this() {
		AddTest(&Create_request_with_json);
		AddTest(&Request_can_start_a_session);
		AddTest(&Request_can_terminate_session);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void Create_request_with_json() {
		auto sessionstore = new MemorySessionStore ();
		Json json = Json.emptyObject;
		json["key"] = "value";
		auto request = new HttpRequest(sessionstore);
		request.SetJsonFromString(serializeToJsonString(json));

		assertEqual(request.json["key"].to!string, "value");
	}

	void Request_can_start_a_session() {
		auto sessionstore = new MemorySessionStore ();
		HttpRequest request = new HttpRequest(sessionstore);
		Session session = request.StartSession();
		assert(session);
		assert(request.session);
	}

	void Request_can_terminate_session() {
		auto sessionstore = new MemorySessionStore ();
		HttpRequest request = new HttpRequest(sessionstore);
		Session session = request.StartSession();
		request.TerminateSession();
		assert(!request.session);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}