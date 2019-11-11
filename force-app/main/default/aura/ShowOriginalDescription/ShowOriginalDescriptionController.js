({
    
        viewDesc : function(component, event, helper) {
        var action = component.get("c.getOrigianlDescription");
        
        action.setParams({ caseId : component.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.originalDesc", response.getReturnValue());
                var desc = component.get("v.originalDesc");
                if(desc == null || desc == '') {
                    alert('This case is uncensored');
                } else {
                    if (confirm('Warning: You have requested to see the uncensored description which may contain profanity, unauthorized web links or other offensive data.\n\nIf you are uncertain what this means, choose cancel.')) {
                        $A.createComponent(
                        'c:OriginalDescription',
                        {"originalDesc":desc},
                            function(newComponent, status, errorMessage) {
                                if (status === "SUCCESS") {
                                    component.set("v.body", newComponent);
                                } else if (status === "INCOMPLETE") {
                                    console.log("No response from server or client is offline.");
                                } else if (status === "ERROR") {
                                    console.log("Error: " + errorMessage);
                                }
                            }
                        );
                    }
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action); 
    }
})