/*------------------------------------------------------------
Author:         Sharath K
Company:        System Partners
Description:    
Test Class:     
History
<Date>      	<Authors Name>      <Brief Description of Change>
06-12-16   	Sharath K       		Created
------------------------------------------------------------*/
global class ActionPlanApproverUpdateBatch implements Database.Batchable<sObject>,  Schedulable{
	
	/*------------------------------------------------------------
    Author:         Sharath K
    Company:        System Partners
    Description:    
    <Date>          <Authors Name>      <Brief Description of Change>
    06-12-2016       Sharath K            Created
    -------------------------------------------------------------*/
	global Database.QueryLocator start(Database.BatchableContext BC) {
        String advice_request = GlobalConstants.ACTION_PLAN_TYPE_ADVICE_REQUEST;
        String agency_reponse = GlobalConstants.ACTION_PLAN_TYPE_AGENCY_RESPONSE;
        String status = GlobalConstants.ACTION_PLAN_WAITING_APPROVAL;
		String query = 'SELECT Id,Last_To_be_Approver__c from Action_Plan__c where Status__c = \''+ status + '\' AND (TYPE__c =\''+ agency_reponse + '\' OR TYPE__c = \'' + advice_request + '\')';
		return Database.getQueryLocator(query);
	}

	/*------------------------------------------------------------
    Author:         Sharath K
    Company:        System Partners
    Description:    Execute the email send
    <Date>          <Authors Name>      <Brief Description of Change>
    06-12-2016       Sharath K            Created
    ------------------------------------------------------------*/
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Id> targetObjIds = new List<Id>();
        List<Id> processInstanceIds = new List<Id>();
        Map<Id,String> pIDUserNameMap = new Map<Id,String>();
        Map<Id,Id> actionPlanPIDMap = new Map<Id,Id>();
        List<Action_Plan__c> recordsToUpdate = new List<Action_Plan__c>();
        for( Action_Plan__c ap:(List<Action_Plan__c>)scope){
            targetObjIds.add(ap.Id);
        }
        for(ProcessInstance pi: [select Id,TargetObjectId from ProcessInstance where TargetObjectId IN :targetObjIds AND Status = :GlobalConstants.APPROVAL_STATUS_PENDING]){
            processInstanceIds.add(pi.Id);
            actionPlanPIDMap.put(pi.TargetObjectId,pi.Id);
        }
        for(ProcessInstanceWorkitem piWorkItem : [SELECT Actor.Name,ProcessInstanceId from ProcessInstanceWorkitem  WHERE ProcessInstanceId IN :processInstanceIds]){
            pIDUserNameMap.put(piWorkItem.ProcessInstanceId, piWorkItem.Actor.Name);
        }
        for(Action_Plan__c ap:(List<Action_Plan__c>)scope){
            if(actionPlanPIDMap.get(ap.Id) != null){
                ap.Last_To_be_Approver__c = pIDUserNameMap.get(actionPlanPIDMap.get(ap.Id));
                recordsToUpdate.add(ap);
            }            
        }
        if(!recordsToUpdate.isEmpty()){
                Database.SaveResult[] results = Database.update(recordsToUpdate,false);
                for (Database.SaveResult sr : results) {
                    if(!sr.isSuccess()){
                         ApplicationLogMessage message= new ApplicationLogMessage();
                            message.source='ActionPlanApproverUpdateBatch';
                            message.sourceFunction='process';
                            message.referenceInfo=JSON.serialize(sr.getErrors());
                            message.debugLevel='Error';
                        ApplicationLogUtility.logMessage(message);
                    }
            	}
        }
        
	}

	global void execute(SchedulableContext sc) {
        ActionPlanApproverUpdateBatch approverUpdate = new ActionPlanApproverUpdateBatch();
        Database.executeBatch(approverUpdate,500); 
    }
	
	global void finish(Database.BatchableContext BC) {}


	

}