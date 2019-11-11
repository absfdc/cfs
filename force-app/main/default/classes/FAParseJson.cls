public without sharing class FAParseJson {
	
	public boolean hasErrors;
	public cls_results[] results;
	class cls_results {
		public String referenceId;
		public string id;
		public cls_errors[] errors;
	}
	class cls_errors {
		public String statusCode;
		public String message;
		public cls_fields[] fields;
	}
	class cls_fields {
	}
	public list<FAParseJson> parse(String json){
		try
		{
			return (list<FAParseJson>) System.JSON.deserialize(json, LIST<FAParseJson>.class);
		}
		
		catch(Exception e)
		{
			DFSICoreService.writeToApplicationLogAndSendEmail('FAParseJson', //write to application log, stacktrace
													'parse',
													e.getMessage(),
													e,
													'Error');
			return null;
		}
	}
}