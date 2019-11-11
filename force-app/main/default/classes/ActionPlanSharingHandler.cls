/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for handling the Apex sharing
               for Action Plan object

Test Class:    ActionPlanSharingHandler_Test
History
04/05/2015     Manish Damle       Created
------------------------------------------------------------*/
public without sharing class ActionPlanSharingHandler {
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will actually recaclulate the sharing
                   for Action Plans
    Inputs:        list of action plans
    History
    04/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/  
    public void share(list <Action_Plan__c> actionPlansToBeShared) {
        map <Id,Action_Plan__Share> newShareRecords = new map <Id, Action_Plan__Share>();
        set <Id> parentActionPlanIds = new set <Id> ();
        set <String> existingShareRecordsForOwners = new set <String>();
        
        for(Action_Plan__c  ap : actionPlansToBeShared) {
            if(ap.Parent_Action_Plan__c != null) {
                parentActionPlanIds.add(ap.Parent_Action_Plan__c);
            }
        } 
        
        map <Id,Action_Plan__Share> existingShareRecords = new map <Id,Action_Plan__Share> ([Select Id,ParentId, UserOrGroupId
                                                                                             From Action_Plan__Share 
                                                                                             Where ParentId IN: actionPlansToBeShared]);
            //delete the existing sharing and create new share records
        list <Database.DeleteResult> results = Database.delete(existingShareRecords.values(), false);

        system.debug('-------Parent Action Plan Ids--------' + parentActionPlanIds);
        map <Id, Action_Plan__c> parentActionPlans = new map <Id, Action_Plan__c> ([Select Id, OwnerId From Action_Plan__c Where Id IN: parentActionPlanIds]);
        system.debug('-------Parent Action Plans--------' + parentActionPlans);
        
        for(Action_Plan__c  ap : actionPlansToBeShared) {
            
            if(ap.Parent_Action_Plan__c != null 
               	&& parentActionPlans.containsKey(ap.Parent_Action_Plan__c)) {     
                newShareRecords.put(ap.Id, getShareRecordForActionPlanOwner(ap.Id, parentActionPlans.get(ap.Parent_Action_Plan__c).OwnerId)); 
                system.debug('-------AP Shared With Parent AP Owner--------' + ap.Id + ' ==> ' + parentActionPlans.get(ap.Parent_Action_Plan__c).OwnerId);
            }
        }
        
        system.debug('-------Child Action Plan Share Records--------' + newShareRecords);
        insert newShareRecords.values();
    }
    
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will return the Share object record to
                   be created
    Inputs:        Parent id, Share with User Id

    History
    04/05/2015     Manish Damle       Created
    ------------------------------------------------------------*/       
    private Action_Plan__Share getShareRecordForActionPlanOwner(Id parentId, String shareWith) {
        return new Action_Plan__Share(ParentId = parentId,
                                      AccessLevel = 'Edit',
                                      UserOrGroupId = shareWith,
                                      RowCause = Schema.Action_Plan__Share.RowCause.Parent_Action_Plan_Owner__c);
    }
}