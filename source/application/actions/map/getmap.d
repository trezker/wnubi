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
		double perlinScale = req.query["perlinScale"].to!double;
		int octaves = req.query["octaves"].to!int;
		double persistence = req.query["persistence"].to!double;
		double lacunarity = req.query["lacunarity"].to!double;
		double rotatedegrees = req.query["rotatey"].to!double;
		double rotatey = req.query["rotatey"].to!double * PI / 180.0;
		double radius = req.query["radius"].to!double;
		int width = req.query["width"].to!int;
		int height = req.query["height"].to!int;

		ubyte[] image;
		ubyte[] blank_pixel = [0, 0, 0, 0];

		double r = radius;

		Perlin perlin = new Perlin(0);

		for (int y = 0; y < height; y++) {
			auto w = to!int(sqrt(to!float(r*r-(y-height/2)*(y-height/2))));
			if(w > width/2)
				w = width/2;
			for(int x = 0; x < width; x++) {
				if(x < width/2-w || x > width/2+w) {
					image ~= blank_pixel[0..3];
					continue;
				}
				auto p = Vector3d(
					(x-width/2)/r, 
					(y-height/2)/r,
					0
				);
				p.z = sqrt(1-sqrt(p.x*p.x+p.y*p.y));
				if(isNaN(p.z)) {
					p.z = 0;
					image ~= blank_pixel[0..3];
					continue;
				}

				p.normalize();
				rotateAroundAxis(p, Vector3d(0.0, 0.0, 0.0), Vector3d(0.0, 1.0, 0.0), rotatey);
				p.normalize();
				int layer = 0;
				
				//for(layer = 0; layer<regions.length; layer++) 
				{
					double scale = perlinScale;
					double amplitude = 1;
					double frequency = 1;
					double c = 0;
					for(int o = 0; o < octaves; o++) {
						double perlinValue = perlin.value(scale*p.x*frequency+layer*0.5, scale*p.y*frequency, scale*p.z*frequency)*2-1;
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
					if(c>1)
						c=1;
					for(int region = 0; region<regions.length; region++) {
						if(c < regions[region].height) {
							color = regions[region].color;
							break;
						}
					}
					image ~= color[0..3];
					//ubyte g = to!ubyte(c*255);
					//image ~= [g, g, g, 255][0..3];
				}
			}
		}
		string lead = "";
		if(rotatedegrees<10)
			lead = "00";
		if(rotatedegrees<100)
			lead = "0";
		string filename = "map" ~ lead ~ to!string(rotatedegrees) ~ ".png";
		write_png(filename, width, height, image);
		ubyte[] png = write_png_to_mem(width, height, image);
		res.writeBody(png, "image/png");
		res.headers["Cache-Control"] = "max-age=86400";
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
		string[] args = [
			"action=test",
			"perlinScale=1",
			"octaves=4",
			"persistence=0.5",
			"lacunarity=2",
			"rotatey=1",
			"radius=50",
			"width=50",
			"height=50"
		];
		string argstring = join(args, "&");

		Get get = new Get();
		get.SetActionCreator("test", () => new GetMap);
		ActionTester tester = new ActionTester(&get.Perform, "http://test.com/test?" ~ argstring);

		auto responseLines = tester.GetResponseLines();
//		writeln(responseLines);
		bool pred(string x) { return x.indexOf("image/png") != -1; }
		auto content_type = find!(pred)(responseLines);
		assertGreaterThan(content_type.length, 0);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}
/*action=GetMap&perlinScale=1&octaves=4&persistence=0.5&lacunarity=2&rotatey=0&radius=50*/
