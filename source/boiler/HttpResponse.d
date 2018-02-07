module boiler.HttpResponse;

class HttpResponse {
	int code;
	string content;
	string content_type;
	ubyte[] data;

	void writeBody(string content, int code){
		this.content = content;
		this.code = code;
		this.content_type = "text/html; charset=UTF-8";
	}

	void writeBody(string content, string content_type){
		this.content = content;
		this.code = 200;
		this.content_type = content_type;
	}

	void writeBody(ubyte[] data, string content_type){
		this.data = data;
		this.code = 200;
		this.content_type = content_type;
	}
}