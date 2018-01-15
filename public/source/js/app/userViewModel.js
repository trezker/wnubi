var userViewModel = function() {
	var self = this;
	self.sign_out = function() {
		var data = {};
		data.action = "Logout";
		ajax_post(data).done(function(returnedData) {
		    if(returnedData.success == true) {
	    		window.location.href = window.location.href;
		    }
		});
	};
};

ko.applyBindings(new userViewModel(), document.getElementById('header'));