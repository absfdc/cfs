/**
 * @Author: Sauce Consulting
 * @Description: Implementation of service locator class for address validation
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class AddressValidationServiceLocator implements NSWPointServiceLocator {
    
    private final String ENDPOINT;

    public AddressValidationServiceLocator(){
      ENDPOINT = NSWPointServiceCredsRetriever.getEndpoint(Label.Address_Validation_Service_Name);
    }
    
    /**
     * provide the endpoint for the service
     */
    public String endpoint(){
      return this.ENDPOINT;
    }    
}