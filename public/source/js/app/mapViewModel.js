var rotatey = 0;
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

function getmap() {
	//console.log("update");
	rotatey+=0.1;
	if(rotatey>360)
		rotatey-=360;
	var data = {
		"action": "GetMap",
		"perlinScale": 0.5,
		"octaves": 8,
		"persistence": 0.5,
		"lacunarity": 2,
		"rotatey": rotatey,
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