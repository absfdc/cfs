public  class DFSICase {

	public DFSIAttribute attributes;

	public String Id;
	public String ContactId;
    public String CaseNumber;
    public String Description; 
    public String Expectation;
    public String Status;
    public String Priority; 
    public String Origin;
    public String RecordTypeId;
    public String Subject;
    public String SuppliedEmail;
    public String SuppliedName;
    public String CreatedDate;
    public String Type;
    public String SLA;
    public String SuppliedPhone;
    public Boolean Sent_VIA_Rest;
    public String What;
    public String Page;
    public String Location;
    public String Agency_Name;

    public DFSICombinedAttachment CombinedAttachments;

    public static List<DFSICase> parse(String JSONString) {
    	String parsedString = JSONString.replaceAll('__c', '');

    	return (List<DFSICase>) JSON.deserialize(JSONString, List<DFSICase>.class);
    }


}