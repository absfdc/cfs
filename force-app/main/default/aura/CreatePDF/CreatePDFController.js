({
   /* doInit : function(component, event, helper) {
        var str = component.get("v.recordId");
		var strsub = str.substr(0,3);
		console.log(strsub);     
        component.set("v.subString", strsub);
    },*/
    
	getInput : function(component, event, helper) {
        
        var caseRecId = component.get("v.recordId");
        console.log(caseRecId);
         window.open("/operatorportal/"+caseRecId+"/p?retURL=/"+caseRecId, "_blank");
		 //window.location.href='/operatorportal/5000l000000UwdvAAC/p?retURL=/5000l000000UwdvAAC';
	}
})

/*
	getInput : function(component, event, helper) {
         window.open("/operatorportal/5000l000000UPYFAA4/p?retURL=/5000l000000UPYFAA4", "_blank");
		 //window.location.href='/operatorportal/5000l000000UPYFAA4/p?retURL=/5000l000000UPYFAA4';
	}
})*/