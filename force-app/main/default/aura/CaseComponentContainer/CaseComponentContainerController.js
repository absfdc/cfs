({
	doInit : function(component, event, helper) {
        var str = component.get("v.recordId");
		var strsub = str.substr(0,3);
		console.log(strsub); 
        console.log(str);
        component.set("v.subString", strsub);
    }
})