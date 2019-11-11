public class StartFeedbackCallController {
	
    public Flow.Interview.Feedback_Call myFlow { get; set; }
    public String getCaseID() {
    	if (myFlow==null) return '';
    	else return myFlow.NewCaseId;
    }
    
    public String getCaseNumber() {
    	if (myFlow==null) return '';
    	else return myFlow.CaseNumber;
    }
    
    public PageReference getCaseRedirectURL(){
        System.debug('case redirect url.');
        //PageReference q = new PageReference(ApexPages.currentPage().getUrl());
    	//q.setRedirect(true);
    	PageReference p = new PageReference(URL.getSalesforceBaseUrl().toExternalForm()+'/apex/RedirectToCaseIntermediatePage?Id='+getCaseID()+'&caseNumber='+getCaseNumber());
    	p.setRedirect(true);
    	return p;
    }
}