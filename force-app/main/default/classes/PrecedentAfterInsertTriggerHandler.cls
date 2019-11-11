/*------------------------------------------------------------
Author:        Arxxus
Description:   After Insert handler class for the Precedent trigger
               Share precedent cases with MO Contact and Signatory Person of related case , if they are not owner. 
Test Class:     PrecedentAfterInsertTriggerHandler_Test
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/

public without sharing class PrecedentAfterInsertTriggerHandler  extends TriggerHandlerBase{

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

            Map<Id,Precedent__c> precedentValuesMap = (Map<Id,Precedent__c>)tp.newMap;
            
            // iterate over trigger data to get set of related case Id
            for(Precedent__c getPrecedent : precedentValuesMap.values()){
                relatedCaseIds.add(getPrecedent.Related_Case__c);
                precedentCaseIds.add(getPrecedent.Precedent_Case__c);
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
                                        WHERE Id IN: relatedCaseIds ] ){

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
                
            System.debug('After Insert relatedCaseVsPrecedentCaseMap :: ' + relatedCaseVsPrecedentCaseMap );
            
            List<CaseShare> csShareList = new List<CaseShare>();
            
            if(relatedCaseVsPrecedentCaseMap.size() > 0){

                for(List<Precedent__c> getPrecedentList : relatedCaseVsPrecedentCaseMap.values()){

                    for(Precedent__c getPrecedent : getPrecedentList){

                        String moContact = NULL;
                        String signatoryPerson = NULL;

                        if(relatedCaseMap.containsKey(getPrecedent.Related_Case__c)){
                        
                            moContact = relatedCaseMap.get(getPrecedent.Related_Case__c).MO_User__c;
                            signatoryPerson = relatedCaseMap.get(getPrecedent.Related_Case__c).Signatory_Person__c;   
                        
                        }    

                        // block to check if MO User or Signatory are owner of precedent case then not share case
                        if(precedentCaseMap.containsKey(getPrecedent.Precedent_Case__c)){
                         
                            // check if MOUser on related case and owner of precedent case are not same
                            if( moContact != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != moContact){

                                CaseShare csShare = new CaseShare();
                                // Give Read write access to that user for this particular case record.
                                csShare.CaseAccessLevel = 'Edit';
                                // Assign case Id of case record.
                                csShare.CaseId = getPrecedent.Precedent_Case__c;
                                // Assign user id to grant read write access to this particular case record.
                                csShare.UserOrGroupId = moContact;
                                csShareList.add( csShare );
                            }

                            // check if Signatory on related case and owner of precedent case are not same
                            if( signatoryPerson != NULL && precedentCaseMap.get(getPrecedent.Precedent_Case__c).OwnerId != signatoryPerson){
                                
                                CaseShare csShare = new CaseShare();
                                // Give Read write access to that user for this particular case record.
                                csShare.CaseAccessLevel = 'Edit';
                                // Assign case Id of case record.
                                csShare.CaseId = getPrecedent.Precedent_Case__c;
                                // Assign user id to grant read write access to this particular case record.
                                csShare.UserOrGroupId = signatoryPerson;
                                csShareList.add( csShare ); 
                            }
                        }
                    }
                }
            }    

            System.debug('After Insert csShareList :: ' + csShareList );

            if(csShareList != null && csShareList.size() > 0){
                insert csShareList;
            }

        }catch(Exception e){
            exceptionInvoked = TRUE;
            System.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='PrecedentAfterInsertTriggerHandler';
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