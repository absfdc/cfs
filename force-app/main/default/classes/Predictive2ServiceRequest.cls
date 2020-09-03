/**
 * @Author: Sauce Consulting
 * @Description: Predictive2 service request class
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public class Predictive2ServiceRequest extends NSWPointServiceRequest{
    @TestVisible
    private static Boolean testGet = false;
    /**
     * create an instance of the rest request
     */
    public Predictive2ServiceRequest() {
    	super(NSWPointServiceRequest.RequestMethod.POST, 'application/json');
      if(testGet){
        this.method = NSWPointServiceRequest.RequestMethod.GET;
      }
    }  
}