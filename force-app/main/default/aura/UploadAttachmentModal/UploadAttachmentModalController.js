({
   doInit : function(component, event, helper) {
       console.log(component.get("v.caseId1"));
       console.log("UploadAttachmentModal INIT");
       $A.util.addClass(component.find("theModal"), "slds-fade-in-open");
       $A.util.addClass(component.find("modalBackdrop"),  "slds-backdrop--open"); 
   }, 
   
   closeAction : function(component, event, helper) { 
       $A.util.removeClass(component.find("theModal"), "slds-fade-in-open");
       $A.util.removeClass(component.find("modalBackdrop"),  "slds-backdrop--open");
   },
    
   setFileName : function(component, event, helper){
       console.log('In setFileName');
       var selectedFile = component.find("file").getElement().files[0].name;
       console.log('selectedFile :: ' + selectedFile);
       document.getElementById('selectedFileName').innerHTML = selectedFile;
   },
    
   save : function(component, event, helper) {
       console.log('Controller Save called');
       helper.save(component,event, helper);
   },
    
           
})