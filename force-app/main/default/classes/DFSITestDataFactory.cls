@isTest
public class DFSITestDataFactory
{
	static Integer s_num = 1;
	
	public static Case  createCase() {
        Case caseRecord = new Case();
        caseRecord.Taxonomy_Location__c = 'Sydney';
        caseRecord.Agency__c = '';
        caseRecord.Origin = 'Web';
        caseRecord.Priority = 'Normal';
        caseRecord.Type = 'Complaint';
        caseRecord.Description = 'Test case'; 
        return caseRecord;
    }   

    public static String getFakeId(Schema.SObjectType sot)
   {
      String result = String.valueOf(s_num++);
      return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
   }
}