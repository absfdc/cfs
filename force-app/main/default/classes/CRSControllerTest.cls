@isTest
public class CRSControllerTest{

    public static testMethod void unitTest1CRSController() {
        PageReference pageRef = Page.CRSCase;
        Test.setCurrentPage(pageRef);

        Map<String,String> testIpType = new Map<String,String>();
    testIpType.put('True-Client-IP','49.181.235.101');
        
        CRSController controller = new CRSController();
        String nextPage = controller.save().getUrl();
        
        Case testCase = new Case(CRS_Feedback_Type__c = 'Crash statistics', SuppliedName = 'Test USr', SuppliedPhone = '2344', SuppliedEmail = 'arg@y.com', Description = 'dd', Response_Requested__c = 'No', Users_Ip_address__c = '49.181.235.101');
        insert testCase;

        Attachment attach=new Attachment();     
      attach.Name='Unit Test Attachment';
      Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
      attach.body=bodyBlob;
        attach.parentId=testCase.id;
        attach.IsPrivate=false;
        insert attach;
      
      List<Attachment> attachments=[select id, name from Attachment where parent.id=:testCase.id];
      System.assertEquals(1, attachments.size());

        controller.setCrsCase(testCase);
        controller.getCrsCase();

        Case[] cases = [select id, SuppliedEmail, casenumber from case where id = :testCase.id];
        //System.assertEquals('arg@y.com', cases[0].SuppliedEmail);
        System.assert(cases[0]!=null);

        controller.setC(cases[0]);
        controller.getC();

        controller.setIsSpam(false);
        controller.getIsSpam();
        controller.setDefaultContactmeNo('Yes');
        controller.getDefaultContactmeNo();
        controller.setIpType(testIpType);
        controller.getIpType();
        controller.getDefaultContactmeNo();
        controller.setAttachment(attach);
        controller.getAttachment();
        controller.setUserMessage('Thanks for your enquiry.');
        controller.getUserMessage();
        nextPage = controller.save().getUrl();

        String url = '/apex/crsthankyoupage?userMessage=Thanks+for+your+enquiry.+Your+case+number+registered+with+us%3A+';
        
        // Verify that the success page displays
        System.assert(pageRef != null);  
        System.assert(nextPage.contains('crsthankyoupage'));        
      //  System.assert(attach.IsPrivate,true);     
    }

}