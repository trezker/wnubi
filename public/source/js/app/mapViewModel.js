var rotatey = 0;

$("#mapimage").css("height","100");
$("#mapimage").css("width","100");
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
		"radius": 50
	};

//	var img = document.createElement("img");  // Create with DOM
//	img.src = "http://dev.trezker.net/get?action=GetMap&perlinScale=0.5&octaves=8&persistence=0.5&lacunarity=2&rotatey="+rotatey+"&radius=50";
//	$("body").append(img);
	$("#mapimage").attr("src","http://dev.trezker.net/get?action=GetMap&perlinScale=0.5&octaves=8&persistence=0.5&lacunarity=2&rotatey="+rotatey+"&radius=50");
}

getmap();