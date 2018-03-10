var MapViewmodel = function() {
	var self = this;

	self.autorotate = ko.observable(false);
	self.rotatey = ko.observable(0);
	self.rotatex = ko.observable(0);

	self.worlds = ko.observableArray();

	self.defaultMapParameters = {
		_id: "",
		name: "",
		seed: 5,
		perlinScale: 0.5,
		octaves: 8,
		persistence: 0.6,
		lacunarity: 2.5,
		spawnpoints: []
	};

	self.canvas = null;
	self.mapParameters = ko.mapping.fromJS(self.defaultMapParameters);

	self.LoadWorlds = function() {
		var data = {
			action: "ListWorlds"
		};
		ajax_post(data).done(function(returnedData) {
			console.log(returnedData);
			if(returnedData.success == true) {
				self.worlds(returnedData.worlds);
			}
		});
	};

	self.SelectWorld = function(item) {
		ko.mapping.fromJS(item, self.mapParameters);
	};

	self.CreateMap = function() {
		var data = ko.mapping.toJS(self.mapParameters);
		data.action = "CreateWorld";
		data.seed = parseFloat(data.seed);
		data.perlinScale = parseFloat(data.perlinScale);
		data.octaves = parseFloat(data.octaves);
		data.persistence = parseFloat(data.persistence);
		data.lacunarity = parseFloat(data.lacunarity);
		ajax_post(data).done(function(returnedData) {
			console.log(returnedData);
			if(returnedData.success == true) {
				self.LoadWorlds();
			}
		});
	};

	self.UpdateMap = function() {
		var data = ko.mapping.toJS(self.mapParameters);
		data.action = "UpdateWorld";
		data.seed = parseFloat(data.seed);
		data.perlinScale = parseFloat(data.perlinScale);
		data.octaves = parseFloat(data.octaves);
		data.persistence = parseFloat(data.persistence);
		data.lacunarity = parseFloat(data.lacunarity);
		ajax_post(data).done(function(returnedData) {
			console.log(returnedData);
			if(returnedData.success == true) {
				self.LoadWorlds();
			}
		});
	};

	self.DeleteWorld = function(item) {
		console.log(item);
		var data = {
			action: "DeleteWorld",
			worldId: item._id
		};
		ajax_post(data).done(function(returnedData) {
			console.log(returnedData);
			if(returnedData.success == true) {
				self.LoadWorlds();
			}
		});
	}
};

var mapViewmodel = new MapViewmodel();
ko.applyBindings(mapViewmodel);

mapViewmodel.LoadWorlds();

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
	var rotatey = mapViewmodel.rotatey();
	var rotatex = mapViewmodel.rotatex();
	if(mapViewmodel.autorotate()) {
		rotatey+=4;
		if(rotatey>360)
			rotatey-=360;
		mapViewmodel.rotatey(rotatey);
	}
	/*
	rotatex += xdir;
	if(rotatex>=90 || rotatex<=-90) {
		xdir = -xdir;
	}
*/


	var vmvars = ko.mapping.toJS(mapViewmodel.mapParameters);

	var data = {
		"action": "WorldPreview",
		"seed": vmvars.seed,
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
	$("#mapimage").attr("src","/get?" + params);
	$("#mapimage2").attr("src","/get?" + params2);
	$("#mapimage3").attr("src","/get?" + params3);
}

getmap();