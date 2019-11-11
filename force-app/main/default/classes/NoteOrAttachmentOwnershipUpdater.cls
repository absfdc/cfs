/*---------------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Helper class for Case After update handler
               
Test Class:    CaseTriggerDispatcher_Test
History
<Date>         <Authors Name>     <Brief Description of Change>
04/05/2015     Manish Damle       Created
11/04/2017     Ian Fitzgerald     Added static Map to track Owners processed to reduce SOQL count
-----------------------------------------------------------------------------------------*/
public without sharing class NoteOrAttachmentOwnershipUpdater {
    
    /*********************************************************************************
    Added by Ian F. 11/Apr/2017 to store the Owners that have been processed. 
    *********************************************************************************/
    private static Map<Id, Id> NoteOrAttachment_processedOwnerChange = new Map<Id, Id>();
    /*********************************************************************************
     END -Added by Ian F. 11/Apr/2017
    *********************************************************************************/
    /*---------------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will chage the Owner of the private notes under case to new 
                   case owner whenever case owner is updated.
    Inputs:        Trigger context parameters

    History
    <Date>         <Authors Name>     <Brief Description of Change>
    04/05/2015     Manish Damle       Created
                                      Private Notes will be renamed to NoteOrAttachment
    -------------------------------------------------------------------------------------*/
    public void updateOwnership(TriggerParameters tp) {
        try {
            
            map <Id, Id> casesWithNewOwners = new map <Id, Id> (); //Case Id vs new owner id map
            map <Id, Id> casesWithNewOwnersAsQueueOrGroup = new map <Id, Id> (); //Case Id vs new owner as Queue or Group id map
            map <Id, Id> casesWithOldOwners = new map <Id, Id> (); //Case Id vd old owner id map
             
            for (Id aCaseId:tp.newMap.keySet()){ 
                //get the old and new case records
                Case oldCase=(Case)tp.oldMap.get(aCaseId);
                Case newCase=(Case)tp.newMap.get(aCaseId);
                
                System.debug('*******NoteOrAttachmentOwnershipUpdater.updateOwnership  oldCase.OwnerId : '+oldCase.OwnerId);
                System.debug('*******NoteOrAttachmentOwnershipUpdater.updateOwnership  newCase.OwnerId : '+newCase.OwnerId);
                
                //Added by Ian Fitzgerald (Transport NSW) 11/Apr/2017
                //Check if Owner has already been processed before executing sharing rule logic
                //This was causing unnecessary SOQL calls by re-executing after Workflow rule field updates
                //If a Workflow ever changed the Owner on the Case then the logic would re-execute
                if(oldCase.OwnerId != newCase.OwnerId && 
                      (NoteOrAttachment_processedOwnerChange.get(newCase.Id)==null || 
                       NoteOrAttachment_processedOwnerChange.get(newCase.Id)!=newCase.OwnerId)
                  )
                {       
                    //If case owner is changed and new owner is not a queue then store them in the map
                    if(((String) newCase.OwnerId).startsWith('005')) {
                        casesWithNewOwners.put(oldCase.Id, newCase.OwnerId);
                        casesWithOldOwners.put(oldCase.Id, oldCase.OwnerId);
                        system.debug('----Owner Changed To User---' + oldCase.OwnerId + ' -> '+ newCase.OwnerId);
                    } else if(((String) newCase.OwnerId).startsWith('00G')) {
                        casesWithNewOwnersAsQueueOrGroup.put(oldCase.Id, newCase.OwnerId);
                        casesWithOldOwners.put(oldCase.Id, oldCase.OwnerId);
                        system.debug('----Owner Changed To Queue Or Group---' + oldCase.OwnerId + ' -> '+ newCase.OwnerId);
                    }
                    NoteOrAttachment_processedOwnerChange.put(newCase.Id, newCase.OwnerId);
                }
            }
            
            if(casesWithOldOwners.keySet().size() == 0)
                return;
                
            //Fetch all the notes with Cases having their owner changed.
            list <NoteOrAttachment__c> privateNotes = [Select Id, Case__c, Privacy__c, OwnerId 
                                                       From NoteOrAttachment__c 
                                                       Where Case__c IN: casesWithOldOwners.keySet()];
                                        
            system.debug('----Private Notes---' + privateNotes.size());
                                        
            for(NoteOrAttachment__c privateNote : privateNotes) {
                //The owner of the NoteOrAttachment should always follow the Owner of the Case where the 
                //security disposition is 'Standard': i.e. it can be owned by a user, queue or Group
                if(privateNote.Privacy__c == GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD) {
                    if(casesWithNewOwners.containsKey(privateNote.Case__c) 
                        && casesWithNewOwners.get(privateNote.Case__c) != null) {
                        privateNote.OwnerId = casesWithNewOwners.get(privateNote.Case__c);
                    } else if(casesWithNewOwnersAsQueueOrGroup.containsKey(privateNote.Case__c) 
                                && casesWithNewOwnersAsQueueOrGroup.get(privateNote.Case__c) != null) {
                                privateNote.OwnerId = casesWithNewOwnersAsQueueOrGroup.get(privateNote.Case__c);
                    }
                } else if(privateNote.Privacy__c == GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED) {
                    //The owner of the NoteOrAttachment should only follow the Owner of the Case 
                    //where the security disposition is not 'Standard': i.e. ownership is never transferred 
                    //to a queue or Group, only to a user where it is <> Stanard (i.e. Restricted)
                    if(casesWithNewOwners.containsKey(privateNote.Case__c) 
                        && casesWithNewOwners.get(privateNote.Case__c) != null) {
                        privateNote.OwnerId = casesWithNewOwners.get(privateNote.Case__c);
                    } 
                }
            }
            
            update privateNotes;
        } catch(Exception e) {
            system.debug('---Exception After Trigger---' + e.getMessage());
            list <ApplicationLogMessage> messages = new list<ApplicationLogMessage>();
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='CaseAfterUpdateTriggerHandler';
            message.sourceFunction='process';
            if (tp!= null && tp.newMap != null) message.referenceInfo=JSON.serialize(tp.newMap.keySet());
            message.logMessage= e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //Throw exception. - Added by Ian F, tfNSW, 21/08/2017
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
        }
    }
}