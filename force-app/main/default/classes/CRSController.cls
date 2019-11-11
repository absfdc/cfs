public class CRSController{
public Case crsCase;
public Case c = null;
public string defaultContactmeNo;
public Map<String,String> ipType;
public Attachment attachment;
public String userMessage;
public boolean isSpam;
    
public Case getCrsCase() {
    return this.crsCase;
}
    
public void setCrsCase(Case crsCase) {
    this.crsCase = crsCase;
}    

public boolean getIsSpam() {
    return this.isSpam;
}
    
public void setIsSpam(Boolean isSpam) {
    this.isSpam = isSpam;
}    
    
public Case getC() {
    return this.c;
}
    
public void setC(Case c) {
    this.c = c;
}    
    
public String getDefaultContactmeNo() {
    return this.defaultContactmeNo;
}
    
public void setDefaultContactmeNo(String defaultContactmeNo) {
    this.defaultContactmeNo = defaultContactmeNo;
}    

public String getUserMessage() {
    return this.userMessage;
}
    
public void setUserMessage(String userMessage) {
    this.userMessage = userMessage;
}    

public Map<String,String> getIpType() {
    return this.IpType;
}
    
public void setIpType(Map<String,String> ipType) {
    this.ipType = ipType;
}    

    
public Attachment getAttachment(){
     if (attachment == null) attachment = new Attachment(IsPrivate = false);
     return attachment;
}

public void setAttachment(Attachment attachment) {
    this.attachment = attachment;
}    

    public CRSController()
    {
        defaultContactmeNo = 'No'; 
        crsCase=new Case();
        crsCase.Response_Requested__c = 'No';
        crsCase.Is_CRS__c = true;
        isSpam = false;
        userMessage = 'Thanks for your enquiry.';
    }
   
public void logError(Exception e){
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
      ApplicationLogMessage message= new ApplicationLogMessage();
      message.source='CRSController';
      message.sourceFunction='Save';
      message.logMessage=e.getMessage();
      message.ex=e;
      message.debugLevel='Error';
      messages.add(message);
      ApplicationLogUtility.logMessage(messages);
      messages.clear();
}
    
public pagereference Save()
    {   
        PageReference pg=Page.CRSThankYouPage;
        Contact crsContact = null;
        String ipAddress = null;
        String firstName = null;
        String lastName = null;
        integer fnl = 0;
        integer nl = 0;
        
        try{
            String name = crsCase.SuppliedName;
            nl = name.length();
            System.debug('Name: ' + name);
			
			crsCase.origin = 'Web';
            crsCase.Origin_Details__c = 'CRS';
            
            List<String> parts = name.split(' ');
            firstName = parts[0];
            fnl = firstName.length();
            System.debug('firstName: ' + firstName);
            
            if(fnl<nl) lastName = name.substring(firstName.length()+1);
            else lastName = parts[0];
            System.debug('firstName: ' + firstName + ' lastName: ' + lastName);
            
            List<RecordType> rt = [Select Id, DeveloperName From RecordType Where SobjectType = 'contact' and DeveloperName = 'Customer'];
            
            crsContact = new Contact();
            crsContact.RecordTypeId = rt[0].id;
            crsContact.phone = crsCase.SuppliedPhone;
            crsContact.email = crsCase.SuppliedEmail;
            crsContact.FirstName = firstName;
            crsContact.LastName = lastName;
            if (crsContact == null) System.debug('Contact cannot be initialized');

            Id crsQueueId = [Select Id, Name From Group Where Type = 'Queue' and name = 'Serco - Web Triage'].id;

            crsCase.Is_CRS__c=true;
            crsCase.OwnerId = crsQueueId;
            crsCase.subject = crsCase.CRS_Feedback_Type__c;
            
            ipType = ApexPages.currentPage().getHeaders();
            
            if(ipType.containsKey('True-Client-IP')) {
                ipAddress = 'True-Client-IP';
            } else if(ipType.containsKey('X-Salesforce-SIP')){
                ipAddress = 'X-Salesforce-SIP';
            }
            if(ipAddress != null) {
                crsCase.Users_Ip_address__c = ipType.get(ipAddress);
            }

            WebToCaseSpamChecker spamChecker = new WebToCaseSpamChecker(crsCase.Users_Ip_address__c);
            isSpam=spamChecker.isSuspectedSpam();
            
            if(!isSpam) {
            insert crsCase;
            c = [select id, casenumber from Case where id=:crsCase.id];
            system.debug('New CRS Case Number' + c.Casenumber );
            attachment.ParentId = c.id;
            //attachment.IsPrivate = false;
            if (attachment.Body!=null && attachment.Name!=null){
                system.debug('Trying to upload attachment');
                insert attachment;
                system.debug('Done uploading attachment');
            }
            
                system.debug('Trying to set Contact on Case');
                WebToCaseContactCreator contactCreator = new WebToCaseContactCreator(c, crsContact, ' ');
                contactCreator.createContact();
                system.debug('Done executing Matching Rules for Contact');
                update c;
                 } else {
                SuspectedSpamCaseLogger.logSpamCase(crsCase.Users_Ip_address__c, 'CRSController', 'Save');
            }
            
            system.debug('Calling Thank You Page');
            
            if(!isSpam) {
                if(c.casenumber != null) userMessage = userMessage+ ' Your case number registered with us: ' + c.casenumber;
                
                pg.getParameters().put('userMessage', userMessage);
                pg.setredirect(false);
            }                
            
        }catch(Exception e){
            System.debug('Unexpected Error Occured: ' + e.getMessage() + e.getStackTraceString());
            logError(e);
        }
        return pg;
        }
}