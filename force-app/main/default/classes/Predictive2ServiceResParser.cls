/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for predictive2 service response parser
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive2ServiceResParser implements NSWPointServiceResponseParser {
	private Predictive2ServiceResponse responseData;
	private Boolean isError = true;

	public void parse(NSWPointServiceResponse response){
		if(response != null){
			if(response.responseStatusCode == 200) {
				isError = false;
				System.debug(LoggingLevel.INFO, 'Success response received from predictive2 service.');
				responseData = (Predictive2ServiceResponse) JSON.deserialize(response.getResponseText(), Predictive2ServiceResponse.class);
			} else {
				System.debug(LoggingLevel.WARN, 'Request to predictive2 service failed with status code ' + response.responseStatusCode);
				responseData = (Predictive2ServiceResponse) JSON.deserialize(response.getResponseText(), Predictive2ServiceResponse.class);				
			}
		} else {
			throw new NSWPointServiceException('Response parser expects instance of NSWPointServiceResponse as input');
		}
	}

	public Predictive2ServiceResponse getResponseData(){
		return this.responseData;
	}

	public String getErrorMessage(){
		if(responseData != null){
			return responseData.errorMessage;
		}
		return null;
	}

	public Boolean isErrorResponse(){
		return this.isError;
	}
}