@isTest
public class MaskContactDetailsBatchTest {
@testSetup static void setupData() 
   {
        List<Account> lAccounts = new List<Account> ();
        for (Integer i = 0; i< 50; i++)
        {
            Account account = new Account();
            account.Name = 'Test' + i;
            lAccounts.add(account);
        }
        insert lAccounts;
        Integer i = 0;
        List<Contact> lContacts = new List<Contact> ();
        for (Account a : lAccounts)
        {
            Contact testContact = new Contact();
            testContact.AccountId = a.Id;
            testContact.FirstName = 'TestFirst' + i;
            testContact.LastName = 'TestLast' + i;
            testContact.Email = 'test' + i + '@testemail.com';
            lContacts.add(testContact);
            i++;
        }
        insert lContacts;

   }

    @isTest
    private static void testMaskContactDetailsBatch() {
        Test.startTest();
        MaskContactDetailsBatch batchClass = new MaskContactDetailsBatch();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    private static void testMaskContactDetailsBatchSingleParam() {
        Test.startTest();
        MaskContactDetailsBatch batchClass = new MaskContactDetailsBatch('test@test.com', 20, true);
        Database.executeBatch(batchClass);
        Test.stopTest();
    }
}