/*-----------------------------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Test Class for Note Or Attachment sharing rules.
History
<Date>         <Authors Name>     <Brief Description of Change>
27/04/2015     Manish Damle       Created
27/06/2017     Anil Sheoran       Merge changes from RMSORGUAT sandbox, SFCOE-1952 - Users in Motorways & Regional and Freight can't see attachment in the Ministerial Action Plans
-----------------------------------------------------------------------------------*/
@isTest
public class NoteOrAttachmentSharingHandler_Test {
    
    static {
        system.runAs(new User(id=UserInfo.getUserId())) {
            insert new CaseFilterSetting__c(Name='default',origin__c='Web',RecordType__c='Bus');
        }
    } 

    static testMethod void standardNoteOrAttachmentSharingTest() {
        User sercoAgent1, sercoAgent2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent1 = createTestUser('md');
        }

        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent2 =  createTestUser('sd');
        }
        
        system.runAs(sercoAgent1) {
            Case caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord;       
            
            NoteOrAttachment__c pn1 = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('Private Note 1', caseRecord.Id);
            pn1.Privacy__c = 'Standard';
            insert pn1;
        }
        
        list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: sercoAgent1.Id];
        system.assertEquals(1,existingShareRecords.size());
        //shared with sercoAgent2
        Id UserRoleId = [Select Id From UserRole Where Name='Serco' limit 1].Id;
        Group gp = [Select Name, DeveloperName, Id, type, relatedid From Group Where Type = 'RoleAndSubordinates' And RelatedId =: UserRoleId limit 1];

        existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: gp.Id];
        system.assertEquals(1,existingShareRecords.size());
    }
    
    static testMethod void restrictedNoteOrAttachmentSharingTest() {
        User sercoAgent1, sercoAgent2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent1 = createTestUser('md');
        }

        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent2 =  createTestUser('sd');
        }
        
        system.runAs(sercoAgent1) {
            Case caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord;       
            
            NoteOrAttachment__c pn1 = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('Private Note 1', caseRecord.Id);
            insert pn1;
        }
        
        list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: sercoAgent1.Id];
        system.assertEquals(1,existingShareRecords.size());
        //shared with sercoAgent2
    }    
 
    static testMethod void changedPrivacyToStandardNoteOrAttachmentSharingTest() {
        User sercoAgent1, sercoAgent2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent1 = createTestUser('md');
        }

        system.runAs(new User(Id = UserInfo.getUserId())) {
            sercoAgent2 =  createTestUser('sd');
        }
        
        system.runAs(sercoAgent1) {
            Case caseRecord = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            insert caseRecord;       
            
            NoteOrAttachment__c pn1 = NoteOrAttachmentTriggerDispatcher_Test.getNoteOrAttachment('Private Note 1', caseRecord.Id);
            insert pn1;
            
            list <NoteOrAttachment__c> attachments = [Select Id, OwnerId From NoteOrAttachment__c Where Id =: pn1.Id];
            system.debug('--pn1--' + attachments);
             
            list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: sercoAgent1.Id];
            system.assertEquals(1,existingShareRecords.size());
            //shared with sercoAgent2
            existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: sercoAgent2.Id];
            system.assertEquals(0,existingShareRecords.size());
            
            pn1.Privacy__c = 'Standard';
            update pn1;
        }
        
        list <NoteOrAttachment__Share> existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: sercoAgent1.Id];
        system.assertEquals(1,existingShareRecords.size());
        //shared with sercoAgent2
        Id UserRoleId = [Select Id From UserRole Where Name='Serco' limit 1].Id;
        Group gp = [Select Name, DeveloperName, Id, type, relatedid From Group Where Type = 'RoleAndSubordinates' And RelatedId =: UserRoleId limit 1];

        existingShareRecords = [Select Id, UserOrGroupId From NoteOrAttachment__Share Where UserOrGroupId =: gp.Id];
        system.assertEquals(1,existingShareRecords.size());
    }

    //Create two NoteOrAttachments against a case, one with Privacy Restricted, the other with Privacy Standard
    //Create two child action plans against the case
    //Link the two case attachments to each of the action plans
    //Assign each action plan to different Force.com license users
    //Expected result:
    //The NoteOrAttachment remains owned by the case owner
    //The 'Restricted' NoteOrAttachment gains two 'Action Plan Owner' sharing reasons: one to each Owner (Users) of the Action Plans
    //The 'Standard' NoteOrAttachment gains two 'Action Plan Owner' sharing reasons: to the two roles of the Owners of the Action Plans
    //Log in as each of the Action Plan owners and confirm visibility to the Notes against the Action Plans
    //Delink the NoteOrAttachment from one of the Action plans
    //Confirm that the NoteOrAttachment still exists, is still linked to the Case and the other Action Plan, 
    //and that there is now only one 'Action Plan Owner' sharing record against the Action Plan which was delinked

    static testMethod void testSharingToActionPlanOwnersAfterActionPlanUpdate(){
        List<NoteOrAttachment__c> attachments=getTwoTestNoteOrAttachment();
        insert attachments;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        List<AP_NoteOrAttachment__c> apnas= new List<AP_NoteOrAttachment__c>();
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna00);
        AP_NoteOrAttachment__c apna01= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna01);
        AP_NoteOrAttachment__c apna10= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna10);
        AP_NoteOrAttachment__c apna11= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna11);
        insert apnas;
        User sydTrainsUser1; 
        User sydTrainsUser2; 
        system.runAs(new User(Id = UserInfo.getUserId())) {
            sydTrainsUser1 = createTestUser('Agency SME', 'STA');
            sydTrainsUser2 = createTestUser('Agency SME', 'RMS');
        }
        system.debug('sydTrainsUser1 - '+sydTrainsUser1);
        system.debug('sydTrainsUser2 - '+sydTrainsUser2);
        
        plans[0].ownerId=sydTrainsUser1.Id;
        plans[1].ownerId=sydTrainsUser2.Id;
        Test.startTest();
        system.debug('plans - '+plans);
        update plans;
        Test.stopTest();
        List<AP_NoteOrAttachment__c> remainingApnas=[select Id from AP_NoteOrAttachment__c];
        system.assertEquals(4,remainingApnas.size());

        List<NoteOrAttachment__c> attachmentsOwnedByCreator= [select Id from NoteOrAttachment__c where ownerId= :UserInfo.getUserId()];
        system.assertEquals(2,attachmentsOwnedByCreator.size());
        List<NoteOrAttachment__Share> allNonOwnerShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where RowCause!=:Schema.NoteOrAttachment__Share.RowCause.Owner ];
        system.assert(!allNonOwnerShare.isEmpty());
        List<NoteOrAttachment__Share> restrictedShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where ParentId=:attachments[0].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assert(!restrictedShare.isEmpty());
        List<NoteOrAttachment__Share> standardShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where  ParentId=:attachments[1].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assert(!standardShare.isEmpty());
    }
    
    static testMethod void unDeleteTriggerRrrorScenarioCapture(){
        AP_NoteOrAttAfterUndeleteTriggerHandler handler = new AP_NoteOrAttAfterUndeleteTriggerHandler();
        handler.mainEntry(null);
        List<Application_Log__c> logs = [Select Id From Application_Log__c];
        System.assert(logs != null);
    }

    static testMethod void testSharingToActionPlanOwnersAfterActionPlanDelete(){
        List<NoteOrAttachment__c> attachments=getTwoTestNoteOrAttachment();
        insert attachments;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        List<AP_NoteOrAttachment__c> apnas= new List<AP_NoteOrAttachment__c>();
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna00);
        AP_NoteOrAttachment__c apna01= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna01);
        AP_NoteOrAttachment__c apna10= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna10);
        AP_NoteOrAttachment__c apna11= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna11);
        insert apnas;
        User sydTrainsUser1;
        User sydTrainsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            sydTrainsUser1 = createTestUser('Agency SME', 'STA');
            sydTrainsUser2 = createTestUser('Agency SME', 'RMS');
        }

        plans[0].ownerId=sydTrainsUser1.Id;
        plans[1].ownerId=sydTrainsUser2.Id;
        
        update plans;
        Test.startTest();
        delete plans[0];
        Test.stopTest();
        List<AP_NoteOrAttachment__c> remainingApnas=[select Id from AP_NoteOrAttachment__c];
        system.assertEquals(2,remainingApnas.size());

        List<NoteOrAttachment__c> attachmentsOwnedByCreator= [select Id from NoteOrAttachment__c where ownerId= :UserInfo.getUserId()];
        system.assertEquals(2,attachmentsOwnedByCreator.size());
 
        List<NoteOrAttachment__Share> restrictedShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where ParentId=:attachments[0].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assertEquals(1,restrictedShare.size());//one deleted
        List<NoteOrAttachment__Share> standardShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where  ParentId=:attachments[1].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assertEquals(2,standardShare.size());

    }

    static testMethod void testSharingToActionPlanOwnersAfterActionPlanUnDelete(){
        List<NoteOrAttachment__c> attachments=getTwoTestNoteOrAttachment();
        insert attachments;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        List<AP_NoteOrAttachment__c> apnas= new List<AP_NoteOrAttachment__c>();
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna00);
        AP_NoteOrAttachment__c apna01= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna01);
        AP_NoteOrAttachment__c apna10= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna10);
        AP_NoteOrAttachment__c apna11= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna11);
        insert apnas;
        User sydTrainsUser1;
        User sydTrainsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {

            sydTrainsUser1 = createTestUser('Agency SME', 'STA');
            sydTrainsUser2 = createTestUser('Agency SME', 'RMS');
        }

        plans[0].ownerId=sydTrainsUser1.Id;
        plans[1].ownerId=sydTrainsUser2.Id;
        

        update plans;
        delete plans[0];
        Test.startTest();
        undelete plans[0];
        Test.stopTest();
        List<AP_NoteOrAttachment__c> remainingApnas=[select Id from AP_NoteOrAttachment__c];
        system.assertEquals(4,remainingApnas.size());

        List<NoteOrAttachment__c> attachmentsOwnedByCreator= [select Id from NoteOrAttachment__c where ownerId= :UserInfo.getUserId()];
        system.assertEquals(2,attachmentsOwnedByCreator.size());
 
        List<NoteOrAttachment__Share> restrictedShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where ParentId=:attachments[0].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assertEquals(2,restrictedShare.size());
        List<NoteOrAttachment__Share> standardShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where  ParentId=:attachments[1].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assertEquals(2,standardShare.size());

    }

    static testMethod void testSharingToActionPlanOwnersAfterDeleteAP_NA(){
        List<NoteOrAttachment__c> attachments=getTwoTestNoteOrAttachment();
        insert attachments;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        List<AP_NoteOrAttachment__c> apnas= new List<AP_NoteOrAttachment__c>();
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna00);
        AP_NoteOrAttachment__c apna01= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna01);
        AP_NoteOrAttachment__c apna10= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna10);
        AP_NoteOrAttachment__c apna11= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna11);
        insert apnas;
        User sydTrainsUser1;
        User sydTrainsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {

            sydTrainsUser1 = createTestUser('Agency SME', 'STA');
            sydTrainsUser2 = createTestUser('Agency SME', 'RMS');
        }

        plans[0].ownerId=sydTrainsUser1.Id;
        plans[1].ownerId=sydTrainsUser2.Id;
        
        update plans;
        Test.startTest();
        delete apnas;
        Test.stopTest();
        List<AP_NoteOrAttachment__c> remainingApnas=[select Id from AP_NoteOrAttachment__c];
        system.assertEquals(0,remainingApnas.size());

        List<NoteOrAttachment__c> attachmentsOwnedByCreator= [select Id from NoteOrAttachment__c where ownerId= :UserInfo.getUserId()];
        system.assertEquals(2,attachmentsOwnedByCreator.size());
        List<NoteOrAttachment__Share> allNonOwnerShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where RowCause!=:Schema.NoteOrAttachment__Share.RowCause.Owner ];
        system.assert(!allNonOwnerShare.isEmpty());
        List<NoteOrAttachment__Share> restrictedShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where ParentId=:attachments[0].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        //system.assert(!restrictedShare.isEmpty());
        List<NoteOrAttachment__Share> standardShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where  ParentId=:attachments[1].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assert(!standardShare.isEmpty());

    }

    static testMethod void testSharingToActionPlanOwnersAfterUndeleteAP_NA(){
        List<NoteOrAttachment__c> attachments=getTwoTestNoteOrAttachment();
        insert attachments;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        List<AP_NoteOrAttachment__c> apnas= new List<AP_NoteOrAttachment__c>();
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna00);
        AP_NoteOrAttachment__c apna01= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna01);
        AP_NoteOrAttachment__c apna10= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[0].id 
            );
        apnas.add(apna10);
        AP_NoteOrAttachment__c apna11= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[1].id ,
            Note_Attachment__c = attachments[1].id 
            );
        apnas.add(apna11);
        insert apnas;
        User sydTrainsUser1;
        User sydTrainsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {

            sydTrainsUser1 = createTestUser('Agency SME', 'STA');
            sydTrainsUser2 = createTestUser('Agency SME', 'RMS');
        }
        
        plans[0].ownerId=sydTrainsUser1.Id;
        plans[1].ownerId=sydTrainsUser2.Id;
        update plans;
        delete apnas;

        Test.startTest();
        undelete apnas;
        Test.stopTest();
        List<AP_NoteOrAttachment__c> remainingApnas=[select Id from AP_NoteOrAttachment__c];
        system.assertEquals(4,remainingApnas.size());

        List<NoteOrAttachment__c> attachmentsOwnedByCreator= [select Id from NoteOrAttachment__c where ownerId= :UserInfo.getUserId()];
        system.assertEquals(2,attachmentsOwnedByCreator.size());
        List<NoteOrAttachment__Share> allNonOwnerShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where RowCause!=:Schema.NoteOrAttachment__Share.RowCause.Owner ];
        system.assert(!allNonOwnerShare.isEmpty());
        List<NoteOrAttachment__Share> restrictedShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where ParentId=:attachments[0].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assert(!restrictedShare.isEmpty());
        List<NoteOrAttachment__Share> standardShare=[SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM NoteOrAttachment__Share where  ParentId=:attachments[1].Id and RowCause=:Schema.NoteOrAttachment__Share.RowCause.Action_Plan_Owner__c ];
        system.assert(!standardShare.isEmpty());

    }
  
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create test users
    Parameters:    profile, role
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static User createTestUser(String profileName, String RoleName) {
        User user = new User();
        user.Username = 'md'+ System.currentTimeMillis() + '@demo.com';
        user.LastName = 'dam';
        user.Email = 'md@demo.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [Select Id From Profile Where Name =: profileName].Id;
        user.UserRoleId = [Select Id From UserRole Where DeveloperName =: RoleName].Id;
        user.LanguageLocaleKey = 'en_US';
        user.isActive = true;
        insert user;
        return user;
    }

    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will create test user with Serco Agent Profile 
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    public static User createTestUser(String lastName) {
        User user = new User();
        user.Username = lastName + System.currentTimeMillis() + '@demo.com';
        user.LastName = lastName;
        user.Email = lastName + '@demo.com';
        user.alias = lastName + 'test';
        user.TimeZoneSidKey = 'Australia/Sydney';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [Select Id From Profile Where Name='Serco Agent'].Id;
        user.UserRoleId = [Select Id From UserRole Where Name='Serco'].Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        return user;
    } 
    //first privacy restricted second standard
    public static List<NoteOrAttachment__c> getTwoTestNoteOrAttachment() {
        List<NoteOrAttachment__c> attachments= new List<NoteOrAttachment__c>();
        NoteOrAttachment__c pn1 = new NoteOrAttachment__c(privacy__c=GlobalConstants.NOTEORATTACHMENT_PRIVACY_RESTRICTED);
        NoteOrAttachment__c pn2 = new NoteOrAttachment__c(privacy__c=GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD);

        attachments.add(pn1);
        attachments.add(pn2);
        return attachments;            
    } 

    public static List<Action_Plan__c>  getTwoTestActionPlans() {
        List<Action_Plan__c> plans= new   List<Action_Plan__c>();
        Action_Plan__c ap1= new Action_Plan__c();
        Action_Plan__c ap2= new Action_Plan__c();
        plans.add(ap1);
        plans.add(ap2);
        return plans;

    }
    // START - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
    public static List<Action_Plan__c> getActionPlans(Integer noOfActionPlansToInsert) {

        List<Action_Plan__c> plans = new List<Action_Plan__c>();
        for(Integer i=0; i < noOfActionPlansToInsert; i++) {
            Action_Plan__c ap= new Action_Plan__c();
            plans.add(ap);
        }
        return plans;

    }
    static testMethod void testNoteOrAttachementSharing() {
        NoteOrAttachment__c pn = new NoteOrAttachment__c(privacy__c=GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD);
        insert pn;
        List<Action_Plan__c> plans= getTwoTestActionPlans();
        insert plans;
        
        AP_NoteOrAttachment__c apna00= new AP_NoteOrAttachment__c(
            Action_Plan__c = plans[0].id ,
            Note_Attachment__c = pn.id
            );
        insert apna00;
        
        User rmsUser1, rmsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            rmsUser1 = getRMSUser('RMS Case Manager','Motorways');
        }
        system.runAs(new User(Id = UserInfo.getUserId())) {
            rmsUser2 = getRMSUser('RMS Case Manager','Regional and Freight');
        }
        Action_Plan__c ap1 = plans.get(0);
        ap1.OwnerId = rmsUser1.Id;
        update ap1;
        
        Action_Plan__c ap2 = plans.get(0);
        ap2.OwnerId = rmsUser2.Id;
        update ap2;
        
        Id rmsRoleId = [SELECT Id FROM Group WHERE Type = 'Role' and DeveloperName = 'RMS'].Id;
        List<NoteOrAttachment__Share> noteShare = [SELECT ParentId,RowCause FROM NoteOrAttachment__Share 
                                             WHERE ParentId =: pn.Id AND RowCause = 'Action_Plan_Owner__c'];
        System.assert(noteShare.size() == 1);                                    
    }
    
    static testMethod void bulKTestNoteOrAttachementSharing() {
        
        List<NoteOrAttachment__c> noteAttachmentList = new List<NoteOrAttachment__c>();
        for(Integer i=0; i < 200; i++) {
            NoteOrAttachment__c noteAttachment = new NoteOrAttachment__c(privacy__c=GlobalConstants.NOTEORATTACHMENT_PRIVACY_STANDARD);
            noteAttachmentList.add(noteAttachment);
        }
        insert noteAttachmentList;
        List<Action_Plan__c> actionPlans = getActionPlans(200);
        insert actionPlans;
        
        List<AP_NoteOrAttachment__c> apNoteOrAttachments = new List<AP_NoteOrAttachment__c>();
        for(Integer i=0 ; i < 200; i++) {
            AP_NoteOrAttachment__c apna = new AP_NoteOrAttachment__c(
            Action_Plan__c = actionPlans[i].id ,
            Note_Attachment__c = noteAttachmentList[i].id
            );
            apNoteOrAttachments.add(apna);
        }
       
        insert apNoteOrAttachments;
        
        User rmsUser1, rmsUser2;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            rmsUser1 = getRMSUser('RMS Case Manager','Motorways');
        }
        system.runAs(new User(Id = UserInfo.getUserId())) {
            rmsUser2 = getRMSUser('RMS Case Manager','Regional and Freight');
        }

        List<Action_Plan__c> apToUpdate = new List<Action_Plan__c>();
        for(Action_Plan__c ap : actionPlans) {
            ap.OwnerId = rmsUser1.Id;
            apToUpdate.add(ap);
        }
        Test.startTest();
            update apToUpdate;
            System.debug('Number of query executed: '+Limits.getQueries());
            System.debug('Number of dml executed: '+Limits.getDMLStatements());
        Test.stopTest();
        
        
        Id rmsRoleId = [SELECT Id FROM Group WHERE Type = 'Role' and DeveloperName = 'RMS'].Id;
        List<NoteOrAttachment__Share> noteShareList = new List<NoteOrAttachment__Share>();
        for(NoteOrAttachment__Share shareRecord : [SELECT ParentId,RowCause FROM NoteOrAttachment__Share 
                                             WHERE ParentId IN : noteAttachmentList AND RowCause = 'Action_Plan_Owner__c']) {
            noteShareList.add(shareRecord);
            
        }
        System.debug('noteShareList:::'+noteShareList.size()); 
        System.assert(noteShareList.size() > 2); 
                                           
    }
    private static User getRMSUser(String profileName, String roleName) {
        
        User rmsUser = new User();
        rmsUser.Agency__c = GlobalConstants.RMS_AGENCY;
        rmsUser.Username = 'rmsTest' + System.currentTimeMillis() + '@demo.com';
        rmsUser.LastName = 'rmsTest';
        rmsUser.Email = 'rmsTest' + '@demo.com';
        rmsUser.alias = roleName.substring(0, 3);
        rmsUser.TimeZoneSidKey = 'Australia/Sydney';
        rmsUser.LocaleSidKey = 'en_US';
        rmsUser.EmailEncodingKey = 'ISO-8859-1';
        rmsUser.ProfileId = [Select Id From Profile Where Name=: profileName ].Id;
        rmsUser.UserRoleId = [Select Id From UserRole Where Name=: roleName].Id;
        rmsUser.LanguageLocaleKey = 'en_US';
        insert rmsUser;
        return rmsUser;
        
    }
    //END - Added by Anil Sheoran 27/06/2017 - Merge changes from RMSORGUAT sandbox
    
}