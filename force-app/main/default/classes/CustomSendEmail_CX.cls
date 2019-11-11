public class CustomSendEmail_CX {

    public CustomSendEmail_CX(ApexPages.StandardController controller) {  }
    
    public PageReference populateMessage() {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please use the buttons "Email Customer" or "Email Staff Member" in the case feed view to send an email.')); 
        return null;
    }
}