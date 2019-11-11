({
    
    doInit:function(component, event, helper){
        helper.getMaximumRecordCount(component);
        helper.getColumnHeader(component);
    },
    
    setFileName : function(component, event, helper){
        console.log('In setFileName');
        var selectedFile = component.find("file").getElement().files[0].name;
        console.log('selectedFile :: ' + selectedFile);
        document.getElementById('selectedFileName').innerHTML = selectedFile;
    },
    
    readFile : function(component, event, helper) {
        
        var MAX_FILE_SIZE = component.get("v.maximumRecord");
        var csvHeadersColumnList = component.get("v.csvColumnHeaders");
        console.log('csvHeadersColumnList :: ' + csvHeadersColumnList);
        console.log('MAX_FILE_SIZE :: ' + MAX_FILE_SIZE);
        
		//disable upload button when clicked on upload file button
		var btn = event.getSource();
		//btn.set("v.disabled",true);
		var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        
        console.log('File length :: ' + fileInput.files.length);
        //check if file is selected or not
        if(fileInput.files.length == 0){
            //show error message if file is not selected and upload button is clicked
			helper.showToast(component, 
                             event, 
                             $A.get("$Label.c.ERRMSG_FILE_NOT_SELECTED"), 
                             '',
                             $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
            return;
        }
        
        var fileName = file.name;
        var fileLastIndex = fileName.lastIndexOf('.');
        var fileExtension = fileName.substring(fileLastIndex);
        console.log('FileExtension :: ' + fileExtension);
        
        
        
        // check if uploaded file is csv or not
        if(fileExtension != '.csv'){
           //Show error message when file is not csv
            helper.showToast(component,
                             event,
                             $A.get("$Label.c.ERROR_MESSAGE_FILE_FORMAT"),
                             '',
                             $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
            return; 
        }
        
        
		var fr = new FileReader();
        var toastEvent = $A.get("e.force:showToast");

		fr.onload = function() {
            
            var linesData = fr.result.split("\n");
            var headers = linesData[0].split(",");
            console.log('CSV Header :: ' + headers);
            
            var totalRows = linesData.length - 1;
            console.log('totalRows :: ' + totalRows );
            var headerMatches = true;
            for(var i= 1 ; i< headers.length; i++){
                if(csvHeadersColumnList.indexOf(headers[i].trim('')) < 0){
                    headerMatches = false;
                } 
            }         
            
            console.log('headerMatches :: ' + headerMatches);
			
            // check if the uploaded file is not in correct format            
            if(headerMatches === false){
                helper.showToast(component,
                                 event,
                                 $A.get("$Label.c.ERRMSG_FILE_COLUMN_MATCH"),
                                 '',
                                 $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
		 		return; 
            }
            
            // check if file has no any records (with or without header)
            if(totalRows < 1){
		 		//Show error message if csv does not contain any record
		 		helper.showToast(component, 
                                 event, 
                                 $A.get("$Label.c.ERRMSG_NO_RECORDS_IN_FILE"), 
                                 '',
                                 $A.get("$Label.c.ERROR_MESSAGE_TOAST"));
		 		return;
		 	}
            
            // check for maximum number of records
            
            	//show file processing message
            helper.showToast(component, 
                             event, 
                             $A.get("$Label.c.FILE_PROCESSING"), 
                             '',
                             $A.get("$Label.c.INFO_MESSAGE"));
            btn.set("v.disabled",true)
        	
            
            event.getSource().set("v.disabled",true);
	        helper.callServerSideAction(component, event, fr.result);
	    };
	    fr.readAsText(file);
	},

	
})