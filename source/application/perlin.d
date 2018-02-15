module application.perlin;

import std.math;
import std.conv;
import std.stdio;
import std.random;
import dlib.math;

class Perlin {
	int[] p;
	this(int seed) {
		for(int i = 0; i < 256; ++i) {
			p ~= i;
		}
		auto rnd = Random(seed);
		randomShuffle(p, rnd);
		for(int i = 0; i < 256; ++i) {
			p ~= p[i];
		}
	}

	double value(double x, double y, double z) {
		int X = to!int(floor(x)) & 255;                  // FIND UNIT CUBE THAT
		int Y = to!int(floor(y)) & 255;                  // CONTAINS POINT.
		int Z = to!int(floor(z)) & 255;
		x -= floor(x);                                // FIND RELATIVE X,Y,Z
		y -= floor(y);                                // OF POINT IN CUBE.
		z -= floor(z);
		
		double u = fade(x);                                // COMPUTE FADE CURVES
		double v = fade(y);                                // FOR EACH OF X,Y,Z.
		double w = fade(z);

		int A = p[X]+Y;
		int AA = p[A]+Z;
		int AB = p[A+1]+Z;      // HASH COORDINATES OF
		int B = p[X+1]+Y;
		int BA = p[B]+Z;
		int BB = p[B+1]+Z;      // THE 8 CUBE CORNERS,

		return scale(
			lerp(
				lerp(
					lerp(
						grad(
							p[AA], x  , y  , z
						),  // AND ADD
						grad(
							p[BA], x-1, y  , z
						),
						u
					), // BLENDED
					lerp(
						grad(
							p[AB], x , y-1, z
						),  // RESULTS
						grad(
							p[BB], x-1, y-1, z
						),
						u
					),
					v
				),// FROM  8
				lerp(
					lerp(
						grad(
							p[AA+1], x  , y  , z-1
						),  // CORNERS
						grad(
							p[BA+1], x-1, y, z-1
						),
						u
					), // OF CUBE
					lerp(
						grad(
							p[AB+1], x, y-1, z-1
						),
						grad(
							p[BB+1], x-1, y-1, z-1
						),
						u
					),
					v
				),
				w
			)
		);
	}
}

double fade(double t) {
	return t * t * t * (t * (t * 6 - 15) + 10);
}

double grad(int hash, double x, double y, double z) {
	int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
	double u = h<8 ? x : y;                 // INTO 12 GRADIENT DIRECTIONS.
	double v = h<4 ? y : h==12||h==14 ? x : z;
	return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
}

double scale(double n) {
	return (1 + n)/2;
}
