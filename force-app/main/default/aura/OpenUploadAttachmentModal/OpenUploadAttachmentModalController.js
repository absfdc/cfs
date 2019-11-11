({
    showModal : function(component, event, helper) {
        var caseId = component.get("v.recordId");
        console.log('caseId'+caseId);
        //document.getElementById("newClientSectionId").style.display = "block";
        $A.createComponent(
            'c:UploadAttachmentModal',
            {"caseId1":caseId},
            function(newComponent, status, errorMessage) {
                
                console.log(status);
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
})