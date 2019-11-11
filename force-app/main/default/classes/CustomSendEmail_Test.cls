@isTest
private class CustomSendEmail_Test {

    private static testMethod void testForErrorMsg() {
        Test.setCurrentPage(Page.CustomSendEmail);
        System.Test.startTest();
        CustomSendEmail_CX controller = new CustomSendEmail_CX(null);
        PageReference pgRef = controller.populateMessage();     
        System.Test.stopTest();     
        System.assert(pgRef == null);
    }
}