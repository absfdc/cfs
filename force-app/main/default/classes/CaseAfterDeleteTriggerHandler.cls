/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   After Delete handler class for the Case trigger
               
Test Class:    CaseTriggerDispatcher_Test

History
<Date>         <Authors Name>     <Brief Description of Change>
06/05/2015     Manish Damle       Created
-----------------------------------------------------------------------------------------*/
public with sharing class CaseAfterDeleteTriggerHandler extends TriggerHandlerBase {
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
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
            rollUp.calculateRollUp((map <Id, Case>) tp.oldMap, null); 
            CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
            Set<Id> suspectOwnerAgencyChangedParent= new Set<Id> ();//determineMultiAgency
            for (case aCase:(List<Case>)tp.oldList){
                if (aCase.parentId!=null) suspectOwnerAgencyChangedParent.add(aCase.parentId);
            } 
             //determineMultiAgency
            Map<Case,List<Case>> suspectParentChild = new Map<Case,List<Case>>();
            for (Case parent:[select Id, MultiAgency__c, OwnerAgency__c,Agency__c,ownerId,(select Id, MultiAgency__c, OwnerAgency__c,Agency__c,ownerId from cases where Id not in:tp.oldMap.keySet() ) from case where Id in:suspectOwnerAgencyChangedParent]){
                suspectParentChild.put(parent,parent.cases);
            }
            if (suspectParentChild.size()>0) {
                Map<Id,Case> updateMultiagency=entitle.determineMultiAgency(suspectParentChild);
                if (updateMultiagency!=null && updateMultiagency.size()>0) {
                    Map<Id,Id> caseVsOwnerIds= new Map<Id,Id>();
                    Map<Id,boolean> caseVsMultiAgency= new Map<Id,boolean>();

                    for (Case aCase:updateMultiagency.values()) {
                        caseVsMultiAgency.put(aCase.Id, aCase.MultiAgency__c);

                        if (aCase.parentId==null) caseVsOwnerIds.put(aCase.Id,aCase.ownerId);
                    }
                    //if (AssignCase_Cx.pressed==true && !System.isFuture()) CaseEntitlementUtil.reassignCaseWithActiveRule(caseVsOwnerIds,caseVsMultiAgency);
                    update updateMultiagency.values();
                }
            }          
        }catch(Exception e) {
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseAfterDeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.newMap!=null)  message.referenceInfo=JSON.serialize(tp.newMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel=GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}