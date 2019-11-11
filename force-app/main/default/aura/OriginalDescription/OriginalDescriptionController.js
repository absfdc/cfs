({
	doInit : function(component, event, helper) {
       console.log("UploadAttachmentModal INIT");
       $A.util.addClass(component.find("theModal"), "slds-fade-in-open");
       $A.util.addClass(component.find("modalBackdrop"),  "slds-backdrop--open"); 
   },
	closeAction : function(component, event, helper) { 
       $A.util.removeClass(component.find("theModal"), "slds-fade-in-open");
       $A.util.removeClass(component.find("modalBackdrop"),  "slds-backdrop--open");
   },
})