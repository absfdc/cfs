global class BatchCaseContactCreation implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	
    String sessionId;
    String parentCaseId;
    String recordTypeId;
    String cfsAPIWebServiceEndpoint;
    
    public BatchCaseContactCreation(String sessionId, String parentCaseId, String recordTypeId, String cfsAPIWebServiceEndpoint){
        this.sessionId = sessionId;
        this.parentCaseId = parentCaseId;
        this.recordTypeId = recordTypeId;
        this.cfsAPIWebServiceEndpoint = cfsAPIWebServiceEndpoint;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Email_Subject__c, Email_Body__c, Contact_First_Name__c, Contact_Last_Name__c, Contact_Email__c, Results__c FROM Temp_Data_Holder__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Temp_Data_Holder__c> bulkCaseAndContactData) {
        for (Temp_Data_Holder__c aCaseAndContactData:bulkCaseAndContactData)
        {
            CaseAndContactJSONGenerator cc = new CaseAndContactJSONGenerator(cfsAPIWebServiceEndpoint, parentCaseId, recordTypeId, sessionId, aCaseAndContactData.Email_Subject__c, aCaseAndContactData.Email_Body__c, aCaseAndContactData.Contact_First_Name__c, aCaseAndContactData.Contact_Last_Name__c, aCaseAndContactData.Contact_Email__c, aCaseAndContactData);           
        }
        System.debug('Next Call...');
        update bulkCaseAndContactData;
    }   
    
    global void finish(Database.BatchableContext BC) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> recepientEmails = new List<String>();
        recepientEmails.add('gary.bakshi@transport.nsw.gov.au');
        email.setSubject('Salesforce Bulk CFS API Case Insertion Job Complete!');
        email.setHTMLBody('Salesforce Bulk CFS API Case Insertion Job Complete!');
        email.setToAddresses(recepientEmails);
        Messaging.sendEmail(New Messaging.SingleEmailMessage[]{email});
    }
}