@isTest
public class UpdateContactPhoneFields_Batch_Test {
    private static List<Contact> conList;
    static testMethod void testPositive(){
        String query = 'SELECT Id FROM Contact WHERE HomePhone != \'\' OR MobilePhone != \'\' OR Other_Phone__c != \'\' OR Phone != \'\' ' ;
    	conList = new List<Contact>();
        createTestData(10);
        Contact cont = new Contact(
                firstName = 'TestCon'+0,
                LastName = 'Test',
                Phone = '9876543210',
                homePhone= '+61 7896541230',
                mobilePhone='0123456789',
                other_Phone__c='+91 147-258 369@0',
                email = 'test@test.com');
        conList.add(cont);
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] newResult = Database.insert(conList, dmlOpt);
        
        Test.startTest();
        UpdateContactPhoneFields_Batch obj = new UpdateContactPhoneFields_Batch();
        Database.executeBatch(obj);
       	Test.stopTest();
		
        for(Contact con: [SELECT Id, Normalized_Home_Phone__c, Normalized_Mobile__c, Normalized_Other_Phone__c, Normalized_Work_Phone__c FROM Contact]){
            System.debug('ID = '+con.Id);
        	System.assertEquals(con.Normalized_Home_Phone__c, '07896541230');
            System.assertEquals(con.Normalized_Mobile__c, '0123456789');
            System.assertEquals(con.Normalized_Other_Phone__c, '01472583690');
            System.assertEquals(con.Normalized_Work_Phone__c, '09876543210');
        }
    }
    
    static testMethod void testLargeDataSet(){
        String query = 'SELECT Id FROM Contact WHERE HomePhone != \'\' OR MobilePhone != \'\' OR Other_Phone__c != \'\' OR Phone != \'\' ' ;
    	conList = new List<Contact>();
        createTestData(101);
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] newResult = Database.insert(conList, dmlOpt);
        
        Test.startTest();
        UpdateContactPhoneFields_Batch obj = new UpdateContactPhoneFields_Batch();
        Database.executeBatch(obj);
       	Test.stopTest();
		
        for(Contact con: [SELECT Id, Normalized_Home_Phone__c, Normalized_Mobile__c, Normalized_Other_Phone__c, Normalized_Work_Phone__c FROM Contact]){
            System.debug('ID = '+con.Id);
        	System.assertEquals(con.Normalized_Home_Phone__c, '07896541230');
            System.assertEquals(con.Normalized_Mobile__c, '0123456789');
            System.assertEquals(con.Normalized_Other_Phone__c, '01472583690');
            System.assertEquals(con.Normalized_Work_Phone__c, '09876543210');
        }
    }
    
    static void createTestData(Integer no){
        for(Integer i = 1; i < no+1; i++){
            Contact con = new Contact(
                firstName = 'TestCon'+i,
                LastName = 'Test',
                Phone = '9876543210',
                homePhone= '+61 7896541230',
                mobilePhone='0123456789',
                other_Phone__c='+91 147-258 369@0',
                email = 'test@test.com');
            conList.add(con);
        }
    }
}