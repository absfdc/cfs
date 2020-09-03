/**
 * @Author: Sauce Consulting
 * @Description: Helper class to invoke NSW point address service
 * TestClass :  
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   15-11-2019       Sauce Consulting            Initial Release
 */
public with sharing class NSWPointAddressHelper{

    /**
     * @Description: Method performs address search based on input string and returns list of probable addresses
     * @Input: Address string to search for.
     * @Output: List of addresses based on search results. 
                Each address will also have associated address id that can be used to retrieve address components
                In case of error/exception, response list will be empty.
     */
    public static List<Predictive1ServiceResponse> searchAddress(String searchKey){
        AddressDetails addrDetails = new AddressDetails();
        addrDetails.addressSearchStr = searchKey;

        Predictive1ServiceReqBuilder reqBuilder = new Predictive1ServiceReqBuilder();
        NSWPointServiceRequest request = reqBuilder.buildRequest(addrDetails);
        Predictive1ServiceLocator serviceLocator = new Predictive1ServiceLocator();
        Predictive1ServiceClient client = new Predictive1ServiceClient(serviceLocator);
        NSWPointServiceResponse response;
        List<Predictive1ServiceResponse> responseData = new List<Predictive1ServiceResponse>();
        try {
            response = client.request(request);
            Predictive1ServiceResParser parser = new Predictive1ServiceResParser();
            parser.parse(response);
            responseData = parser.getDataList();
            if(parser.isErrorResponse()){
                System.debug(LoggingLevel.WARN, parser.getErrorMessage());
                responseData = new List<Predictive1ServiceResponse>();
            }          
        } catch(Exception e){
            String responseTxt = response != null? response.getResponseText() : null;
            String requestTxt = request != null? request.requestBody : null;
            System.debug(LoggingLevel.ERROR, 'Response Msg: ' + responseTxt);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return responseData;
    }
    
    /**
     * @Description: Method retrieves the address components for the address id passed as input string
     * @Input: Address Id for which details address components needs to be returned.
     * @Output: Predictive2ServiceResponse instance that has address components. 
                In case of error/exception, address components will be null.
     */
    public static Predictive2ServiceResponse getAddressComponent(String addressId, String outputFields){
        AddressDetails addrDetails = new AddressDetails();
        addrDetails.addressId = addressId;
        addrDetails.outputFields = outputFields;

        Predictive2ServiceReqBuilder reqBuilder = new Predictive2ServiceReqBuilder();
        NSWPointServiceRequest request = reqBuilder.buildRequest(addrDetails);
        Predictive2ServiceLocator serviceLocator = new Predictive2ServiceLocator();
        Predictive2ServiceClient client = new Predictive2ServiceClient(serviceLocator);
        NSWPointServiceResponse response;       
        Predictive2ServiceResponse responseData = new Predictive2ServiceResponse();
        try {
            response = client.request(request);
            Predictive2ServiceResParser parser = new Predictive2ServiceResParser();
            parser.parse(response);
            responseData = parser.getResponseData();
            if(parser.isErrorResponse()){
                System.debug(LoggingLevel.WARN, parser.getErrorMessage());
                System.debug(parser.getErrorMessage());
                responseData = new Predictive2ServiceResponse();
            }         
        } catch(Exception e){
            String responseTxt = response != null? response.getResponseText() : null;
            String requestTxt = request != null? request.requestBody : null;
            System.debug(LoggingLevel.ERROR, 'Response Msg: ' + responseTxt);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
        }

        return responseData;
    }

    /**
     * @Description: Method validates the address based on data passed as input string
     * @Input: Address string to be verified.
     * @Output: AddressValidationServiceResponse instance that has address components and validation status. 
                In case of error/exception, address components will be null.
     */
    public static AddressValidationServiceResponse validateAddress(String address){
        AddressDetails addrDetails = new AddressDetails();
        addrDetails.addressSearchStr = address;

        AddressValidationServiceReqBuilder reqBuilder = new AddressValidationServiceReqBuilder();
        NSWPointServiceRequest request = reqBuilder.buildRequest(addrDetails);
        AddressValidationServiceLocator serviceLocator = new AddressValidationServiceLocator();
        AddressValidationServiceClient client = new AddressValidationServiceClient(serviceLocator);
        NSWPointServiceResponse response;
        AddressValidationServiceResponse responseData = new AddressValidationServiceResponse(); 

        try {
            response = client.request(request);
            AddressValidationServiceResParser parser = new AddressValidationServiceResParser();
            parser.parse(response);
            responseData = parser.getResponseData();
            if(parser.isErrorResponse()){
                System.debug(LoggingLevel.WARN, parser.getErrorMessage());
                System.debug(parser.getErrorMessage());
                responseData = new AddressValidationServiceResponse();
            }          
        } catch(Exception e){
            String responseTxt = response != null? response.getResponseText() : null;
            String requestTxt = request != null? request.requestBody : null;
            System.debug(LoggingLevel.ERROR, 'Response Msg: ' + responseTxt);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
        }

        return responseData;
    }
}