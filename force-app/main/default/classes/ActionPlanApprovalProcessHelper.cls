/*------------------------------------------------------------
Author:        Arxxus
Description:   Set the current approver of action plans under approval
History
Implemented for Oct 2017 Release 

This class is commented as this component needs to get rolled back for oct release. 
Please delete this class post october release. 
-------------------------------------------------------------*/
public class ActionPlanApprovalProcessHelper {
	
    /*
    @future(callout = true)
    public static void setCurrentApprover(Set<Id> targetObjIds) {
        List<Action_Plan__c> apList = new List<Action_Plan__c>();        
        Set<Id> processInstanceIds = new Set<Id>();
        Map<Id,String> pIDUserIdMap = new Map<Id,String>();
        Map<Id,Id> actionPlanPIDMap = new Map<Id,Id>();
        
        for(ProcessInstance pi: [select Id,TargetObjectId from ProcessInstance where TargetObjectId IN :targetObjIds AND Status = :GlobalConstants.APPROVAL_STATUS_PENDING]){
            processInstanceIds.add(pi.Id);
            actionPlanPIDMap.put(pi.TargetObjectId,pi.Id);
        }
        System.debug('actionPlanPIDMap: '+actionPlanPIDMap);
        for(ProcessInstanceWorkitem piWorkItem : [SELECT ActorId ,ProcessInstanceId from ProcessInstanceWorkitem  WHERE ProcessInstanceId IN :processInstanceIds]){
            pIDUserIdMap.put(piWorkItem.ProcessInstanceId, piWorkItem.ActorId);
        }
        System.debug('pIDUserIdMap: '+pIDUserIdMap);
        for(Action_plan__c ap :[SELECT ID, Current_Approver__c, ApprovalCount__c FROM Action_Plan__c WHERE Id IN : targetObjIds]){
            if(actionPlanPIDMap.containsKey(ap.Id) && actionPlanPIDMap.get(ap.Id) != NULL && pIDUserIdMap.containsKey(actionPlanPIDMap.get(ap.Id))){
                System.debug('actor Id '+pIDUserIdMap.get(actionPlanPIDMap.get(ap.Id)));
				String actorId = pIDUserIdMap.get(actionPlanPIDMap.get(ap.Id));
                if( !actorId.startsWith('00G') && (ap.Current_Approver__c == NULL || ap.Current_Approver__c != pIDUserIdMap.get(actionPlanPIDMap.get(ap.Id)) )){
                    ap.Current_Approver__c = pIDUserIdMap.get(actionPlanPIDMap.get(ap.Id));
                    apList.add(ap); 
                }
            }else {
                if(ap.Current_Approver__c != NULL || ap.ApprovalCount__c != 0){
                    ap.Current_Approver__c = NULL;
                    ap.ApprovalCount__c = 0;
                    apList.add(ap);    
                }
            }            
        }
        System.debug('aplist to update: '+apList);
        if(apList.size() > 0)
        update apList;
        
    }
    */
}