/*------------------------------------------------------------
Author:        Dipankar Barman
Company:       Arxxus.com
Description:   A utility class for the Action Plan Trigger

Test Class:    NotesOrAttachemnetSharingHandler_Test
History
17/06/2015     Dipankar Barman       Created
------------------------------------------------------------*/
public class ActionPlanBeforeDeleteTriggerHandler extends TriggerHandlerBase {
    
    List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
    
    public override void mainEntry(TriggerParameters tp) {
        process(tp);
    }
    
    public override void inProgressEntry(TriggerParameters tp) {
        System.debug('This is an example for reentrant code...');
    }
    
    private void process(TriggerParameters tp) {
        try {
           
            system.debug('actionplanIds for delete - '+tp.oldMap.keySet());

            list <AP_NoteOrAttachment__c> relatedAttachemnts=[select Id, Note_Attachment__c,Action_Plan__c from AP_NoteOrAttachment__c where Action_Plan__c in: tp.oldMap.keySet()];
            system.debug('relatedAttachemnts - '+relatedAttachemnts);
            
            

            if (relatedAttachemnts.size()>0) {
                set<Id> attachmentIds= new set<Id>();
                set<Id> actionPlanIds= new set<Id>();
                set<Id> actionPlanOwnerIds= new set<Id>();
                Set<String> combined= new Set<String>();

                for(AP_NoteOrAttachment__c apna:relatedAttachemnts){
                    attachmentIds.add(apna.Note_Attachment__c);
                    actionPlanIds.add(apna.Action_Plan__c);
                    combined.add(''+apna.Note_Attachment__c+((Action_Plan__c)(tp.oldMap.get(apna.Action_Plan__c))).ownerId);
                    actionPlanOwnerIds.add(((Action_Plan__c)(tp.oldMap.get(apna.Action_Plan__c))).ownerId);
                }
                //new
                //other action plans  NoteOrAttachments associations for these notes and attachments
	            Map<Id,AP_NoteOrAttachment__c> otherAP_NAs=new Map<Id,AP_NoteOrAttachment__c>([Select Id,Note_Attachment__c,Action_Plan__c, Action_Plan__r.ownerId from AP_NoteOrAttachment__c where    Note_Attachment__c in:attachmentIds ]);
	            //remove netted AP_NAs and where AP owner are users and also create a AttachmentID vs set of AP owner IDs
	            Map<Id,Set<Id>> requiredNAIdVSAPOwnerIds = new Map<Id,Set<Id>> ();
	            for (Id apnaId:otherAP_NAs.keySet()){
	                AP_NoteOrAttachment__c apna=otherAP_NAs.get(apnaId);
	                if (tp.oldMap.containsKey(apnaId)){
	                    otherAP_NAs.remove(apnaId);
	                }
	                else if (((String) apna.Action_Plan__r.ownerId).startsWith(GlobalConstants.USER_ID_PREFIX) ){
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
                //end new
                list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId,ParentId
                                                                   From NoteOrAttachment__Share 
                                                                   Where ParentId IN: attachmentIds and UserOrGroupId in:actionPlanOwnerIds and  RowCause = :Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
                system.debug('existingShareRecords - '+existingShareRecords);

                List<NoteOrAttachment__Share> forDeletion= new List<NoteOrAttachment__Share>();
                for (NoteOrAttachment__Share aShare:existingShareRecords){
                    //new
                    if (combined.contains(''+aShare.ParentId+aShare.UserOrGroupId) ){
	                	Set<Id> requiredAPOwners= requiredNAIdVSAPOwnerIds.get(aShare.ParentId);
	                	if(requiredAPOwners!=null && requiredAPOwners.size()>0 && requiredAPOwners.contains(aShare.UserOrGroupId)) 
	                    {
	                        system.debug('aShare is required - '+aShare);
	                    }else{
	                        forDeletion.add(aShare);
	                    }
	                }//end new



                   /* if (((String)aShare.UserOrGroupId).startsWith(GlobalConstants.USER_ID_PREFIX)
                        &&
                        combined.contains(''+aShare.ParentId+aShare.UserOrGroupId)
                        ) forDeletion.add(aShare);

					*/
                }
                system.debug('existingShareRecords forDeletion - '+forDeletion);
                delete forDeletion;
            }
            
        } catch(Exception e){
            ApplicationLogMessage message= new ApplicationLogMessage();
            message.source='ActionPlanBeforeDeleteTriggerHandler';
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