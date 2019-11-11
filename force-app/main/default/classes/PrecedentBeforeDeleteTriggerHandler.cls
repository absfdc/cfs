/*------------------------------------------------------------
Author:        Arxxus
Description:   Before delete handler class for the Precedent trigger
                unshare precedent case from MO Contact and Signatory Person if they are not owner of the case. 
Test Class:     PrecedentBeforeDeleteTriggerHandler_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/

public without sharing class PrecedentBeforeDeleteTriggerHandler extends TriggerHandlerBase {

    public Boolean exceptionInvoked = FALSE;
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }

    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    private void process(TriggerParameters tp) {
        try{     

            Set<Id> relatedCaseIds = new Set<Id>();
            Map<Id,Case> relatedCaseMap = new Map<Id,Case>();

            Set<Id> precedentCaseIds = new Set<Id>();
            Map<Id,Case> precedentCaseMap = new Map<Id,Case>();

            Map<Id,Precedent__c> precedentValuesMap = (Map<Id,Precedent__c>)tp.oldMap;

            if(precedentValuesMap.size() > 0){
                // iterate over trigger data to get set of related case Id
                for(Precedent__c getPrecedent : precedentValuesMap.values()){
                    relatedCaseIds.add(getPrecedent.Related_Case__c);
                    precedentCaseIds.add(getPrecedent.Precedent_Case__c);
                }
            }

            if(precedentCaseIds.size() > 0){
                // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                for( Case getCase : [Select Id, OwnerId FROM Case 
                                        WHERE Id IN: precedentCaseIds ] ){

                    precedentCaseMap.put(getCase.Id,getCase);

                }
            }

            if(relatedCaseIds.size() > 0){

                // create a map of caseId and case to get MO_User__c and Signatory_Person__c 
                for( Case getCase : [Select Id, MO_User__c, Signatory_Person__c FROM Case 
                                        WHERE Id IN: relatedCaseIds 
                                        AND (MO_User__c != NULL OR Signatory_Person__c != NULL) ] ){

                    relatedCaseMap.put(getCase.Id,getCase);

                }    
            }
            
            Map<Id,List<Precedent__c>> relatedCaseVsPrecedentCaseMap = new Map<Id,List<Precedent__c>>();
            
            if(precedentValuesMap.size() > 0){
                // create a Map of related Case id with List of precdent
                for(Precedent__c getPrecedent : precedentValuesMap.values()){
                
                    if(!relatedCaseVsPrecedentCaseMap.containsKey(getPrecedent.Related_Case__c))
                        relatedCaseVsPrecedentCaseMap.put(getPrecedent.Related_Case__c,new List<Precedent__c>{getPrecedent});
                    else
                        relatedCaseVsPrecedentCaseMap.get(getPrecedent.Related_Case__c).add(getPrecedent);
                
                }
            }

            system.debug('Before Delete relatedCaseVsPrecedentCaseMap ::' + relatedCaseVsPrecedentCaseMap );
            
            List<CaseShare> csShareList = new List<CaseShare>();

            // map used to create case vs user (MO Contact or Signatory Person)
            Map<Id,Set<Id>> caseVsUserIdMap = new Map<Id,Set<Id>>();

            if(relatedCaseVsPrecedentCaseMap.size() > 0){

                for(List<Precedent__c> getPrecedentList : relatedCaseVsPrecedentCaseMap.values()){

                    for(Precedent__c getPrecedent : getPrecedentList){

                        String moContact = NULL;
                        String signatoryPerson = NULL;

                        if(relatedCaseMap.containsKey(getPrecedent.Related_Case__c)){
                        
                            moContact = relatedCaseMap.get(getPrecedent.Related_Case__c).MO_User__c;
                            signatoryPerson = relatedCaseMap.get(getPrecedent.Related_Case__c).Signatory_Person__c;   
                        
                        }
                        
                        if(getPrecedent.Precedent_Case__c != NULL){

                            // block to check if MO User or Signatory are owner of precedent case then not share case
                            if(precedentCaseMap.containsKey(getPrecedent.Precedent_Case__c)){ 

                                if(moContact != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact){

                                    if(!caseVsUserIdMap.containsKey(getPrecedent.Precedent_Case__c)){    
                                        caseVsUserIdMap.put(getPrecedent.Precedent_Case__c,new Set<Id>{(Id)moContact});
                                    }else{
                                        caseVsUserIdMap.get(getPrecedent.Precedent_Case__c).add((Id)moContact);
                                    }

                                }    

                                if(signatoryPerson != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact){

                                    if(!caseVsUserIdMap.containsKey(getPrecedent.Precedent_Case__c)){    
                                        caseVsUserIdMap.put(getPrecedent.Precedent_Case__c,new Set<Id>{(Id)signatoryPerson});
                                    }else{
                                        caseVsUserIdMap.get(getPrecedent.Precedent_Case__c).add((Id)signatoryPerson);
                                    }

                                }
                            }        
                        }    
                    }
                }
            }    
            // set of user id with whom unshare case.
            Set<Id> userIds = new Set<Id>();
            if(caseVsUserIdMap.size() > 0){
                for(Set<Id> getIdSet : caseVsUserIdMap.values()){
                    for(Id getId:getIdSet){
                        userIds.add(getId);
                    }
                }
            }

            if(caseVsUserIdMap.size() > 0 && userIds.size() > 0){    
                List<CaseShare> caseShareToDelete = [Select Id,  CaseId, CaseAccessLevel, UserOrGroupId, RowCause FROM CaseShare 
                                        WHERE CaseAccessLevel='Edit' 
                                        AND CaseId IN: caseVsUserIdMap.keySet() 
                                        AND RowCause = 'Manual'
                                        AND UserOrGroupId IN: userIds];
            
                if(caseShareToDelete.size() > 0)
                    delete caseShareToDelete;                        
            }

        }catch(Exception e){
            exceptionInvoked = TRUE;
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='PrecedentBeforeDeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
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