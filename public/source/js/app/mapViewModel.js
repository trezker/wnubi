var MapViewmodel = function() {
	var self = this;

	self.autorotate = ko.observable(false);
	self.longitude = ko.observable(0);
	self.latitude = ko.observable(0);

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
			if(returnedData.success == true) {
				self.LoadWorlds();
			}
		});
	};

	self.DeleteWorld = function(item) {
		var data = {
			action: "DeleteWorld",
			worldId: item._id
		};
		ajax_post(data).done(function(returnedData) {
			if(returnedData.success == true) {
				self.LoadWorlds();
			}
		});
	};

	self.AddSpawnPoint = function() {
		self.mapParameters.spawnpoints.push({
			coordinates: {
				longitude: ko.observable(parseFloat(self.longitude())),
				latitude: ko.observable(parseFloat(self.latitude()))
			}
		});
	};

	self.GoToSpawnpoint = function(item) {
		self.longitude(item.coordinates.longitude());
		self.latitude(item.coordinates.latitude());
	};

	self.DeleteSpawnpoint = function(item) {
		self.mapParameters.spawnpoints.remove(function(spawnpoint) {
			return item == spawnpoint;
		});
	};
	
	self.MarkerPosition = function(item, radius) {
		console.log(item);
		console.log(radius);
		var lngrad = (item.coordinates.longitude() - self.longitude()) * Math.PI / 180.0;
		var latrad = (item.coordinates.latitude() - self.latitude()) * Math.PI / 180.0;
		console.log(lngrad);
		console.log(latrad);
		var x = Math.cos(-latrad) * Math.sin(lngrad) * radius + 49;
		var y = Math.sin(-latrad) * radius + 49;
		var display = "";
		if(x<0 || x>100 || y<0 || y>100 || lngrad > Math.PI/2 || lngrad < -Math.PI/2)
			display = "display: none;";
		return "top: " + y + "; left: " + x + ";" + display;
	};
};

var mapViewmodel = new MapViewmodel();
ko.applyBindings(mapViewmodel);

mapViewmodel.LoadWorlds();

var height = 100;
var width = 100;
var radius = 50;

var imagesloaded = 0;

function imgload() {
	console.log("loaded image");
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
/*
$("#mapimage").on("load", imgload);
$("#mapimage2").on("load", imgload);
$("#mapimage3").on("load", imgload);
*/
var xdir = -.5;

function getmap() {
	var longitude = mapViewmodel.longitude();
	var latitude = mapViewmodel.latitude();
	if(mapViewmodel.autorotate()) {
		longitude+=1;
		if(longitude>180)
			longitude-=360;
		if(longitude<-180)
			longitude+=360;
		mapViewmodel.longitude(longitude);
	}
	/*
	latitude += xdir;
	if(latitude>=90 || latitude<=-90) {
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
		"longitude": longitude,
		"latitude": latitude,
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
	setTimeout(getmap, 500);
}

getmap();