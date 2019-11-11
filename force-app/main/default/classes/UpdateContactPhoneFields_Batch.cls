global class UpdateContactPhoneFields_Batch implements Database.Batchable<sObject>, Database.Stateful {
	global final String contactQuery;
	List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

	global UpdateContactPhoneFields_Batch() {
		contactQuery = 'SELECT Id, MobilePhone, HomePhone, Phone, Other_Phone__c FROM Contact WHERE HomePhone != \'\' OR MobilePhone != \'\' OR Other_Phone__c != \'\' OR Phone != \'\' ' ;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('contactQuery: '+contactQuery);
		return Database.getQueryLocator(contactQuery);
	}

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Contact> contactsToBeUpdated = new List<Contact>();
        
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.DuplicateRuleHeader.AllowSave = true;
        if(Test.isRunningTest()){
            dmlOpt.DuplicateRuleHeader.AllowSave = false;
        }
        
        NormalizePhoneFieldHandler obj = new NormalizePhoneFieldHandler();
        for(contact con : (List<Contact>)scope){
            con = obj.normalizePhoneFields(con);
            contactsToBeUpdated.add(con);
        }
        
        Database.SaveResult[] srList = Database.update(contactsToBeUpdated, dmlOpt);
        
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {          
                for(Database.Error err : sr.getErrors()) {
                    ApplicationLogMessage message= new ApplicationLogMessage();
                    message.source='UpdateContactPhoneFields_Batch';
                    //message.sourceFunction='execute';
                    message.logMessage=err.getMessage();
                    //message.debugLevel='Error';
                    messages.add(message);
                }
            }
        }
    }
	
	global void finish(Database.BatchableContext BC) {
		ApplicationLogUtility.logMessage(messages);
	}	
}