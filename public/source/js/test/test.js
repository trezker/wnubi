function assertElementExists(selector) {
	if($("iframe#test").contents().find(selector).length == 0) {
		console.log(new Error("Element not found. Selector = " + selector));
	}
}

function wait(milliseconds) {
	return new Promise((resolve, reject) => {
		setTimeout(function() {
			resolve();
		}, milliseconds);
	});
}

var TestSuite = function() {
	var self = this;
	self.iFrameDOM = $("iframe#test").contents();

	self.tests = ["Log_in"];
	self.currentTest = 0;

	self.run = function() {
		console.log("Running tests");
		self.currentTest = 0;
		self.next();
	};

	self.next = function() {
		if(self.currentTest >= self.tests.length) {
			console.log("Done");
			return;
		}
		console.log("Test: " + self.tests[self.currentTest].replace("_", " "));
		self[self.tests[self.currentTest]]().then(() => {
			self.teardown();
			self.currentTest++;
			self.next();
		});
	};

	self.teardown = function() {
	};

	self.Log_in = function() {
		return new Promise((resolve, reject) => {
			$(self.iFrameDOM.find("input")[0]).sendkeys("a");
			$(self.iFrameDOM.find("input")[1]).sendkeys("a");

			wait(1).then(() => {
				$(self.iFrameDOM.find("button")[1]).click();
				return wait(1000);
			}).then(() => {
				assertElementExists("[data-bind='click: sign_out']");
				resolve();
			});
		});
	};

	self.create_event = function() {
		google.maps.event.trigger(eventViewModel.map, 'click', {
			latLng: new google.maps.LatLng(37, -122)
		});
	};
};

var runOnce = false;
function iframeLoaded() {
	if(runOnce) {
		return;
	}
	runOnce = true;
	var suite = new TestSuite();
	suite.run();
}

$("#test").attr("src", "/");
