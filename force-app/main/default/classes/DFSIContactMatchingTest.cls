@isTest
public class DFSIContactMatchingTest {
    
@isTest
    private static void testContactWithBothFirstLastName() {
        Contact testContactA = DFSIContactMatching.DFSIContactCheck('Test ContactA','test@test.com','123123123');
		System.assertEquals(testContactA.FirstName,'Test');
    }

@isTest    
    private static void testContactWithOnlyLastName() {
        Contact testContactA = DFSIContactMatching.DFSIContactCheck('ContactB','test@test.com','123123123');
		System.assertEquals(testContactA.LastName,'ContactB');
        System.assert(testContactA.FirstName == null);
    }

}