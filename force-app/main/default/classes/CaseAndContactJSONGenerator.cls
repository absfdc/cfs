public class CaseAndContactJSONGenerator {
    
    public CaseAndContactJSONGenerator(String cfsAPIWebServiceEndpoint, String parentCaseId, String recordTypeId, String sessionId, String emailSubject, String emailBody, String ContactFirstName, String ContactLastName, String ContactEmail, Temp_Data_Holder__c aCaseAndContactData){

        CaseAndContactJSON cc = new CaseAndContactJSON(emailSubject, recordTypeId, 'Email', 'Individual - Standard', 'No', 'Complaint', 'Completed', 'Transport and Infrastructure', 'Routine', parentCaseId, emailBody, ContactFirstName, ContactLastName, ContactEmail);
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        
        gen.writeFieldName('Case');
        gen.writeStartObject();
        if (cc.theCase.subject!=null){
            gen.writeStringField('Subject', cc.theCase.subject);
        }
        gen.writeStringField('RecordTypeId', cc.theCase.RecordTypeId);
        if (cc.theCase.Origin!=null){
            gen.writeStringField('Origin', cc.theCase.Origin);
        }
        if (cc.theCase.Priority!=null){
            gen.writeStringField('Priority', cc.theCase.Priority);
        }
        if (cc.theCase.Response_Requested__c!=null){
            gen.writeStringField('Response_Requested__c', cc.theCase.Response_Requested__c);
        }
        if (cc.theCase.Type!=null){
            gen.writeStringField('Type', cc.theCase.Type);
        }
        if (cc.theCase.Status!=null){
            gen.writeStringField('Status', cc.theCase.Status);
        }
        if (cc.theCase.Portfolio__c!=null){
            gen.writeStringField('Portfolio__c', cc.theCase.Portfolio__c);
        }
        if (cc.theCase.Classification__c!=null){
            gen.writeStringField('Classification__c', cc.theCase.Classification__c);
        }
        if (cc.theCase.ParentId!=null){
            gen.writeStringField('ParentId', cc.theCase.ParentId);
        }
        if (cc.theCase.description!=null){
            gen.writeStringField('description', cc.theCase.description);
        }
        
        gen.writeEndObject();
        
        gen.writeFieldName('Contact');
        gen.writeStartObject();        
        if (cc.theContact.FirstName!=null){
            gen.writeStringField('FirstName', cc.theContact.FirstName);
        }
        if (cc.theContact.LastName!=null){
            gen.writeStringField('LastName', cc.theContact.LastName);
        }
        else gen.writeStringField('LastName', 'Not provided');
        if (cc.theContact.Email!=null){
            gen.writeStringField('Email', cc.theContact.Email);
        }
        gen.writeEndObject();
        
        gen.writeEndObject();
        if(gen!=null){
            system.debug('gen.getAsString() : '+gen.getAsString());
        }
        else system.debug('JSONGenerator produced no results');
        
        
        if(gen.getAsString()!=null)
            docallout(cfsAPIWebServiceEndpoint, sessionId, gen.getAsString(), aCaseAndContactData);
    }
    
    public void docallout(String cfsAPIWebServiceEndpoint, String sessionId, String jsonString, Temp_Data_Holder__c aCaseAndContactData){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        // req.setHeader('Authorization', 'OAuth: '+ sessionId);
        //req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setEndpoint(cfsAPIWebServiceEndpoint);    //'https://transportnsw--spdev.cs58.my.salesforce.com/services/apexrest/v1/salesforce/case'
        req.setBody(jsonString);
        req.setMethod('POST');
        if(!Test.isRunningTest())
	        res = http.send(req);
        system.debug ('result : ' + res.getbody());
        
        aCaseAndContactData.Results__c = res.getbody();
    }
    
}