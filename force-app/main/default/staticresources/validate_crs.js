console.log("validate_crs loading...");

j$ = jQuery.noConflict();
j$(document).ready(function() {
	console.log("jquery is loaded");

});
String.prototype.trim = function() { return this.replace(/^\s+|\s+$/g, ''); }

function isEmail(address) {
	var reg = /^[A-Za-z0-9\._\+\-\!\#\$\%\&\'\*\/\=\?\^\`\{\|\}\~]+@[A-Za-z0-9.-]+\.([A-Za-z]{2,4}|museum)$/;
	if(reg.test(address)) {
		return true;
	}
	return false;
}

function okay(){
	console.log("validate_crs running okay() function...");
	//return false;
	
	j$("input[id$=':name']").css("backgroundColor","#fff");
	j$("input[id$=':email']").css("backgroundColor","#fff");
	j$("textarea[id$=':enquirycomment']").css("backgroundColor","#fff");

	if (j$("input[id$=':name']").val().trim() == '') {
		alert("Please enter your name");	
		j$("input[id$=':name']").css("backgroundColor","#FF9933");
		j$("input[id$=':name']").focus();
		return false;
	}
	console.log("email", j$("input[id$=':email']").val());
	if (!isEmail(j$("input[id$=':email']").val())) {
		alert("Please enter in a valid email address");
		j$("input[id$=':email']").css("backgroundColor","#FF9933");
		j$("input[id$=':email']").focus();
		return false;
	}

	if (j$("textarea[id$=':enquirycomment']").val().trim() == '') {
		alert("Please enter a message");	
		j$("textarea[id$=':enquirycomment']").css("backgroundColor","#FF9933");
		j$("textarea[id$=':enquirycomment']").focus();
		return false;
	}
	
	return true;
}