/**
 * @Author: Sauce Consulting
 * @Description: Implementation class for predictive1 service request builder
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive1ServiceReqBuilder implements NSWPointServiceRequestBuilder {
    
    /**
     * Implementation of buildRequest for predictive1 service
     */
    public NSWPointServiceRequest buildRequest(Object reqParams) {
	    Predictive1ServiceRequest request = new Predictive1ServiceRequest();
        if(reqParams instanceof AddressDetails) {
			AddressDetails addrDetails = (AddressDetails) reqParams;
			if(String.isBlank(addrDetails.addressSearchStr)){
                throw new NSWPointServiceException('Address to search is mandatory parameter for predictive1 service');
            }				
			String address = 'address=' + getEncodedParameter(addrDetails.addressSearchStr);
			String stateTerritory = (String.isBlank(addrDetails.stateTerritory)? '' : '&stateTerritory=' + getEncodedParameter(addrDetails.stateTerritory));
			String maxNumberOfResults = (addrDetails.maxNumberOfResults > 5? '&maxNumberOfResults=' + getEncodedParameter('' +addrDetails.maxNumberOfResults) : '');
			String dataset = (String.isBlank(addrDetails.dataset)? '' : '&dataset=' + getEncodedParameter(addrDetails.dataset));
			String addressType = (String.isBlank(addrDetails.addressType)? '' : '&addressType=' + getEncodedParameter(addrDetails.addressType));
			request.requestBody = address + stateTerritory + maxNumberOfResults + dataset + addressType;

            request.headers = new Map<String, String>();
            request.headers.put('x-api-key',NSWPointServiceCredsRetriever.getKey(Label.Predictive1_Service_Name));
            request.headers.put('Access-Control-Request-Headers','x-requested-with');
        }else{
			throw new NSWPointServiceException('Invalid parameter to build predictive1 service request');
        }
	    return request;
    } 

    private String getEncodedParameter(String param){
        return EncodingUtil.urlEncode(param, 'UTF-8');
    }
}