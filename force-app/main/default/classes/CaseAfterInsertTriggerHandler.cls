/*------------------------------------------------------------
Author:        Brett Cawrse
Company:       Salesforce
Description:   After Insert handler class for the Case trigger
               Executes case assignment rules for cases created through web to case  

Test Class:    CaseTriggerDispatcher_Test
History
14 Apr 2015      Brett Cawrse     created
------------------------------------------------------------*/
public class CaseAfterInsertTriggerHandler extends TriggerHandlerBase{
    public override void mainEntry(TriggerParameters tp) {
        system.debug('hello world');
        process(tp);
    }
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    /*------------------------------------------------------------
    Author:        Brett Cawrse
    Company:       Salesforce.com
    Description:   Executes custom rollup field function for lookup relationships (without sharing)
    Inputs:        Trigger context parameters

    History
    <Date>      <Authors Name>     <Brief Description of Change>
    14-Apr-2015 B. Cawrse          Execute assigment rules for web2case
    8-May-2015  B.Cawrse           Reverted assignment rule execution code now that assignment rules have been fixed
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{            
	        //call after insert integration here - Ishu Jain
            FASendCasesToDFSIAfterInsert FASendCases = new FASendCasesToDFSIAfterInsert();
            FASendCases.SendCasesToDFSI((map <Id, Case>) tp.newMap);
        		
            CaseCustomRollUpImpl rollUp = new CaseCustomRollUpImpl();
            rollUp.calculateRollUp((map <Id, Case>) tp.newMap, null); 
            
            shareCaseWithParentOwner(tp);
            CaseEntitlementUtil  entitle= new CaseEntitlementUtil();
            Set<Id> suspectOwnerAgencyChangedParent= new Set<Id> ();//determineMultiAgency
            for (case aCase:(List<Case>)tp.newList){
                if (aCase.parentId!=null) suspectOwnerAgencyChangedParent.add(aCase.parentId);
            } 
             //determineMultiAgency
            Map<Case,List<Case>> suspectParentChild = new Map<Case,List<Case>>();
            for (Case parent:[select Id, MultiAgency__c, OwnerAgency__c,Agency__c,ownerId,(select Id, Agency__c,MultiAgency__c, OwnerAgency__c,ownerId from cases ) from case where Id in:suspectOwnerAgencyChangedParent]){
                suspectParentChild.put(parent,parent.cases);
            }
            if (suspectParentChild.size()>0) {
                Map<Id,Case> updateMultiagency=entitle.determineMultiAgency(suspectParentChild);
                if (updateMultiagency!=null && updateMultiagency.size()>0)  {
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
            Set<Id> caseIdsToUpdateClosureTarget = new Set<Id>();
            for (Id aCaseId:tp.newMap.keySet()){
                Case newCase=(Case)tp.newMap.get(aCaseId);
                if(newCase.ClosureTargetDate__c == null && (newCase.Agency__c != NULL || newCase.OwnerAgency__c != null)) {
                    caseIdsToUpdateClosureTarget.add(newCase.Id);
                }
            }
            if(!caseIdsToUpdateClosureTarget.isEmpty() && !System.isFuture()) {
                CaseEntitlementUtil.updateCaseTargetDate(caseIdsToUpdateClosureTarget);
            }
            
        }catch(Exception e){
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseAfterInsertTriggerHandler';
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
    
    private void shareCaseWithParentOwner(TriggerParameters tp) {
        List<Case> casesToCreateShareRecords = new List<Case>();            
        for(Case caseRecord: (List<Case>)tp.newMap.values()) {
            if(caseRecord.ParentId != null) {
                casesToCreateShareRecords.add(caseRecord);
            }
        }
        
        if(!casesToCreateShareRecords.isEmpty()) {
            ChildCaseSharingCreator shareCreator = new ChildCaseSharingCreator(casesToCreateShareRecords);
            shareCreator.createShareRecords();
        }
    }
}