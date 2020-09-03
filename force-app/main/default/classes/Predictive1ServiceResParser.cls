/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for predictive1 service response parser
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive1ServiceResParser implements NSWPointServiceResponseParser {
	private List<Predictive1ServiceResponse> dataList;
	private Boolean isError = true;

	public void parse(NSWPointServiceResponse response){
		if(response != null){
			if(response.responseStatusCode == 200) {
				isError = false;
				System.debug(LoggingLevel.INFO, 'Success response received from predictive1 service.');
				dataList = (List<Predictive1ServiceResponse>) JSON.deserialize(response.getResponseText(), List<Predictive1ServiceResponse>.class);
			} else {
				System.debug(LoggingLevel.WARN, 'Request to predictive1 service failed with status code ' + response.responseStatusCode);
				Predictive1ServiceResponse errorRes = (Predictive1ServiceResponse) JSON.deserialize(response.getResponseText(), Predictive1ServiceResponse.class);
				dataList = new List<Predictive1ServiceResponse>();
				dataList.add(errorRes);
			}			
		} else {
			throw new NSWPointServiceException('Response parser expects instance of NSWPointServiceResponse as input');
		}
	}

	public Boolean isErrorResponse(){
		return this.isError;
	}

	public String getErrorMessage(){
		if(dataList != null && !dataList.isEmpty()) {
			return dataList[0].errorMessage;
		}
		return null;
	}

	public List<Predictive1ServiceResponse> getDataList(){
		return this.dataList;
	}

}