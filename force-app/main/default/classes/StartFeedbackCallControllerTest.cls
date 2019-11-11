@isTest
public class StartFeedbackCallControllerTest {
	
    @isTest
    static void testFeedbackController() {
        
        PageReference pageRef = Page.Start_Feedback_Call; //replace with your VF page name
        Test.setCurrentPage(pageRef);
        // Instantiate a new controller with all parameters in the page      
        StartFeedbackCallController controller = new StartFeedbackCallController();
        controller.getCaseRedirectURL();
    }
}