/**
 * @Author: Sauce Consulting
 * @Description: Address validation service request class
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class AddressValidationServiceRequest extends NSWPointServiceRequest{
    
    @TestVisible
    private static Boolean testPost = false;
    /**
     * create an instance of the rest request
     */
    public AddressValidationServiceRequest() {
    	super(NSWPointServiceRequest.RequestMethod.GET, 'application/json');
      if(testPost){
        this.method = NSWPointServiceRequest.RequestMethod.POST;
      }
    }  
}