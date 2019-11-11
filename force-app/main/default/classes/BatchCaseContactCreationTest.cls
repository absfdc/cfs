@isTest
public class BatchCaseContactCreationTest {
    
    static testMethod void testMethod1() 
    {
        Database.BatchableContext BC;
        
        RecordType rtcm = [Select Id From RecordType where developername  = 'CampaignMember'];
        RecordType rtc = [Select Id From RecordType where developername  = 'Campaign'];
        String cfsAPIWebServiceEndpoint = 'https://transportnsw--spdev.cs58.my.salesforce.com/services/apexrest/v1/salesforce/case';
        
        Case campaign = getCaseRecord();
        campaign.Subject = 'CAMPAIGN';
        campaign.Taxonomy_Moment__c = 'A';
        campaign.Taxonomy_Transaction__c = 'B';
        campaign.Taxonomy_Location_Type__c = 'C';
        campaign.Taxonomy_Symptom__c = 'D';
        campaign.RecordTypeId = rtc.Id;  
        insert campaign;
        
        User us = [Select id from User where Id = :UserInfo.getUserId()];
        
        Temp_Data_Holder__c inboundEntry = new Temp_Data_Holder__c();
        inboundEntry.EMAIL_SUBJECT__C = 'Uber tax';
        inboundEntry.EMAIL_BODY__C = 'Im utterly disgusted that the nsw govenment think its fair to empose this tax';
        inboundEntry.CONTACT_FIRST_NAME__C = 'Justin';
        inboundEntry.CONTACT_LAST_NAME__C = 'A';
        inboundEntry.CONTACT_EMAIL__C = 'justmatel@hotmail.com';
        
        insert inboundEntry;
        
        System.runAs(us){
            Test.startTest();
            
            BatchCaseContactCreation obj = new BatchCaseContactCreation(userinfo.getSessionId(), campaign.Id, rtcm.Id, cfsAPIWebServiceEndpoint);
            DataBase.executeBatch(obj);
            obj.finish(BC);
            
            Test.stopTest();
        }
    }
    
    private static Case getCaseRecord() {
        return new Case(Status = 'Registered', Subject = 'Campaign Testing', Description = 'Campaign Testing Description');
    }
    
}