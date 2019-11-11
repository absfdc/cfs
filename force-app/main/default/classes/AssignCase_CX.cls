/*------------------------------------------------------------
Author:        Brett Cawrse
Company:       Salesforce
Description:   Class to execute case assingment rules from a button

History
16 Apr 2015      Brett Cawrse     created
21 Apr 2015      Manish Damle     Updated. Support to close the tab when 
                                  user dont have access to case record.
------------------------------------------------------------*/

public with sharing class AssignCase_CX {
    public static Boolean pressed{get;set;}
    
    public Case c;
    //This flag will indicate that whether user does not have read access to case record or not.
    public boolean HasReadAccess {get; set;}
    
    
    // Constructor - this only really matters if the autoRun function doesn't work right
    public AssignCase_CX(ApexPages.StandardController controller)
    {
        this.c = (Case)controller.getRecord();
        HasReadAccess = true;
    }
    
    // Code to invoke on page load.
    public PageReference autoRun()
     {
     	
        pressed=true;
        String theId = ApexPages.currentPage().getParameters().get('id');
        
        // SFCOE-1989 by Anil Sheoran - Capture any error/exception on Case Update in Application Log table - 17-05-2017 - Start
        
        List<Case> casesToUpdate = new List<Case>();
        Boolean isSercoProfile = false;
        //Create the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
	    	    
	    try{        
	        if (theId == null || theId == '') {
	            // Display the Visualforce page's content if no Id is passed over
	            HasReadAccess = false;
	            return null;
	        }
	 
	        //Fetch the assignment rules on case
	        system.debug('test5');
	        List<AssignmentRule> rules = new List<AssignmentRule>();
	        system.debug('test6');
	        AssignmentRule rule = new AssignmentRule();
	        system.debug('test7');
	        rules = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
	
	        if (rules != null && rules.size() == 1){
	            rule = rules[0];
	            system.debug('Found a rule');
	        } else {
	            system.debug('Error: there should be only one');
	        }
		    
	        dmlOpts.assignmentRuleHeader.assignmentRuleId= rule.id;
	        //dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
	        dmlOpts.EmailHeader.triggerUserEmail = true;
	        
	        List<Profile> sercoProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() AND Name = :GlobalConstants.SERCO_AGENT_PROFILE];
	        if(!sercoProfile.isEmpty()) {
	            isSercoProfile = true;
	        }
	        
	        List<Case> cases = [select Id, (SELECT Id, OwnerAgency__c, isClosed FROM Cases)  from Case where id =: theId limit 1]; 
	        
	        for(Case caseRecord : cases) {
	            casesToUpdate.add(caseRecord);
	            for(Case child : caseRecord.cases) {
	                if(isSercoProfile) {
	                    if(GlobalConstants.AGENCY_SERCO.equalsIgnoreCase(child.OwnerAgency__c)) {
	                        casesToUpdate.add(child);
	                    } else if(!(GlobalConstants.AGENCY_SYDNEY_TRAINS.equalsIgnoreCase(child.OwnerAgency__c) || GlobalConstants.AGENCY_NSW_TRAINS.equalsIgnoreCase(child.OwnerAgency__c)) && child.isClosed) {
	                        casesToUpdate.add(child);
	                    }
	                } else {
	                    casesToUpdate.add(child);
	                }               
	            }
	            //casesToUpdate.addAll(caseRecord.cases);
	        }
        
        }
     	catch(Exception e){
     		ApplicationLogUtility.logMessage('Error','AssignCase_CX','autoRun',e.getMessage(),'',Null,Null,'','','Case Id - '+theId+' User Id - '+userinfo.getuserid());
     		//THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
     	}
     	                
//        cases.setOptions(dmlOpts);
//        system.debug('Options set');
//        update cases;
        System.debug(LoggingLevel.INFO, 'Total cases to be updated: ' + casesToUpdate.size());
        Database.SaveResult[] result = Database.update(casesToUpdate, dmlOpts);     
        system.debug('Updated Case');
        
        for(Database.SaveResult sResult : result){
        	System.Debug(' **** Case Record Id **** '+sResult.getId());
            if(!sResult.isSuccess()){
                System.debug(' **** Errors while updating case - Case Assignment by click of Assign Button **** '+sResult.getErrors());
                for(Database.Error err : sResult.getErrors()){
                	// Reference - ApplicationLogUtility.logMessage(String debugLevel,String source,String sourceFunction,String logMessage,String payLoad,Exception ex,Long timeTaken,String logCode,String referenceId,String referenceInfo)
                	ApplicationLogUtility.logMessage('Error','AssignCase_CX','autoRun method - case update',err.getMessage(),'',Null,Null,'','','Case Id - '+String.valueOf(sResult.getId())+' User Id - '+userinfo.getuserid());
                }
            }
        }
        // SFCOE-1989 by Anil Sheoran - Capture any error/exception on Case Update in Application Log table - 17-05-2017 - End
        
        UserRecordAccess recordAccesss = [Select RecordId, HasReadAccess 
                                          From UserRecordAccess 
                                          Where UserId =: UserInfo.getUserId() 
                                            And RecordId =: theId];
        system.debug('-----Has Read Acceess-----' + recordAccesss.HasReadAccess); 
        
         //If current user has read access then redirect user to case details page other wise close the current tab in the console.
        if(recordAccesss.HasReadAccess) {
            //This will avoid insufficient 
            PageReference pageRef = new PageReference('/' + theId);
            system.debug('redirecting');
            pageRef.setRedirect(true);
            return pageRef; 
        }
            
        HasReadAccess = false;
        pressed=false;
        return null;
     }
}