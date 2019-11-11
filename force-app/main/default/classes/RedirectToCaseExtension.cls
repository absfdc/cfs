public class RedirectToCaseExtension {
	
	private final Case cse;
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public RedirectToCaseExtension(ApexPages.StandardController stdController) {
        this.cse = (case)stdController.getRecord();
    }

    public String getBaseURL() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
    
}