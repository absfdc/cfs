/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   After UnDelete handler class for the Case trigger
               
Test Class:    CaseTriggerDispatcher_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
06/05/2015     Manish Damle       Created
-----------------------------------------------------------------------------------------*/
public with sharing class CaseAfterUnDeleteTriggerHandler extends TriggerHandlerBase {
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Calculate no of child cases
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    06/05/2015     Manish Damle       Created
     -------------------------------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try {
            CaseCustomRollUpImpl rollUp = new CaseCustomRollUpImpl();
            rollUp.calculateRollUp((map <Id, Case>) tp.newMap, null); 
            CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
            Set<Id> suspectOwnerAgencyChangedParent= new Set<Id> ();//determineMultiAgency
            for (case aCase:(List<Case>)tp.newList){
                if (aCase.parentId!=null) suspectOwnerAgencyChangedParent.add(aCase.parentId);
            } 
            //determineMultiAgency
            Map<Case,List<Case>> suspectParentChild = new Map<Case,List<Case>>();
            for (Case parent:[select Id, Agency__c,MultiAgency__c, OwnerAgency__c,ownerId, (select Id, Agency__c,MultiAgency__c, OwnerAgency__c,ownerId from cases ) from case where Id in:suspectOwnerAgencyChangedParent]){
                suspectParentChild.put(parent,parent.cases);
            }
            
            if (suspectParentChild.size()>0) {
                Map<Id,Case> updateMultiagency=entitle.determineMultiAgency(suspectParentChild);
                if (updateMultiagency!=null && updateMultiagency.size()>0)  {
                    Map<Id,Id> caseVsOwnerIds= new Map<Id,Id>();
                    for (Case aCase:updateMultiagency.values()) {
                        if (aCase.parentId==null) caseVsOwnerIds.put(aCase.Id,aCase.ownerId);
                    }
                    //if (AssignCase_Cx.pressed==true && !System.isFuture()) CaseEntitlementUtil.reassignCaseWithActiveRule(caseVsOwnerIds);
                    update updateMultiagency.values();
                }
            }                     
        }catch(Exception e) {
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}