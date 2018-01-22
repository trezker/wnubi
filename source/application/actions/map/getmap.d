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

class GetMap: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			// width * height
			auto image = new Image!(PixelFormat.RGB8)(100, 100);
			auto vw = image.width;
			auto vh = image.height;

			// fill it in with a gradient
			foreach(y; 0 .. image.height)
			    foreach(x; 0 .. image.width)
			        image[x, y] = Color4f(0, 0, 0);

			auto r = 50;
			//canvas.canvasContext.fillStyle = "#FFF";
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
					/*
					var p = {
						x: (x-vw/2)/r,
						y: (y-vh/2)/r
					}*/
					p.z = sqrt(1-sqrt(p.x*p.x+p.y*p.y));

					auto pr = Vector3d();
					rotateAroundAxis(pr, p, Vector3d(0, 1, 0), 0);
					/*
					var pr = vec3.rotateY([], [p.x, p.y, p.z], [0, 0, 0], self.rotationy);
					p.x = pr[0];
					p.y = pr[1];
					p.z = pr[2];
					*/
					//var layer = 0;
					/*
					for(layer = 0; layer<regions.length; layer++) 
					{
						var scale = self.settings.perlinScale;
						var amplitude = 1;
						var frequency = 1;
						var c = 0;
						for(o = 0; o < self.settings.octaves; o++) {
							var perlinValue = PerlinNoise.noise(scale*p.x*frequency+layer*0.5, scale*p.y*frequency, scale*p.z*frequency)*2-1;
							c += perlinValue * amplitude;

							amplitude *= self.settings.persistence;
							frequency *= self.settings.lacunarity;
						}

						c = (c+1)/2;
						if(c<min)
							min=c;
						if(c>max)
							max=c;
						var color = "";

						for(region = 0; region<regions[layer].length; region++) {
							if(c < regions[layer][region].height) {
								color = regions[layer][region].color;
								break;
							}
						}
						canvas.canvasContext.fillStyle = color;
						if(color != "") {
							canvas.DrawPoint({x,y})
						}
					}*/
			        image[x, y] = Color4f(255, 255, 255);
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
	}

	override void Setup() {
	}

	override void Teardown() {
	}

	void GetMap_should_generate_image_file() {
		GetMap m = new GetMap();

		ActionTester tester = new ActionTester(&m.Perform);
	}
}

unittest {
	auto test = new Test;
	test.Run();
}