public class ReassignForPL {//without sharing 
    /*------------------------------------------------------------
Author:        Arxxus
Description:   This class is used to perform custom Re-Assign functionality.
Test Class:    
History
<Date>        <Authors Name>     <Brief Description of Change>
16-APR-2018   Ankur Jaiswal       
------------------------------------------------------------*/
    
    String caseId;
    public Case newCase {get; set;}
    public ReassignForPL(ApexPages.StandardController controller) {
        Id id = ApexPages.currentPage().getParameters().get('id');
        this.newCase=(Case)controller.getRecord(); 
    }
    
    public ReassignForPL() {
        
    }
    
    public pagereference searchdata() {
        try{                
            if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
                caseId = System.currentPagereference().getParameters().get('Id');
            }
            
            //Send email to change owner of the approval process
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            List<String> reassignEmailServiceToAddress = getReassignEmailServiceAddress();
            if (reassignEmailServiceToAddress!=null && !reassignEmailServiceToAddress.isEmpty())
            {
                mail.setToAddresses(reassignEmailServiceToAddress);
                mail.setSenderDisplayName('Salesforce Requests');
                mail.setSubject('Case Reassignment Request for Case: ' + caseId + 'To: ' + '--' + newCase.ownerId);
                mail.setPlainTextBody(caseId + '--' + newCase.ownerId);
                Messaging.SendEmailResult[] oResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });        
                
                if (!oResults[0].success) {
                    System.debug('Email could not be sent');
                }
            }            
            
            newCase.MO_User__c = newCase.ownerId;
            newCase.ownerId = newCase.ownerId;
            Update newCase;
            
            if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
                caseId = System.currentPagereference().getParameters().get('Id');
                PageReference pageRef = new PageReference('/' + caseId);
                System.debug('Returning back to Case after successful transfer...');
                return pageRef;
            }
            
            
        }Catch(Exception e) {
            System.debug('-------Exception-----' + e.getLineNumber() + e.getMessage() + e.getStackTraceString());
            
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source = 'ReassignForPL';
            message.sourceFunction='searchdata';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }            
        return null;
    }
    
    public PageReference Cancel() {
        if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
            caseId = System.currentPagereference().getParameters().get('Id');
            PageReference pageRef = new PageReference('/' + caseId);
            System.debug('Returning back on click of cancel button...');
            return pageRef;
        }
        
        return null;
    }
    
    
    public static List<String> getReassignEmailServiceAddress(){
        String reassignEmailServiceAddress;
        List<Reassign_Case_Email_Service_Config__mdt> mappingMetadataRecList = [SELECT Reassign_Email_Service_Address__c 
                                                                                FROM Reassign_Case_Email_Service_Config__mdt
                                                                                LIMIT 1];
        if(mappingMetadataRecList.size() > 0){
            reassignEmailServiceAddress = mappingMetadataRecList[0].Reassign_Email_Service_Address__c;
            System.debug('reassignEmailServiceAddress:: ' + reassignEmailServiceAddress);
            return new List<String>{reassignEmailServiceAddress};
                }
        return null;
    }
    
}