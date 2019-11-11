/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Helper class which will calculate the No of private 
               notes for a case and updates the Private Notes Count Field on Case

Test Class:    PrivateNoteTriggerDispatcher_Test
History
20/04/2015     Manish Damle       Created
01/05/2015     Brett Cawrse       Updated to without sharing
01/05/2017     Ian Fitzgerald     Added check to see if Private Notes rollup value has changed before 
                                  updating Case to save on SOQL queries and CPU.
------------------------------------------------------------*/
public without sharing class  NoteOrAttachmentCustomRollUpImpl {
    public static void calculateRollUp(map <Id, NoteOrAttachment__c > privateNotes, map <Id, NoteOrAttachment__c > oldPrivateNotes) {
        set <Id> caseIds = new set <Id> ();
        list <Case> casesToBeUpdated = new list <Case> ();
        
        for(Id privateNoteId : privateNotes.keySet()) {
            if(privateNotes.get(privateNoteId).Case__c != null)
                caseIds.add(privateNotes.get(privateNoteId).Case__c);
        }
        
        if(oldPrivateNotes != null) {
            for(Id privateNoteId : privateNotes.keySet()) {
                if(privateNotes.get(privateNoteId).Case__c != oldPrivateNotes.get(privateNoteId).Case__c) {
                    //private note parent has changed so capture old case id too
                    caseIds.add(oldPrivateNotes.get(privateNoteId).Case__c);
                }
            }
        }
        
        system.debug('------Cases------' + caseIds.size());
        /*
         * SNSW Changes START: Changes to prevent update where SNSW is responsible for case resolution. Added check for responsible party.
         */
        for(Case caseRecord : [Select Id, CaseNumber, Private_Notes_Count__c,
                                      (Select Id From NoteOrAttachments__r Where Privacy__c = 'Restricted') 
                               From Case 
                               Where Id IN: caseIds
                                    AND Responsible_Party__c != :GlobalConstants.RESPONSIBLE_PARTY_SNSW]) {
            
            //Ian Fitzgerald 01/05/2017 Added if-statement to prevent unncessary updates in order to to save on SOQL queries and CPU.                       
            if ( (caseRecord.NoteOrAttachments__r==null && caseRecord.Private_Notes_Count__c!=0) ||
                 caseRecord.Private_Notes_Count__c != caseRecord.NoteOrAttachments__r.size())
            {                       
                if(caseRecord.NoteOrAttachments__r != null) 
                    caseRecord.Private_Notes_Count__c = caseRecord.NoteOrAttachments__r.size();
                else 
                    caseRecord.Private_Notes_Count__c = 0;
                    
                system.debug('------CaseNumber---' + caseRecord.CaseNumber + '---' + caseRecord.Private_Notes_Count__c);                       
                casesToBeUpdated.add(caseRecord);
            }

        }
        /*
         * SNSW Changes END: Changes to prevent update where SNSW is responsible for case resolution. Added check for responsible party.
         */
        update casesToBeUpdated;
    }
}