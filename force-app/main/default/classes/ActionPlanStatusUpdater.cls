/*-----------------------------------------------------------------------------------
Author:        Vishal Taware
Company:       Arxxus.com
Description:   Helper class for Case After update handler

Test Class:    ActionPlanStatusUpdater_Test
History
28/04/2015     Vishal Taware       Created
13/01/2017     Arxxus              Updated Code - Optimisation 
-----------------------------------------------------------------------------------*/
public without sharing class ActionPlanStatusUpdater {
    
    /*---------------------------------------------------------------------------------------
    Author:        Vishal Taware
    Company:       Arxxus.com
    Description:   This method will close all the linked action plans once the case is marked 
                   as No Response Required.
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    28/04/2015     Vishal Taware      Created
    29/06/2015     Manish Damle       Updated the code to close the child action plan also.  
    -------------------------------------------------------------------------------------*/
    public Boolean closeRelatedActionPlan(TriggerParameters tp){
        try {
            //Filter out all misisterial corrospondance cases having Response_Type__c = 'No response required (NRR)' from newList.
            Set<String> NRRCaseIdSet = new Set<String>(); 
            
            for(String tempId : tp.newMap.keySet()){
                
              Case tempCase = (Case) tp.newMap.get(tempId);
              
              System.debug('Case Response Type: '+tempCase.Response_Type__c);
              if(tempCase.Response_Type__c == GlobalConstants.CASE_NRR_RESPONSE_TYPE)
               NRRCaseIdSet.add(tempCase.Id);
            }    
            List<Action_Plan__c> actionPlanList = new List<Action_Plan__c>();
            
                actionPlanList = [Select Id, Status__c, Parent_Case__c, (Select Id, Status__c From Action_Plans__r)
                                                   From Action_Plan__c 
                                                   Where Parent_Case__c IN: NRRCaseIdSet];
            
            List<Action_Plan__c> updateActionPlanList = new List<Action_Plan__c>();
            
            //Filter out all changed cases from misisterial corrospondance cases.
            for (Action_Plan__c ap : actionPlanList){
                Case newCase = (Case)(tp.newMap.get(ap.Parent_Case__c));
                Case oldCase = (Case)(tp.oldMap.get(ap.Parent_Case__c));

                if(newCase.Response_Type__c != oldCase.Response_Type__c){
                    ap.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
                    ap.SkipValidations__c = true;
                    updateActionPlanList.add(ap);
                    
                    if(ap.Action_Plans__r != null) {
                        System.debug('---Child Action Plan---Found----');
                        for (Action_Plan__c childAp : ap.Action_Plans__r){
                            childAp.Status__c = GlobalConstants.ACTION_PLAN_CLOSED_STATUS;
                            childAp.SkipValidations__c = true;
                            updateActionPlanList.add(childAp);    
                        }
                    }
                }
            }

                        
            if(updateActionPlanList.size()>0){
                update updateActionPlanList;
                return true;
            }else{
                return false;
            }
        
        }catch(Exception exc){
            system.debug('---Exception After Trigger: closeRelatedActionPlan---' + exc.getMessage());
            list <ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source='CaseAfterUpdateTriggerHandler';
            message.sourceFunction='closeRelatedActionPlan';
            if (tp!= null && tp.newMap != null) message.referenceInfo=JSON.serialize(tp.newMap.keySet());
            message.logMessage= exc.getMessage();
            message.ex = exc;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            return false;
        }

    }

}