@isTest
private class CaseCustomRollUpImpl_Test {

    static testMethod void calculateRollupTest1() {
        Case parentCase = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase;
        
        Test.startTest();
            Case childCase1 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase1.ParentId = parentCase.Id;
            Case childCase2 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase2.ParentId = parentCase.Id;
            insert new list <Case> { childCase1, childCase2 };
        Test.stopTest();
        
        Case c = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
        system.assertEquals(2, c.Child_Cases_Count__c);
    }
    
    
    static testMethod void calculateRollupTest2() {
        Case parentCase1 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase1;
        
        Case parentCase2 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase2;
        
        Test.startTest();
            Case childCase1 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase1.ParentId = parentCase1.Id;
            Case childCase2 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase2.ParentId = parentCase1.Id;
            insert new list <Case> { childCase1, childCase2 };
            
            Case c = [Select Child_Cases_Count__c From Case Where Id =: parentCase1.Id limit 1];
            system.assertEquals(2, c.Child_Cases_Count__c);
            //Reparent the case
            childCase2.ParentId = parentCase2.Id;
            update childCase2;
        Test.stopTest();
        Case pc1 = [Select Child_Cases_Count__c From Case Where Id =: parentCase1.Id limit 1];
        system.assertEquals(1, pc1.Child_Cases_Count__c);  
                
        Case pc2 = [Select Child_Cases_Count__c From Case Where Id =: parentCase2.Id limit 1];
        system.assertEquals(1, pc2.Child_Cases_Count__c);
        
    }
    
    
    static testMethod void calculateRollupTest3() {
        Case parentCase = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase;
        
        Test.startTest();
            Case childCase1 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase1.ParentId = parentCase.Id;
            Case childCase2 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase2.ParentId = parentCase.Id;
            insert new list <Case> { childCase1, childCase2 };
            Case c = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
            system.assertEquals(2, c.Child_Cases_Count__c);
            //delete the case 
            delete childCase2;
        Test.stopTest();
        
        Case c1 = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
        system.assertEquals(1, c1.Child_Cases_Count__c);
    }
    
    static testMethod void calculateRollupTest4() {
        Case parentCase = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase;
        
        Test.startTest();
            Case childCase1 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase1.ParentId = parentCase.Id;
            Case childCase2 = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
            childCase2.ParentId = parentCase.Id;
            insert new list <Case> { childCase1, childCase2 };
            Case c = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
            system.assertEquals(2, c.Child_Cases_Count__c);
            //delete the case 
            delete childCase2;
            
            Case c1 = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
            system.assertEquals(1, c1.Child_Cases_Count__c);
        Test.stopTest();
        undelete childCase2;
        
        Case c2 = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
        system.assertEquals(2, c2.Child_Cases_Count__c);
    }
    
    static testMethod void calculateRollupTest5() {
        Case parentCase = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
        insert parentCase;
        Test.startTest();
            list <Case> childCases = new list <Case>();
            for(Integer i = 0; i < 5; i++) { 
                Case c = NoteOrAttachmentTriggerDispatcher_Test.getCaseRecord();
                c.ParentId = parentCase.Id;
                childCases.add(c);
            }
            insert childCases; 
        Test.stopTest();
        Case c1 = [Select Child_Cases_Count__c From Case Where Id =: parentCase.Id limit 1];
        system.assertEquals(5, c1.Child_Cases_Count__c);
    }
}