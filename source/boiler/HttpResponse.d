module boiler.HttpResponse;

class HttpResponse {
	int code;
	string content;
	string content_type;

	void writeBody(string content, int code){
		this.content = content;
		this.code = code;
	}

	void writeBody(string content, string content_type){
		this.content = content;
		this.code = 200;
		this.content_type = content_type;
	}
}