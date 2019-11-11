@isTest
private class WebToCaseErrorPage_Test {
    private static final String ERROR_MSG = 'Error message for webform.';

    private static testMethod void testForErrorWithoutReferer() {
        createCustomSettings(GlobalConstants.WEBTOCASE_SOURCE_TNSW_TRAINS);
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseErrorPage);
        WebToCaseErrorPage_CC controller = new WebToCaseErrorPage_CC();        
        System.Test.stopTest();
        System.assert(String.isBlank(controller.source));
    }
    
    private static testMethod void testForErrorWithoutRefererButWithSource() {
        createCustomSettings(GlobalConstants.WEBTOCASE_SOURCE_TNSW_TRAINS);
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseErrorPage);
        ApexPages.currentPage().getParameters().put('source', 'rms');
        WebToCaseErrorPage_CC controller = new WebToCaseErrorPage_CC();        
        String errorMessage = controller.getErrorMessage();
        System.Test.stopTest();
        System.assert(!String.isBlank(controller.source));
        System.assert(controller.source == 'rms');
        System.assert(errorMessage == ERROR_MSG);
    }
    
    private static testMethod void testForErrorPageWithReferer() {
        createCustomSettings('rms');
        System.Test.startTest();
        System.Test.setCurrentPage(System.Page.WebToCaseErrorPage);
        ApexPages.currentPage().getHeaders().put('Referer', 'https://tfnsw.nsw.gov.au/feedback?source=maritime&about=road');
        WebToCaseErrorPage_CC controller = new WebToCaseErrorPage_CC();
        controller.setErrorMessage(null);
        String errorMessage = controller.getErrorMessage();
        System.Test.stopTest();
        System.assert(controller.source == 'rms');
        System.assert(errorMessage == ERROR_MSG);
    }   
    
    private static void createCustomSettings(String name) {
        WebToCaseErrorMessages__c setting = new WebToCaseErrorMessages__c();
        setting.Name = name;
        setting.Message__c = ERROR_MSG ;
        insert setting;
    }
}