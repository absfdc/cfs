/**
 * @Author: Sauce Consulting
 * @Description: Virtual request class for NSW Point service
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   6-11-2019       Sauce Consulting            Initial Release
 */
public virtual class NSWPointServiceRequest {
    
    /** method type */
    public enum RequestMethod { GET, POST }
	
	/** service request content type */
	public String contentType {get; set;}
	
	/** service request body */
	public String requestBody {get; set;}
	
    /** request method type */
    public RequestMethod method { get; set;}
    
    /** service request headers */
    public Map<String, String> headers { public get; public set; }
    
    public NSWPointServiceRequest(NSWPointServiceRequest.RequestMethod requestMethod, String contentType) {
      this.method = requestMethod;
		  this.contentType = contentType;
    }
}