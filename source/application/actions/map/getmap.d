module application.GetMap;

import std.stdio;
import std.math;
import std.conv;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;
import dlib.image;
import dlib.math;

import boiler.ActionTester;
import boiler.helpers;
import boiler.testsuite;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.Database;
import application.perlin;

struct Region {
	string name;
	double height;
	Color4f color;
};
/*
Region[int] [
	[
		{
			name: "Water deep",
			height: 0.3,
			color: color3(0x0000aa)
		},
		{
			name: "Water shallow",
			height: 0.4,
			color: color3(0x0000ff)
		},
		{
			name: "Sand",
			height: 0.45,
			color: color3(0xe3ae0b)
		},
		{
			name: "Grass",
			height: 0.55,
			color: color3(0x48cb48)
		},
		{
			name: "Grass 2",
			height: 0.6,
			color: color3(0x26a626)
		},
		{
			name: "Rock",
			height: 0.7,
			color: color3(0x746444)
		},
		{
			name: "Rock 2",
			height: 0.9,
			color: color3(0x6a604b)
		},
		{
			name: "Snow",
			height: 1,
			color: color3(0xffffff)
		}
	]
];*/

Region[] regions = [
	{
		name: "Water deep",
		height: 0.3,
		color: color3(0x0000aa)
	},
	{
		name: "Water shallow",
		height: 0.4,
		color: color3(0x0000ff)
	},
	{
		name: "Sand",
		height: 0.45,
		color: color3(0xe3ae0b)
	},
	{
		name: "Grass",
		height: 0.55,
		color: color3(0x48cb48)
	},
	{
		name: "Grass 2",
		height: 0.6,
		color: color3(0x26a626)
	},
	{
		name: "Rock",
		height: 0.7,
		color: color3(0x746444)
	},
	{
		name: "Rock 2",
		height: 0.9,
		color: color3(0x6a604b)
	},
	{
		name: "Snow",
		height: 1,
		color: color3(0xffffff)
	}
];

class GetMap: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			double perlinScale = req.json["perlinScale"].to!double;
			int octaves = req.json["octaves"].to!int;
			double persistence = req.json["persistence"].to!double;
			double lacunarity = req.json["lacunarity"].to!double;
			double rotatey = req.json["rotatey"].to!double;
			double radius = req.json["radius"].to!double;

			auto image = new Image!(PixelFormat.RGB8)(100, 100);
			int vw = image.width;
			int vh = image.height;

			foreach(y; 0 .. image.height)
			    foreach(x; 0 .. image.width)
			        image[x, y] = Color4f(0, 0, 0);

			double r = radius;
			for (int y = 0; y < vh; y++) {
				auto w = to!int(sqrt(to!float(r*r-(y-vh/2)*(y-vh/2))));
				if(w > vw/2)
					w = vw/2;
				for(int x = vw/2-w; x < vw/2+w; x++) {
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
						Color4f color = Color4f(255, 255, 255);
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
						image[x, y] = color;
					}
				}
			}

			savePNG(image, "public/map/test.png");

			//Write result
			Json json = Json.emptyObject;
			json["success"] = true;
			json["file"] = "public/map/test.png";
			res.writeBody(serializeToJsonString(json), 200);
		}
		catch(Exception e) {
			//writeln(e);
			//Write result
			Json json = Json.emptyObject;
			json["success"] = false;
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

class Test : TestSuite {
	this() {
		AddTest(&GetMap_should_generate_image_file);
		AddTest(&GetMap_can_generate_with_specific_parameters);
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void GetMap_without_parameters_should_fail() {
		GetMap m = new GetMap();

		ActionTester tester = new ActionTester(&m.Perform);

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, false);
	}

	void GetMap_with_specific_parameters_should_succeed() {
		GetMap m = new GetMap();
		Json jsoninput = Json.emptyObject;
		jsoninput["perlinScale"] = 1;
		jsoninput["octaves"] = 4;
		jsoninput["persistence"] = 0.5;
		jsoninput["lacunarity"] = 2;
		jsoninput["rotatey"] = 0;
		jsoninput["radius"] = 50;
		ActionTester tester = new ActionTester(&m.Perform, serializeToJsonString(jsoninput));

		Json jsonoutput = tester.GetResponseJson();
		assertEqual(jsonoutput["success"].to!bool, true);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}