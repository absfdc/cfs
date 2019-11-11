/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This is generic class which will be used for URL hacking and setting the 
			   default values to fields when new record is created. This class will be invoked 
			   when user will click on custom new button.

			   --Parameters--
			   oname    : Object Name
			   allowRTS : Record Type (yes/1/true)
			   parentId : Record Id from which custom button was clicked
			   isConsole: If set to 1 then this will allow the page to be opened in the console.
			   
Test Class:    RedirectWithDefaultFieldValues_CC_Test
History
16/04/2015     Manish Damle       Created
-----------------------------------------------------------------------------------*/
public with sharing class RedirectWithDefaultFieldValues_CC {
    
    public String pRefURL {get;set;}
    public boolean errorOnPage  {get;set;}
    private String parentObjectName;
    private Id recordTypeProvidedViaURL;
    /*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method will redirect user to edit page of the Object and with 
				   prepopulated fields.
	Inputs: 
	
	History
	16/04/2015     Manish Damle       Created
	14/05/2015     Manish Damle       Updated. Added Support for Custom Lookups.
	-----------------------------------------------------------------------------------*/
    public PageReference redirectUser() {
        pRefURL = '';
        errorOnPage = false;
        //Take the URL param
    	String objectName = ApexPages.currentPage().getParameters().get('oname');
        String allowRecordTypeSelection = System.currentPageReference().getParameters().get('allowRTS');
        String parentRecordId = System.currentPageReference().getParameters().get('parentId');
        
        try {
        	//if object name is not passed then return error
        	if(objectName == null || objectName == '') {
        		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Invalid Parameters'));
        		return null;
        	}
        	
            system.debug('-----Object Name-----' + objectName);
            system.debug('-----Parent Id-----' + parentRecordId);
            system.debug('-----allowRTS----' + allowRecordTypeSelection);
            
            //Get Sobject type for further use
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);   
            if(!objectType.getDescribe().isCreateable()) {
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'You do not have permission to create record.'));
        		return null;
            }
            
			//Check if we have to use record type selection or not
            if(allowRecordTypeSelection != '' 
               	&& (allowRecordTypeSelection == 'true' || 
                    allowRecordTypeSelection == '1' || 
                    allowRecordTypeSelection == 'yes')) { 
                //if record type selection is required then redirect user to recordtypeselect.jsp
                if(objectType.getDescribe().custom) {
                    String sobjectDevName = objectType.getDescribe().getName().replaceAll('__c', '');
					EntityDefinition ed = [Select Id,DeveloperName From EntityDefinition Where DeveloperName =: sobjectDevName];
					String objectId = '01I' + ((String) ed.Id).subString(3,15);
                    pRefURL = '/setup/ui/recordtypeselect.jsp?ent=' + objectId + '&save_new_url=/' + objectType.getDescribe().getKeyPrefix() + '/e?';                   
                } else {
                    pRefURL = '/setup/ui/recordtypeselect.jsp?ent=' + objectType.getDescribe().getName() + '&save_new_url=/' + objectType.getDescribe().getKeyPrefix() + '/e?';   
                }
            } else {
                pRefURL = '/' +  objectType.getDescribe().getKeyPrefix() + '/e?';
            }
            
            //Get all current parameters - this could be either edit page or the record type selection.
            map <String, String> currentParameters = new map <String, String>();
            currentParameters.putAll(getFieldsWithDefaultValues(objectName, parentRecordId, objectType));
            currentParameters.put('nooverride', '1');
            String retUrl = ApexPages.currentPage().getParameters().get('retURL');
            if(retUrl == null || retUrl == '') { //%2F for slash
            	retUrl = parentRecordId != null && parentRecordId != '' ? '%2F' + parentRecordId : '%2F' + objectType.getDescribe().getKeyPrefix();
            }
            currentParameters.put('retURL', retUrl);
            if(ApexPages.currentPage().getParameters().get('isConsole') != null && ApexPages.currentPage().getParameters().get('isConsole') == '1') {
            	currentParameters.put('isdtp', 'vw'); //This parameter is hard coded for Console. This will open the tab in Console fasion.
            }
            system.debug('----Constructing URL---');
            //Call the tooling api for additinal parameters to build
            pRefURL = pRefURL +  constructURL(currentParameters);
            system.debug('-----Final URL---' + pRefURL);
            pRefURL = pRefURL.replaceAll('%0D%0A', '<br/>'); //hack to preserve newline characters. 
            pRefURL = pRefURL.replaceAll('%0A', '<br/>'); 
            system.debug('-----Final URL After BR---' + pRefURL);
        } catch(Exception e) {
        	system.debug('----Exception While Redirecting---' + e.getMessage() + '---LINE---' + e.getLineNumber());
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'RedirectWithDefaultFieldValues_CC';
            message.sourceFunction = 'redirectUser';
            message.referenceInfo = 'Check Record type and permission set assignment for user ' + UserInfo.getName();
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = 'Error';
            ApplicationLogUtility.logMessage(message);
            Application_Log__c anApplog= new Application_Log__c(Debug_Level__c='Error',
		                                                        Integration_Payload__c= null,
		                                                        Log_Code__c= null,
		                                                        Message__c= e.getMessage(),
		                                                        Reference_Id__c= null,
		                                                        Reference_Info__c='Check Record type and permission set assignment for user ' + UserInfo.getName(),
		                                                        Source__c= 'RedirectWithDefaultFieldValues_CC',
		                                                        Source_Function__c= 'redirectUser',
		                                                        Stack_Trace__c= e.getStackTraceString(),
		                                                        Timer__c= null);
            insert anApplog;
            list<Application_Log__c> logs = [Select Id, Name From Application_Log__c Where Id =: anApplog.Id];
            String transactionId = logs.size() > 0 ? logs[0].Name : 'Not Available';
            String msg = 'Error: You do not have the appropriate permission to create this record type.<br/><br/>';
            msg += 'If you feel you received this in error, please contact your system administrator and reference transaction ID: ' + transactionId;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,msg));
            errorOnPage = true;
        } 
        return null;
    }
    
    /*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method will create a map of Field Id and Values
	Inputs: 	   Object Name, parentRecordId, SobjectType
	
	History
	16/04/2015     Manish Damle       Created
	-----------------------------------------------------------------------------------*/
	@testVisible
    private map<String, String> getFieldsWithDefaultValues(String objectName, String parentRecordId, Schema.SObjectType objectType) {
    	map <String,String> fieldsWithDefaultValues = new map <String,String> ();
    	map <String,String> apiFields = getConfiguredFieldNames(objectType, parentRecordId);
    	sObject parentRecord = fetchParentRecordDetails(apiFields.values(), parentRecordId);
    	Map<String, DescribeFieldResult> objectFieldsMetadata =  new map <String, DescribeFieldResult>();
    	
    	//Create map of field api name and fied metadata
    	for (SObjectField field : objectType.getDescribe().fields.getMap().values()) {
    		DescribeFieldResult f = field.getDescribe();
    		objectFieldsMetadata.put(f.getName(), f);	
            system.debug('------ObjectFieldsMetadata------' + f.getName());
    	}
    	
    	
    	system.debug('------Parent Record------' + parentRecord);
    	//If parent record is null then we dont have to do anything
    	if(parentRecord != null) {
    		//fetch the custom field ids using tooling API
    		//WITH TOOLING API
    		//map <String, String> fieldApiNameVsId = getCustomFieldApiNameVsIdMap(objectName);
    		//WITHOUT TOOLING API
    		map <String, String> fieldApiNameVsId = getCustomFieldApiNameVsIdMap(objectType);
    		Id pId = Id.valueOf(parentRecordId); 
    		system.debug('------parentObjectName------' + parentObjectName);
    		for(String fieldName : apiFields.keySet()) {
    			//Tooling API returns DeveloperName without __c hence remove that form api name
    			String apiName = fieldName.replace('__c','');
    			String strValue = '';
                system.debug('-----API Field NAME---' + apiName + '----Field NAME---' + fieldName) ;
    			if(fieldApiNameVsId.containsKey(apiName)) {
                    system.debug('-----Field---' + apiName + '---Type----' + objectFieldsMetadata.get(fieldName));
					String fId = fieldApiNameVsId.get(apiName);
					DescribeFieldResult f = objectFieldsMetadata.get(fieldName);
					//Check for field type and then convert the value to appropriate string
					if (f.getType() == DisplayType.Date) {
		                strValue = parentRecord.get(apiFields.get(fieldName)) == null ? null : ((Date) parentRecord.get(apiFields.get(fieldName))).format();
		                strValue = strValue == null ? '' : EncodingUtil.urlEncode(strValue,'UTF-8');
		            } else if (f.getType() == DisplayType.Datetime) {
		                strValue = parentRecord.get(apiFields.get(fieldName)) == null ? null : ((Datetime) parentRecord.get(apiFields.get(fieldName))).format();
		                strValue = strValue == null ? '' : EncodingUtil.urlEncode(strValue,'UTF-8');
		            } else if (f.getType() == DisplayType.Boolean) {
		                strValue = ((Boolean) parentRecord.get(apiFields.get(fieldName))) ? '1' : '0';
		            } else if(f.getType() ==  DisplayType.MultiPicklist) {
		            	//Generate the value as url fieldId = single values of the picklist
		            	strValue = ((String) parentRecord.get(apiFields.get(fieldName)));
		            	if(strValue != null && strValue.contains(';')) {
		            		string multiSelectValues = '';
		            		list <String> values = strValue.split(';');
		            		for(integer i = 0 ; i < values.size() ; i++) {
		            			if(i == 0) {
		            				multiSelectValues += EncodingUtil.urlEncode(values[0],'UTF-8');
		            			} else {
		            				multiSelectValues += '&' + fId + '=' + EncodingUtil.urlEncode(values[i],'UTF-8');
		            			} 
		            		} 
		            		strValue = multiSelectValues;
		            		system.debug('---MULTISELECT---' + strValue);		            		
		            	}
		            } else {
		                strValue = String.valueOf(parentRecord.get(apiFields.get(fieldName)));
		                strValue = strValue == null ? '' : EncodingUtil.urlEncode(strValue,'UTF-8');
		            }
		            
		            //Lookup field
		            if(f.getReferenceTo().size() > 0){
		            	system.debug('--------Lookup Field--------' + parentObjectName + '--FID--' + fId);
		            	String fId_lkid = fId.startsWith('CF') ? fId + '_lkid' : 'CF' + fId + '_lkid';
                        if(f.getReferenceTo()[0] == pId.getSobjectType()) { //This is parent lookup
                            fieldsWithDefaultValues.put(fId_lkid , parentRecordId); // Populate hidden field value
                            String Name = '';
                            if(parentObjectName != 'Case') {
                                Name = (String) parentRecord.get('Name');
                            } else {
                                Name = (String) parentRecord.get('CaseNumber');
                            }
                            
                            Name = Name == null ? '' : EncodingUtil.urlEncode(Name,'UTF-8');
                            String fId_display_name = fId.startsWith('CF') ? fId : 'CF' + fId;
                            fieldsWithDefaultValues.put(fId_display_name, Name); //Diplay Name in the field
                        } else { //This is custom lookup field
                            if(strValue == null || strValue == '')
                                continue;
                            
                            try {
                                String Name = '';
                                Id recordId = Id.valueOf(strValue);
                                String objetName = recordId.getSobjectType().getDescribe().getName();
                                system.debug('--------Lookup Objet Name--------' + objetName);
                                if(objetName == 'Case') {
                                    Case c = [Select Id, CaseNumber From Case Where Id =: recordId];
                                    Name = c.CaseNumber;
                                } else {
                                    String query = 'Select Id, Name From ' + objetName + ' Where Id =:recordId limit 1';
                                    Sobject obj = Database.query(query);
                                    Name = (String) obj.get('Name');
                                }                                
                                fieldsWithDefaultValues.put(fId_lkid , recordId);
                                Name = Name == null ? '' : EncodingUtil.urlEncode(Name,'UTF-8');
                            	String fId_display_name = fId.startsWith('CF') ? fId : 'CF' + fId;
                            	fieldsWithDefaultValues.put(fId_display_name, Name); //Diplay Name in the field
                            }catch(Exception ee) {
                                System.debug('-----Lookup Field Not Populated---' + ee.getMessage() + '--LINE--' + ee.getLineNumber());
                            }
                        }
 		            } else {

                        //SFCOE-1314 If description > 7000 Characters, display custom message and don't try to pre-populate description as that will break URL Hacking - Start
                        
                        System.debug('apiName:: ' + apiName + ' Value:: ' + strValue);
                        
                            if(apiName.equalsignorecase('Case_Description'))
                            {
	                            System.debug('fieldApiNameVsId.get(fId):: ' + apiName);
    	                    	if (strValue.length() > 7000) fieldsWithDefaultValues.put(fId,Label.Field_size_is_too_large);
                                else fieldsWithDefaultValues.put(fId,strValue);
                            }
                        	else fieldsWithDefaultValues.put(fId,strValue);
                        
                        //SFCOE-1314 - End

                    }
    			} //End If
    		}//End for
    		
    		//Check for record type
    		String recordTypeName = ApexPages.currentPage().getParameters().get('RecordType');
    		if(recordTypeName != null && recordTypeProvidedViaURL != null) {
				 fieldsWithDefaultValues.put('RecordType', recordTypeProvidedViaURL);
			 }		                                         
    	   }
    	system.debug('------Fields With Default Values------' + fieldsWithDefaultValues);
		return fieldsWithDefaultValues;
	}
	
	/*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method will fetch the parent record details if parent id is provided.
	Inputs: 	   list of fields from custom settings configured for sObject, parent record id, sobjectType
	
	History
	16/04/2015     Manish Damle       Created
	-----------------------------------------------------------------------------------*/
	@testVisible
	private sObject fetchParentRecordDetails(list <String> apiFields, String parentRecordId) {
		system.debug('------fetchParentRecordDetails Parent Record------' + parentRecordId);
		//if parent id is null or apiFields are not configured then don't do anything
		if(parentRecordId == null || parentRecordId == '' || apiFields.isEmpty())
			return null;	
        
		String query = 'Select ';
		//Build query dynamically
		for(String fieldName : apiFields) {
			if(fieldName == 'Id' || fieldName == 'Name') continue;
			query += fieldName + ', ';
		}
		
		if(parentObjectName == 'Case') //Case has no Name field
			query += 'Id, CaseNumber From ' + parentObjectName + ' Where Id=: parentRecordId limit 1';
		else			
			query += 'Id, Name From ' + parentObjectName + ' Where Id=: parentRecordId limit 1';
		
		list <sObject> records = Database.query(query);
		system.debug('----Parent Record ----' + records); 
		if(records.size() > 0)
			return records[0];
			
		return null;
	}
	
 	/*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method will create list of field names from the custom settings for given object.
	Inputs: 	   sobjectType
	
	History
	16/04/2015     Manish Damle       Created
	-----------------------------------------------------------------------------------*/
	@testVisible   
    private map <String, String> getConfiguredFieldNames(Schema.SObjectType objectType, String parentRecordId) {
    	map <String, URLPopulatedFieldsConfiguration__c> configuredFields = URLPopulatedFieldsConfiguration__c.getAll();
		map <String, String> fieldApiNames = new map <String, String>();
		Id pId = Id.valueOf(parentRecordId);
        String pObjectName = pId.getSobjectType().getDescribe().getName();
		for(String key : configuredFields.keySet()) {
			if(configuredFields.get(key).Object_Name__c != null 
				&& configuredFields.get(key).Field_Name__c != null 
				&& configuredFields.get(key).Object_Name__c.equalsIgnoreCase(objectType.getDescribe().getName())
                && configuredFields.get(key).Parent_Object_Name__c.equalsIgnoreCase(pObjectName)){
					
				fieldApiNames.put(configuredFields.get(key).Field_Name__c,configuredFields.get(key).Parent_Field_Name__c);
                parentObjectName = configuredFields.get(key).Parent_Object_Name__c;
               system.debug('-----Field Name----' + configuredFields.get(key).Field_Name__c + ' => ' +  configuredFields.get(key).Parent_Field_Name__c);
			}
		}
		 
		return fieldApiNames;
    }	
    
 	
    /*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This function will construct the URL.
				   Parameter serialization will not allow duplicate field id in param map.
				   For setting the multiselect picklist values we need to add same field id 
				   and for different values.
				   a;b;c;
				   URL will look like FIELDID=a&FIELDID=b&FIELDID=c where FIELDID is Multiselect picklist field id. 
				   
	Inputs: 	   Page parameters
	
	History
	16/04/2015     Manish Damle       Created
	-----------------------------------------------------------------------------------*/
	@testVisible 
    private String constructURL(map <String, String> params) {
    	String urlStr = ''; 
    	for(String paramName : params.keySet()) {
    		String value = params.get(paramName);
    		urlStr += paramName + '=' + value + '&';
    	}
    	system.debug('------URL String----' + urlStr);
    	return urlStr;
    }
    
    
	/*-----------------------------------------------------------------------------------
	Author:        Manish Damle
	Company:       Arxxus.com
	Description:   This method will parse the page markup and then creates field apiname and field id map
	Inputs: 	   Object Name
	
	History
	24/04/2015     Manish Damle       Created
	24/06/2015     Manish Damle       Added new pattern for assistiveText span
	-----------------------------------------------------------------------------------*/
    public map <String, String> getCustomFieldApiNameVsIdMap(Schema.SObjectType objectType) {
     	map <String, String> customFieldApiNameVsId = new map <String, String> ();
        PageReference pEditReference;
        
        String recordTypeName = ApexPages.currentPage().getParameters().get('RecordType');
        
        if(recordTypeName != null) {
            list <RecordType> recordTypes = [Select Id
                                             From RecordType
                                             Where DeveloperName =: recordTypeName
                                             And SObjectType =: objectType.getDescribe().getName()];
           if(recordTypes.size() > 0) 
           	  recordTypeProvidedViaURL = recordTypes[0].Id; 
        }
        
        if(recordTypeProvidedViaURL != null) {
           	pEditReference = new PageReference('/' +  objectType.getDescribe().getKeyPrefix() + '/e?RecordType=' + recordTypeProvidedViaURL);
        } else {
     		pEditReference = new PageReference('/' +  objectType.getDescribe().getKeyPrefix() + '/e');
        }
        
        pEditReference.setRedirect(false);
     	//store the html from the page reference
        String html = '';
        if (test.isRunningTest()){
            html += '<label for="00NO0000001au9F"><span class="requiredMark">*</span>Level 1 Value</label>';
            html += '<label for="00NO0000001aZKR"><span class="requiredMark">*</span>Type</label>';
            html += '<label for="00NO0000001aZKg"><span class="requiredMark">*</span>Modes</label>';
            html += '<label for="CF00NO0000001aZKl">Parent Id</label>';
            html += '<label for="00NO0000001aZKv"><span class="requiredMark">*</span>Value</label>';
        }
        else{
            //get the HTML contents
            html = pEditReference.getContent().toString();      
        }
        
        Map<String, String> labelVsFieldId = new Map<String, String>();
        Matcher m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(<span class="assistiveText">\\*</span>)?(.*?)</label>').matcher(html);
        while (m.find()) {
            //Label is stored in the 4th column 
            String label = m.group(4); 
            
            //Id is stored in the second column
            String id = m.group(1);
            
            //Add it to the map (split on _, on occasion we have a _top somewhere)
            labelVsFieldId.put(label, id.split('_')[0]);                  
        } 
        system.debug('------labelVsFieldId size---' + labelVsFieldId.size());
        for (SObjectField field : objectType.getDescribe().fields.getMap().values()) {
    		DescribeFieldResult f = field.getDescribe();
    		if(labelVsFieldId.containsKey(f.getLabel())) {
                system.debug('------Custom Field Api Name Vs Id---' + f.getName() + ' => ' + labelVsFieldId.get(f.getLabel()));
    			customFieldApiNameVsId.put(f.getName().replace('__c',''), labelVsFieldId.get(f.getLabel()));
    		}
    	}

     	return customFieldApiNameVsId;
     }
}