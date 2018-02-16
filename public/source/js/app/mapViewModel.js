var MapViewmodel = function() {
	var self = this;

	self.defaultMapParameters = {
		seed: 1,
		perlinScale: 0.5,
		octaves: 8,
		persistence: 0.5,
		lacunarity: 2
	};

	self.map = null;
	self.canvas = null;
	self.mapParameters = ko.mapping.fromJS(self.defaultMapParameters);

	self.CreateMap = function() {
		self.map = ko.mapping.toJS(self.mapParameters);
	};
/*
	self.change = ko.computed(function () {
		ko.toJS(root);
	};*/
};

var mapViewmodel = new MapViewmodel();
ko.applyBindings(mapViewmodel);

mapViewmodel.CreateMap();

var rotatey = 0;
var rotatex = 0;
var height = 100;
var width = 100;
var radius = 50;

var imagesloaded = 0;

function imgload() {
	imagesloaded++;
	if(imagesloaded == 3) {
		imagesloaded = 0;
		setTimeout(getmap, 100);
	}
}

$("#mapimage").css("height", height);
$("#mapimage").css("width", width);
$("#mapimage2").css("height", height);
$("#mapimage2").css("width", width);
$("#mapimage3").css("height", height);
$("#mapimage3").css("width", width);

$("#mapimage").on("load", imgload);
$("#mapimage2").on("load", imgload);
$("#mapimage3").on("load", imgload);

var xdir = -.5;

function getmap() {
	//console.log("update");
	rotatey+=0.5;
	if(rotatey>360)
		rotatey-=360;
	
	rotatex += xdir;
	if(rotatex>=90 || rotatex<=-90) {
		xdir = -xdir;
	}

	var vmvars = ko.mapping.toJS(mapViewmodel.mapParameters);

	var data = {
		"action": "GetMap",
		"perlinScale": vmvars.perlinScale,
		"octaves": vmvars.octaves,
		"persistence": vmvars.persistence,
		"lacunarity": vmvars.lacunarity,
		"rotatey": rotatey,
		"rotatex": rotatex,
		"radius": radius,
		"width": width,
		"height": height
	};
	var params = $.param(data);
	data.radius = radius*10;
	var params2 = $.param(data);
	data.radius = radius*100;
	var params3 = $.param(data);
	console.log(params);
	$("#mapimage").attr("src","/get?" + params);
	$("#mapimage2").attr("src","/get?" + params2);
	$("#mapimage3").attr("src","/get?" + params3);
}

getmap();