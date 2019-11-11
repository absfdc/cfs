({
    MAX_FILE_SIZE: 4500000, /* File Size : ~4 MB Because heap size doesn't allow more than this size*/
    CHUNK_SIZE: 614400, /* Chunk Size : 600 KB*/
    /*Utility function to display spinner*/
    showHideSpinner: function(component, show) {
        console.log('Showhide spinner called');
        var spinner = component.find("spinner");
        if (show) {
            $A.util.removeClass(spinner, "slds-hide");
        } else {
            $A.util.addClass(spinner, "slds-hide");
        }
    },
    
    /*Utility method to close modal.*/
    closeModal : function(component) { 
       $A.util.removeClass(component.find("theModal"), "slds-fade-in-open");
       $A.util.removeClass(component.find("modalBackdrop"),  "slds-backdrop--open");
   },
   
    /*Utility method to display toast on UI.*/
    showToast : function(message, title, msgType) {
        var toastEvent = $A.get("e.force:showToast");
	    toastEvent.setParams({
	        "title": title,
	        "message": message,
            "type": msgType
	    });
	    toastEvent.fire();
	},

    /*
     * This method will ochestrate the file upload process.
     * Read the file contents and determine the chunk size and initial load.
    */
    save : function(component,event,helper) {
    	console.log('Helper save called');
        var self = this;
        var fileInput = component.find("file").getElement();
    	var file = fileInput.files[0];
   		var filelength = fileInput.files.length;
    	
        // Check if file is not uploaded
        if(filelength == 0){
            this.showToast(
            $A.get("$Label.c.ERRMSG_FILE_NOT_SELECTED"), 
            '',
            $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
            return;
        }
        //check if file exceeds maximun file size specified
    	if(file.size > this.MAX_FILE_SIZE){
            console.log('File size error :: ' + filelength);
            this.showToast( $A.get("$Label.c.MAX_FILE_SIZE_ERROR"), 
                             '',
                             $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
            return;
        }
        this.showToast($A.get("$Label.c.FILE_UPLOADING"), 
                             	'',
                             	$A.get("$Label.c.INFO_MESSAGE"));
        self.showHideSpinner(component,true);
        
        // close the upload attachment modal

        var fr = new FileReader();
        fr.onload = $A.getCallback(function() {
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
    	    self.upload(component, file, fileContents.substring(dataStart));
        });

        fr.readAsDataURL(file);
    },
    //Method will create the initial chunk and calculate the from and to positions for chunking.
    upload: function(component, file, fileContents) {
        //this.showSpinner(component, event);
        console.log('Helper Upload called');
        var self = this;
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);
		// start with the initial chunk
        self.uploadChunk(component, file, fileContents, fromPos, toPos, '');   
    },
    //Method to upload file chunk to server. this will called recursively to upload all the chunks 
    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId) {
        console.log('Helper uploadChunk called');
        var self = this;
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);
		//Set action params
        action.setParams({
            parentId: component.get("v.caseId1"),
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId
        });
       
        action.setCallback(this, function(response) {
            attachId = response.getReturnValue();
            //if server success and attachement Id is not null
            if(response.getState() == 'SUCCESS' && attachId != null){
                //self.hideSpinner(component);
                //Calculate the positions
            	fromPos = toPos;
            	toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);
            	//Recursive call to uploadChunk
            	if (fromPos < toPos) {
            		self.uploadChunk(component, file, fileContents, fromPos, toPos, attachId);  
            	}else{
                    self.closeModal(component);
                    self.showHideSpinner(component,false);
                	console.log('File Inserted');
                    //Show success message with number of records uploaded
                    self.showToast( 
									$A.get("$Label.c.FILE_UPLOAD_PROCESSED"), 
									'', 
									$A.get("$Label.c.SUCCESS_MESSAGE_TOAST"));
                    $A.get('e.force:refreshView').fire();
            	}   
            }else{//If server failed and return error state
                self.closeModal(component);
                self.showHideSpinner(component,false);
				console.log('File Upload Failed');
                self.showToast($A.get("$Label.c.ERRMSG_ATTACHMENT_UPLOAD_FAILED"), 
									'', 
									$A.get("$Label.c.ERROR_MESSAGE_TOAST"));

            }
      
        });
        //Enqueue server action    
     	$A.enqueueAction(action); 
       
    }
})