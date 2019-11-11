@isTest
public class FAParseJSONTest {
	

    public static string createJSONString() {
		list<Case> lstcase = [select id from case limit 1];
		if(lstcase.size()>0)
		{
			String jsonString = '{"hasErrors":false,"results":[{"referenceId":"'+lstcase[0].id+'","id":"5000k000009TqgCAAS"}]}';
			return jsonString;
		}
		else
		{
			return '';
		}
    }
    public static string createJSONStringWithIncorrectId() {
		String jsonString = '{"hasErrors":false,"results":[{"referenceId":"5000k000009TqgCAAS","id":"5000k000009TqgCAAS"}]}';
		return jsonString;
    }
    
        public static string createIncorrectJSONString() {
		String jsonString = 'xyz';
		return jsonString;
    }

}