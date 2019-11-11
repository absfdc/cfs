/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   This class is responsible for handling the Apex sharing
               for NoteOrAttachment object

Test Class:    NoteOrAttachmentSharingHandler_Test
History
24/04/2015     Manish Damle       Created
02/05/2017     Ian Fitzgerald     Remove call to getOwnerIdVsRoleId by passing result to getGroupIdForRolesOfActionPlanOwners
27/06/2017     Anil Sheoran       Merge changes from RMSORGUAT sandbox, SFCOE-1952 - Users in Motorways & Regional and Freight can't see attachment in the Ministerial Action Plans
------------------------------------------------------------*/
public without sharing class NoteOrAttachmentSharingHandler {
    private String rowCause;
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will actually recaclulate the sharing
                   for attachments
    Inputs:        list of attachments
    History
    24/04/2015     Manish Damle       Created
    ------------------------------------------------------------*/
    public void share(list <NoteOrAttachment__c> attachments) {
        rowCause=Schema.NoteOrAttachment__Share.RowCause.Standard_Sharing__c;
        //New share records to be created
        list <NoteOrAttachment__Share> newShareRecords = new list <NoteOrAttachment__Share>();
        //Set of all roles
        map <Id,Id> userRoles = new map <Id,Id>();
        //map of user and his role
        map <Id,Id> roleVsGroupId = new map <Id,Id>();
        //Temp list of users
        list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId
                                                               From NoteOrAttachment__Share 
                                                               Where ParentId IN: attachments and (RowCause = :Schema.NoteOrAttachment__Share.RowCause.Standard_Sharing__c or RowCause='Owner')];
        system.debug('------Existing Share Records-----' + existingShareRecords.size());
        //delete the existing sharing and create new share records
        database.delete(existingShareRecords, false);
        userRoles = getRoleVsUsersMap(attachments); //gets all the role ids asssociated with the owners.
        roleVsGroupId = getRoleVsGroupIdMap(userRoles.values()); //get all group ids associated with the Roles

        for(NoteOrAttachment__c att : attachments) {
            //If privacy is standard then share that attachment or 
            //note with all the users having the same role as that of Note/Attachment owner
            String owner = att.OwnerId;
            system.debug('------Owner Id-----' + owner);
            if(att.Privacy__c == GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD && owner.startsWith(GlobalConstants.USER_ID_PREFIX)) {
                if(userRoles.containsKey(att.OwnerId) 
                    && roleVsGroupId.containsKey(userRoles.get(att.OwnerId))
                    && roleVsGroupId.get(userRoles.get(att.OwnerId)) != null) {
                    //Share the record with all the roles and subordinates
                    newShareRecords.add(getShareRecord(att.Id, roleVsGroupId.get(userRoles.get(att.OwnerId))));
                    system.debug('---------' + att.Name + ' shared with group ' +  roleVsGroupId.get(userRoles.get(att.OwnerId)));            
                }
            }
        } 
        
        system.debug('-----New Share Records------' + newShareRecords.size());
        insert newShareRecords;
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create map of role vs users 
                   in that role
    Inputs:        list of attachments
    History
    24/04/2015     Manish Damle       Created
    ------------------------------------------------------------*/    
    private map <Id, Id> getRoleVsUsersMap(list <NoteOrAttachment__c> attachments) {
        set <Id> ownerIds = new set <Id>();
        map <Id,Id> userVsrole = new map <Id,Id>();
        //Get all owners
        for(NoteOrAttachment__c att : attachments) {
            String owner = att.OwnerId;
            if(owner.startsWith(GlobalConstants.USER_ID_PREFIX)) {
                ownerIds.add(att.OwnerId);
            }
        }
        
        //Get roles for all the owners
        system.debug('------Owner Ids-----' + ownerIds);
        for(User u : [Select Id, UserRoleId, FirstName 
                      From User 
                      Where Id IN: ownerIds 
                        And IsActive = true]) {

             if(u.UserRoleId == null) continue;
             userVsrole.put(u.Id, u.UserRoleId);
        }

        return userVsrole;
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method creates map of user ids vs their role ids
    Inputs:        list of users
    History
    24/04/2015     Manish Damle       Created
    ------------------------------------------------------------*/   
    private map <Id,Id> getRoleVsGroupIdMap(list <Id> roles) {
        map <Id,Id>  roleVsGroupId = new map <Id,Id> ();
        for (Group gp:[Select Name, DeveloperName, Id, type, relatedid From Group Where Type = 'RoleAndSubordinates' And RelatedId IN: roles]){
            if (!roleVsGroupId.containsKey(gp.Relatedid)){
                roleVsGroupId.put(gp.Relatedid, gp.Id);
            } 
        }
        return roleVsGroupId;
    }
    
    /*------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will return the Share object record to
                   be created
    Inputs:        parent id, share with User Id

    History
    24/04/2015     Manish Damle       Created
    01/05/2014     Brett Cawrse       Added row cause and set class to without sharing
    ------------------------------------------------------------*/       
    private NoteOrAttachment__Share getShareRecord(Id parentId, String shareWith) {
        return new NoteOrAttachment__Share(ParentId = parentId,
                                           AccessLevel = 'Edit',
                                           UserOrGroupId = shareWith,
                                           RowCause = rowCause);
    }

    /*------------------------------------------------------------
    Author:        Dipankar Barman
    Company:       Arxxus.com
    Description:   This method will actually recaclulate the sharing when they are shared with actionPlanOwners.
    Inputs:        list of attachments
    History
    24/04/2015     Dipankar Barman       Created
    1/7/2015       Manish Damle          Added the sharing for Roles and subordinates
    ------------------------------------------------------------*/
    public void shareWithActionPlanOwners(list <AP_NoteOrAttachment__c> apAttachments) {
        rowCause=Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ;
        Set<Id>attachmentIds=new Set<Id>();
        Set<Id>actionPlanIds= new Set<Id>();
        Map<Id,AP_NoteOrAttachment__c> apAttachmentsMap= new Map<Id,AP_NoteOrAttachment__c>(apAttachments);
        for (AP_NoteOrAttachment__c anApNoteOrAttachment:apAttachments){
            attachmentIds.add(anApNoteOrAttachment.Note_Attachment__c);
            actionPlanIds.add(anApNoteOrAttachment.Action_Plan__c);
        }
        List<AP_NoteOrAttachment__c> otherApAttachments=[Select Id,Note_Attachment__c, Action_Plan__c from AP_NoteOrAttachment__c where Note_Attachment__c in:attachmentIds and Id not in:apAttachmentsMap.keySet()];
        for (AP_NoteOrAttachment__c anApNoteOrAttachment:otherApAttachments){
            attachmentIds.add(anApNoteOrAttachment.Note_Attachment__c);
            actionPlanIds.add(anApNoteOrAttachment.Action_Plan__c);
        }
        List<AP_NoteOrAttachment__c> combined=  new List<AP_NoteOrAttachment__c>();
        combined.addAll(otherApAttachments);
        combined.addAll(apAttachments);
        Map<Id,Action_Plan__c> actionPlanMap = new Map<Id,Action_Plan__c>( [select Id,ownerId from  Action_Plan__c where Id in:actionPlanIds]);
        system.debug('actionPlanMap - '+actionPlanMap);
        Map<Id,NoteOrAttachment__c> notesMap = new Map<Id,NoteOrAttachment__c>([select Id,Privacy__c,OwnerId,Name from NoteOrAttachment__c where Id in:attachmentIds]);
        List<Action_Plan__c> actionPlans = actionPlanMap.values();
        //New share records to be created
        list <NoteOrAttachment__Share> newShareRecords = new list <NoteOrAttachment__Share>();
        //map of role vs list of users in that role
        map <Id,list <User>> roleVsUsers = new map <Id,list <User>> ();
        //map of user and his role
        map <Id,Id> userVsRole = new map <Id,Id>();
        //Temp list of users
        list <User> users = new list <User>();
        
        list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId
                                                               From NoteOrAttachment__Share 
                                                               Where ParentId IN: attachmentIds and RowCause = :Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.debug('------Existing Share Records-----' + existingShareRecords.size());
        //delete the existing sharing and create new share records
        database.delete(existingShareRecords, false);
        
        //Added by Ian Fitzgerald, 02/05/2017  Remove call to getOwnerIdVsRoleId by passing result to getGroupIdForRolesOfActionPlanOwners
        Map<Id,Id> ownerIdVsRoleId = getOwnerIdVsRoleId(actionPlans);
        Map<Id,Id> roleIdVsGroupId =getGroupIdForRolesOfActionPlanOwners(actionPlans, ownerIdVsRoleId);
        //END - Added by Ian Fitzgerald 02/05/2017
        
        system.debug('roleIdVsGroupId - '+roleIdVsGroupId);
        system.debug('ownerIdVsRoleId - '+ ownerIdVsRoleId);
        
        // START - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
        Set<Id> rmsUsers = new Set<Id>();
        rmsUsers = RMSSharingHandlerQueryHelper.getRMSUserIds();
        Id rmsRoleId = RMSSharingHandlerQueryHelper.getRMSRoleAndSubordinateId();
        //END - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
        
        userVsRole = getUserVsRoleMap(users); //get all roles associated with the owners*/
        Set<String> rolesShared= new Set<String> ();

        for (AP_NoteOrAttachment__c anApNoteOrAttachment:combined){
            String owner = actionPlanMap.get(anApNoteOrAttachment.Action_Plan__c).ownerId;
            NoteOrAttachment__c att= notesMap.get(anApNoteOrAttachment.Note_Attachment__c);
            system.debug('------Owner Id-----' + owner);
            if(att.Privacy__c == GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD && owner.startsWith(GlobalConstants.USER_ID_PREFIX)) {
                if (!rolesShared.contains(''+ownerIdVsRoleId.get(owner)+att.Id) ) {
                    Id groupId=roleIdVsGroupId.get(ownerIdVsRoleId.get((Id)owner));
                    if (groupId!=null){
                         newShareRecords.add(getShareRecord(att.Id, roleIdVsGroupId.get(ownerIdVsRoleId.get((Id)owner))));
                        rolesShared.add(''+ownerIdVsRoleId.get(owner)+att.Id);
                        system.debug('----Attachment---' + att.Name + ' shared with groupId for role role- ' + roleIdVsGroupId.get(ownerIdVsRoleId.get((Id)owner)));

                    }
                   
                }
                // START - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
                if(rmsUsers.contains(owner)) {
                    if(!rolesShared.contains(''+rmsRoleId+att.Id)) {
                        System.debug('action plan owner is from RMS Agency.');
                        newShareRecords.add(getShareRecord(att.Id,rmsRoleId));
                        rolesShared.add(''+rmsRoleId+att.Id);
                    }
                }
                //END - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
                
            }else if (att.Privacy__c == GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED && owner.startsWith(GlobalConstants.USER_ID_PREFIX)){
                system.debug('----Attachment---' + att.Name + ' shared with ' + owner);
                newShareRecords.add(getShareRecord(att.Id, (Id)owner));
            }
        }
        system.debug('-----New Share Records------' + newShareRecords.size());
        insert newShareRecords;
    }
 
    private map <Id,Id> getUserVsRoleMap(list <User> users) {
        map <Id,Id> userVsRole = new map <Id,Id> ();
        for(User u: users) {
            if(u.UserRoleId == null) continue; //skip user with no role
            userVsRole.put(u.Id, u.UserRoleId);
        }
        return userVsRole;
    }

    private map <Id,Id>  getOwnerIdVsRoleId(list<Action_Plan__c> actionPlans){
        set <Id> ownerIds = new set <Id>();
        Map <Id,Id> userRoles = new Map <Id,Id>();
        //Get all owners
        for(Action_Plan__c ap : actionPlans) {
            String owner = ap.OwnerId;
            if(owner.startsWith(GlobalConstants.USER_ID_PREFIX)) {
                ownerIds.add(ap.OwnerId);
            }
        }
        
        //Get roles for all the owners
        system.debug('------Owner Ids-----' + ownerIds);
        for(User u : [Select Id, UserRoleId, FirstName 
                      From User 
                      Where Id IN: ownerIds 
                        And IsActive = true]) {
             if(u.UserRoleId == null) continue;
             userRoles.put(U.Id,u.UserRoleId);
        }
        return userRoles;
    }

    //Ian Fitzgerald, 02/05/2017  Remove call to getOwnerIdVsRoleId by passing result to getGroupIdForRolesOfActionPlanOwners
    private map <Id,Id>  getGroupIdForRolesOfActionPlanOwners(list<Action_Plan__c> actionPlans, Map<Id,Id> ownerRole){
        map <Id,Id> rolevsGroup = new map <Id,Id> ();

        //Map<Id,Id> ownerRole=getOwnerIdVsRoleId(actionPlans);
        for (Group gp:[SELECT Name, DeveloperName, Id, type, relatedid from Group where Type ='RoleAndSubordinates' and relatedid in:ownerRole.values()]){
            if (!rolevsGroup.containsKey(gp.relatedid)){
                rolevsGroup.put(gp.relatedid,gp.Id);
            }
        }
        return rolevsGroup;
    }  
}