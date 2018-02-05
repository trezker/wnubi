module application.GetMap;

import std.stdio;
import std.math;
import std.conv;
import std.string;
import std.algorithm;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;
import dlib.math;
import imageformats;

import boiler.ActionTester;
import boiler.Get;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.perlin;

struct Region {
	string name;
	double height;
	ubyte[] color;
};

Region[] regions = [
	{
		name: "Water deep",
		height: 0.3,
		color: [0x00,0x00,0xaa,0xff]
	},
	{
		name: "Water shallow",
		height: 0.4,
		color: [0x00,0x00,0xff,0xff]
	},
	{
		name: "Sand",
		height: 0.45,
		color: [0xe3,0xae,0x0b,0xff]
	},
	{
		name: "Grass",
		height: 0.55,
		color: [0x48,0xcb,0x48,0xff]
	},
	{
		name: "Grass 2",
		height: 0.6,
		color: [0x26,0xa6,0x26,0xff]
	},
	{
		name: "Rock",
		height: 0.7,
		color: [0x74,0x64,0x44,0xff]
	},
	{
		name: "Rock 2",
		height: 0.9,
		color: [0x6a,0x60,0x4b,0xff]
	},
	{
		name: "Snow",
		height: 1,
		color: [0xff,0xff,0xff,0xff]
	}
];

class GetMap: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		double perlinScale = req.json["perlinScale"].to!double;
		int octaves = req.json["octaves"].to!int;
		double persistence = req.json["persistence"].to!double;
		double lacunarity = req.json["lacunarity"].to!double;
		double rotatey = req.json["rotatey"].to!double;
		double radius = req.json["radius"].to!double;

    	ubyte[] image;
    	ubyte[] blank_pixel = [0, 0, 0, 0];

		int vw = 100;
		int vh = 100;

		double r = radius;
		for (int y = 0; y < vh; y++) {
			auto w = to!int(sqrt(to!float(r*r-(y-vh/2)*(y-vh/2))));
			if(w > vw/2)
				w = vw/2;
			for(int x = 0; x < vw; x++) {
				if(x < vw/2-w || x > vw/2+w) {
					image ~= blank_pixel[0..3];
					continue;
				}
				auto p = Vector3d(
					(x-vw/2)/r, 
					(y-vh/2)/r,
					0
				);
				p.z = sqrt(1-sqrt(p.x*p.x+p.y*p.y));
				if(isNaN(p.z)) {
					p.z = 0;
				}

				auto pr = Vector3d();
				rotateAroundAxis(pr, p, Vector3d(0, 1, 0), rotatey);
				int layer = 0;
				
				//for(layer = 0; layer<regions.length; layer++) 
				{
					double scale = perlinScale;
					double amplitude = 1;
					double frequency = 1;
					double c = 0;
					for(int o = 0; o < octaves; o++) {
						double perlinValue = PerlinNoise(scale*p.x*frequency+layer*0.5, scale*p.y*frequency, scale*p.z*frequency)*2-1;
						c += perlinValue * amplitude;

						amplitude *= persistence;
						frequency *= lacunarity;
					}

					c = (c+1)/2;
					ubyte[] color = [0x00,0x00,0xaa,0xff];
/*
					for(int region = 0; region<regions[layer].length; region++) {
						if(c < regions[layer][region].height) {
							color = regions[layer][region].color;
							break;
						}
					}*/
					for(int region = 0; region<regions.length; region++) {
						if(c < regions[region].height) {
							color = regions[region].color;
							break;
						}
					}
					image ~= color[0..3];
				}
			}
		}

		ubyte[] png = write_png_to_mem(100, 100, image);
		res.writeBody(png, "image/png");
		return res;
	}
}

class Test : TestSuite {
	this() {
		AddTest(&GetMap_without_parameters_should_fail);
		AddTest(&GetMap_with_specific_parameters_should_succeed);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void GetMap_without_parameters_should_fail() {
		Get get = new Get();
		get.SetActionCreator("test", () => new GetMap);
		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?action=test");

		string textoutput = tester.GetResponseText();
		assertEqual(indexOf(textoutput, "500") == -1, false);
	}

	void GetMap_with_specific_parameters_should_succeed() {
		Json jsoninput = Json.emptyObject;
		jsoninput["perlinScale"] = 1;
		jsoninput["octaves"] = 4;
		jsoninput["persistence"] = 0.5;
		jsoninput["lacunarity"] = 2;
		jsoninput["rotatey"] = 0;
		jsoninput["radius"] = 50;

		Get get = new Get();
		get.SetActionCreator("test", () => new GetMap);
		ActionTester tester = new ActionTester(&get.Perform, serializeToJsonString(jsoninput), "http://test.com/test?action=test");

		auto responseLines = tester.GetResponseLines();
		bool pred(string x) { return x.indexOf("image/png") != -1; }
		auto content_type = find!(pred)(responseLines);
		assertGreaterThan(content_type.length, 0);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}