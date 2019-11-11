({
    showToast : function(component, event, message, title, msgType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": msgType
        });
        toastEvent.fire();
    },
    
    getMaximumRecordCount : function(component, event, fileContent){
        var getCountAction = component.get("c.getUploadRecordCount");
        getCountAction.setCallback(this, function(response){
            console.log('Inside getCountAction');
            var  status = response.getState();
            console.log(status);
            if(status === 'SUCCESS'){
                console.log('getCountAction :: ' + response.getReturnValue());
                component.set("{!v.maximumRecord}",response.getReturnValue());
            }	
            
        });
        $A.enqueueAction(getCountAction); 
    },
    
    getColumnHeader : function(component, event, fileContent){
        var columnHeaderAction = component.get("c.getCSVColumnHeaders");
        columnHeaderAction.setCallback(this, function(response){
            console.log('Inside getColumnHeader');
            var  status = response.getState();
            console.log('getColumnHeader status :: ' + status);
            if(status === 'SUCCESS'){
                console.log('getColumnHeader :: ' + response.getReturnValue());
                component.set("{!v.csvColumnHeaders}",response.getReturnValue());
            }	
            
        });
        $A.enqueueAction(columnHeaderAction); 
    },
    
    callServerSideAction : function(component, event, fileContent){
        event.getSource().set("v.disabled",true);
        var action = component.get("c.addRecordsCSV");
        
        action.setParams({
            "fileContent" : fileContent
        });
        
        action.setCallback(this, function(response){
            console.log('Inside setCallback');
            var  status = response.getState();
            console.log(status);
            
            var MAX_FILE_SIZE = component.get("v.maximumRecord");
            console.log('MAX_FILE_SIZE: ' + MAX_FILE_SIZE);
            if(!MAX_FILE_SIZE) MAX_FILE_SIZE = 100;
            
            if(status === 'SUCCESS'){
                console.log(response);
                component.set("{!v.successUploads}",response.getReturnValue());
                component.set("{!v.isSuccess}",true);
                console.log('Inserted records ::' + response.getReturnValue());
                
                if(response.getReturnValue() > MAX_FILE_SIZE) {
                    event.getSource().set("v.disabled",false);
                    this.showToast(component, 
                                   event, 
                                   $A.get("$Label.c.MAXIMUM_RECORD_SIZE") + ' ' + MAX_FILE_SIZE, 
                                   '', 
                                   $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
                } 
                else if(response.getReturnValue() < 1){
                    event.getSource().set("v.disabled",false);
                    this.showToast(component, 
                                   event, 
                                   $A.get("$Label.c.ERRMSG_NO_RECORDS_IN_FILE"), 
                                   '', 
                                   $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
                }
                
                else if(response.getReturnValue() == 1){
                        // refresh the view to show the new records
                        $A.get('e.force:refreshView').fire()
                        var message = response.getReturnValue()+' '+$A.get("$Label.c.STAGING_RECORDS_PROCESSED");
                        //Show success message with number of records uploaded
                        this.showToast(component, 
                                       event, 
                                       message, 
                                       '', 
                                       $A.get("$Label.c.SUCCESS_MESSAGE_TOAST"));
                }                    
                    
                    else if(response.getReturnValue() > 0){
                        // refresh the view to show the new records
                        $A.get('e.force:refreshView').fire()
                        var message = response.getReturnValue()+' '+$A.get("$Label.c.STAGING_RECORDS_PROCESSED");
                        //Show success message with number of records uploaded
                        this.showToast(component, 
                                       event, 
                                       message, 
                                       '', 
                                       $A.get("$Label.c.SUCCESS_MESSAGE_TOAST"));
                }
                else{
                            //Show error message if upload fails
                            event.getSource().set("v.disabled",false);
                            this.showToast(component, 
                                           event, 
                                           $A.get("$Label.c.BULK_UPLOAD_EXCEPTION"), 
                                           '', 
                                           $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
                            return;
                        }
                }
            	else{
                event.getSource().set("v.disabled",false);
                this.showToast(component, 
                               event, 
                               $A.get("$Label.c.BULK_UPLOAD_EXCEPTION"), 
                               '', 
                               $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
            	}
        });
        
        //$A.run(function() {
        $A.enqueueAction(action); 
        //});
    }
})