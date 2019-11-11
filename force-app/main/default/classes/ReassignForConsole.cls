public class ReassignForConsole {
    /*------------------------------------------------------------
Author:        Arxxus
Description:   This class is used to perform custom Re-Assign functionality.
Test Class:    
History
<Date>        <Authors Name>     <Brief Description of Change>
16-APR-2018   Ankur Jaiswal       
------------------------------------------------------------*/
    
    public String caseId;
    public Case newCase {get; set;}
    public static set<String> casePortfolioValues = new set<String>{'Transport and Infrastructure', 'Roads, Maritime and Freight', 'Office of the Secretary', 'WestConnex'};
        public static set<String> allowedMOContactFilterRoles = new Set<String>{'DLO_Transport','Policy_Advisor_Transport','DLO_WestConnex','DLO_Road','Policy_Advisor_Road','Policy_Advisor_WestConnex','Senior_Executive_Coordinator','Executive_Director'};    
            public static map<Id,UserRole> allowedMOContactFilterRoleIds;
    static{
        allowedMOContactFilterRoleIds = new map<Id,UserRole>([Select Id From UserRole Where DeveloperName IN: allowedMOContactFilterRoles]);
    }
    
    public ReassignForConsole(){}
    
    public ReassignForConsole(ApexPages.StandardController controller) {
        Id id = ApexPages.currentPage().getParameters().get('id');
        this.newCase=(Case)controller.getRecord(); 
    }
    
    @RemoteAction    
    public static Case validateAndReassign(String caseId, String selectedUserId) {        
        Case newCase;
        try{ 
            System.debug('validateAndReassign:: caseId: ' + caseId + ' selectedUserId: ' + selectedUserId);
            boolean isQueueORNotMORole = false;
            boolean isCasePortfolioFilterNotFulfilled = false;
            
            if(caseId != null){
                newCase = [Select id, ownerId, portfolio__c, MO_User__c from case where id = :caseId limit 1][0];
                newCase.ownerId = selectedUserId;
            }
            
            System.debug('caseId: ' + caseId + ' newCase.ownerId: ' + newCase.ownerId + ' newCase.portfolio__c: ' + newCase.portfolio__c);
            
            //Send email to change owner of the approval process
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            System.debug('Attempting to send email now...');
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
            
            if (!((String)newCase.ownerId).startsWith('005'))
            {
                isQueueORNotMORole = true;
                System.debug('newCase.ownerId is Not a Salesforce User: isQueueORNotMORole: ' + isQueueORNotMORole);
            }else {
                Id currentUserRoleId = [SELECT Id, UserRoleId FROM User where id = :newCase.ownerId limit 1].UserRoleId;
                String casePortfolio = newCase.Portfolio__c;
                System.debug('casePortfolio: ' + casePortfolio);
                if(casePortfolio == null) isCasePortfolioFilterNotFulfilled = true;
                else if (casePortfolio != null && !casePortfolioValues.contains(casePortfolio)){
                    System.debug('casePortfolioValues.contains(casePortfolio): ' + casePortfolioValues.contains(casePortfolio));
                    isCasePortfolioFilterNotFulfilled = true;
                    System.debug('newCase.casePortfolio is Not one of the allowed values: casePortfolio: ' + casePortfolio);
                }
                if(!allowedMOContactFilterRoleIds.containsKey(currentUserRoleId)){
                    isQueueORNotMORole = true;
                    System.debug('Current user role is Not one of the allowed values: currentUserRoleId: ' + currentUserRoleId);
                }
            }
            
            //Do not attempt to update MO Contact if user is a Queue or doesn't satisfies filter criteria for the Case record
            System.debug('isQueueORNotMORole: ' + isQueueORNotMORole + ' isCasePortfolioFilterNotFulfilled: ' + isCasePortfolioFilterNotFulfilled);
            if(!(isQueueORNotMORole || isCasePortfolioFilterNotFulfilled)){
                newCase.MO_User__c = newCase.ownerId;
                System.debug('Updated newCase MO Contact as the Case owner');
            }
            // newCase.ownerId = newCase.ownerId;
            Update newCase;
        }Catch(Exception e) {
            System.debug('-------Exception-----' + e.getLineNumber() + e.getMessage() + e.getStackTraceString());
            
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source = 'ReassignForPL';
            message.sourceFunction='validateAndReassign';
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
            return null;
        }            
        return newCase;
    }
    
    public PageReference Cancel() {
        if (System.currentPagereference().getParameters().get('Id') != null || System.currentPagereference().getParameters().get('Id') != '') {
            caseId = System.currentPagereference().getParameters().get('Id');
            PageReference pageRef = new PageReference('/' + caseId);
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