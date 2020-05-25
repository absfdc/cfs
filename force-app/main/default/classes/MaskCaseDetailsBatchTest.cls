@isTest
public class MaskCaseDetailsBatchTest {
@testSetup static void setupData() 
   {
        List<Case> lCases = new List<Case> ();
        for (Integer i = 0; i< 50; i++)
        {
            Case testCase = new Case();
            testCase.Subject = 'test subject-' + i;
            testCase.SuppliedEmail = 'test' + i + '@testemail.com';
            lCases.add(testCase);
            i++;
        }
        insert lCases;

   }

    @isTest
    private static void testMaskCaseDetailsBatch() {
        Test.startTest();
        MaskCaseDetailsBatch batchClass = new MaskCaseDetailsBatch();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    private static void testMaskCaseDetailsBatchSingleParam() {
        Test.startTest();
        MaskCaseDetailsBatch batchClass = new MaskCaseDetailsBatch('test@test.com');
        Database.executeBatch(batchClass);
        Test.stopTest();
    }
}