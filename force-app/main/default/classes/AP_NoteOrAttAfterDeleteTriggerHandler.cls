/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Private Note trigger

Test Class:    AP_NoteOrAttAfterDeleteTriggerDispatcher_Test
History
10/6/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public class AP_NoteOrAttAfterDeleteTriggerHandler extends TriggerHandlerBase {
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();

    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    /*------------------------------------------------------------
    Author:        Dipankar Barman 
    Company:       Arxxus.com
    Description:   Handler function updates the number of private notes 
                   on a particular case record.
    
    History
    10/6/2015     Dipankar Barman       Created
    ------------------------------------------------------------*/
    private void process(TriggerParameters tp) {
        try{
            system.debug('---AP_NoteAfterDeleteTriggerHandler---');
            set<Id> attachmentIds= new set<Id>();
            set<Id> actionPlanIds= new set<Id>();
            set<Id> actionPlanOwnerIds= new set<Id>();
            for(Id apnaId:tp.oldMap.keySet()){
                AP_NoteOrAttachment__c apna= (AP_NoteOrAttachment__c)tp.oldMap.get(apnaId);
                attachmentIds.add(apna.Note_Attachment__c);
                actionPlanIds.add(apna.Action_Plan__c);

            }
            //other action plans  NoteOrAttachments associations for these notes and attachments
            Map<Id,AP_NoteOrAttachment__c> otherAP_NAs=new Map<Id,AP_NoteOrAttachment__c>([Select Id,Note_Attachment__c,Action_Plan__c, Action_Plan__r.ownerId from AP_NoteOrAttachment__c where    Note_Attachment__c in:attachmentIds ]);
            //remove netted AP_NAs and where AP owner are users and also create a AttachmentID vs set of AP owner IDs
            Map<Id,Set<Id>> requiredNAIdVSAPOwnerIds = new Map<Id,Set<Id>> ();
            for (Id apnaId:otherAP_NAs.keySet()){
                AP_NoteOrAttachment__c apna=otherAP_NAs.get(apnaId);
                if (tp.oldMap.containsKey(apnaId)){
                    otherAP_NAs.remove(apnaId);
                }
                else if (((String) apna.Action_Plan__r.ownerId).startsWith('005') ){
                    otherAP_NAs.remove(apnaId) ;
                }else{
                    Set<Id> requiredAPOwners=requiredNAIdVSAPOwnerIds.get(apna.Note_Attachment__c);
                    if (requiredAPOwners==null){
                        requiredAPOwners=new Set<Id>();
                        requiredNAIdVSAPOwnerIds.put(apna.Note_Attachment__c,requiredAPOwners);
                    }
                    requiredAPOwners.add(apna.Action_Plan__r.ownerId);
                } 

            }

            Map<Id,Action_Plan__c> actionPlans=new Map<Id,Action_Plan__c>([Select Id,ownerId from Action_Plan__c where  Id in:actionPlanIds]);
            Set<String> combined= new Set<String>();
            for(Id apnaId:tp.oldMap.keySet()){
                AP_NoteOrAttachment__c apna= (AP_NoteOrAttachment__c)tp.oldMap.get(apnaId);

                combined.add(''+apna.Note_Attachment__c+actionPlans.get(apna.Action_Plan__c).ownerId);
                actionPlanOwnerIds.add(actionPlans.get(apna.Action_Plan__c).ownerId);

            }
            list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId,ParentId
                                                               From NoteOrAttachment__Share 
                                                               Where ParentId IN: attachmentIds and UserOrGroupId in:actionPlanOwnerIds and  RowCause = :Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
            List<NoteOrAttachment__Share> forDeletion= new List<NoteOrAttachment__Share>();
            for (NoteOrAttachment__Share aShare:existingShareRecords){
                if (combined.contains(''+aShare.ParentId+aShare.UserOrGroupId) ){
                    
                    Set<Id> requiredAPOwners= requiredNAIdVSAPOwnerIds.get(aShare.ParentId);

                    if(requiredAPOwners!=null && requiredAPOwners.size()>0 && requiredAPOwners.contains(aShare.UserOrGroupId)) 
                    {
                        system.debug('aShare is required - '+aShare);
                    }else{
                        forDeletion.add(aShare);
                    }
                    
                    
                    
                }

            }
            system.debug('share records for deletion - '+ forDeletion);
            delete forDeletion;
        }catch(Exception e){
            system.debug(e);
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='AP_NoteOrAttAfterDeleteTriggerHandler';
            message.sourceFunction='process';
            if (tp!=null && tp.oldMap!=null)  message.referenceInfo=JSON.serialize(tp.oldMap.keySet());
            message.logMessage=e.getMessage();
            message.ex=e;
            message.debugLevel='Error';
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