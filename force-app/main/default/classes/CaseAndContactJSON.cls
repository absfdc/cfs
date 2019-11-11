public class CaseAndContactJSON {
    public Case theCase;
    public Contact theContact;
    
    public CaseAndContactJSON(String Subject, String RecordTypeId, String Origin, String Priority, String Response_Requested, String Type, String Status, String Portfolio, String Classification, String ParentId, String description, String contactFirstName, String contactLastName, String contactEmail){
        this.theCase = new Case();
        this.theContact = new Contact();
        
        theCase.Subject = Subject;
        theCase.RecordTypeId = RecordTypeId;
        theCase.Origin = Origin;
        theCase.Priority = Priority;
        theCase.Response_Requested__c = Response_Requested;
        theCase.Type = Type;
        theCase.Status = Status;
        theCase.Portfolio__c = Portfolio;
        theCase.Classification__c = Classification;
        theCase.ParentId = ParentId;
        theCase.description = description;
        
        theContact.FirstName = contactFirstName;
        theContact.LastName = contactLastName;
        theContact.Email = contactEmail;
        
        theCase.contact = theContact;
       
    }
    
}