var rotatey = 0;
var height = 100;
var width = 100;
var radius = 50;

$("#mapimage").css("height", height);
$("#mapimage").css("width", width);
$("#mapimage").on("load", function() {
	console.log("loaded");
	setTimeout(getmap, 10);
});

function getmap() {
	console.log("update");
	rotatey++;
	if(rotatey>360)
		rotatey-=360;
	var data = {
		"action": "GetMap",
		"perlinScale": 0.5,
		"octaves": 8,
		"persistence": 0.5,
		"lacunarity": 2,
		"rotatey": 1,
		"radius": radius,
		"width": width,
		"height": height
	};

//	var img = document.createElement("img");  // Create with DOM
//	img.src = "http://dev.trezker.net/get?action=GetMap&perlinScale=0.5&octaves=8&persistence=0.5&lacunarity=2&rotatey="+rotatey+"&radius=50";
//	$("body").append(img);
	$("#mapimage").attr("src","http://dev.trezker.net/get?action=GetMap&perlinScale=0.5&octaves=8&persistence=0.5&lacunarity=2&rotatey="+rotatey+"&radius="+radius+"&width="+width+"&height="+height);
}

getmap();