/**
 * @Author: Sauce Consulting
 * @Description: Abstract client class to send request to service endpoint.
 * TestClass :      
 * History
 * Date            Author                      Comments
   --------------------------------------------------------------
   7-11-2019       Sauce Consulting            Initial Release
 */
public abstract class NSWPointServiceClient {

	public static final String VERSION = '1.0.0';
    
    /** the NSW point service resource locator */
    protected final NSWPointServiceLocator serviceLocator;        
    
    /**
     * Create an instance of the nsw point service client
     */
    public NSWPointServiceClient(NSWPointServiceLocator serviceLocator) {     
        this.serviceLocator = serviceLocator;        
    }

    /**
     * send request to the service endpoint
     */
    public NSWPointServiceResponse request(NSWPointServiceRequest serviceRequest){       
        HttpRequest request = setupRequest(serviceRequest);
        String responseText;
        Integer statusCode;

        System.debug(LoggingLevel.INFO, 'Request = ' + request.getEndpoint() + ',' +  request.getBody());
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug(LoggingLevel.INFO, 'Response = ' + response.getBody());
        responseText = (response.getBody() == null)? '' : response.getBody();
        statusCode = response.getStatusCode();
        
        return new NSWPointServiceResponse(responseText, statusCode);
    }
        
    /**
     * Create the http request to be sent on service endpoint
     */
    protected HttpRequest setupRequest(NSWPointServiceRequest serviceRequest){
        
        //String path = buildResourcePath(serviceRequest);
		String path = serviceLocator.endpoint();
        HttpRequest request = buildMethod(serviceRequest, path);
        
        //set default timeout for service call
        request.setTimeout(Integer.valueOf(Label.NSW_Point_Service_Call_Timeout));
        
        //add headers to request
        request.setHeader('User-Agent', 'tfnsw-salesforce/' + VERSION);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Accept-Charset', 'utf-8');        
        
        if(serviceRequest.contentType != null) {
            request.setHeader('content-type', serviceRequest.contentType);
        }
        
        if(serviceRequest.headers != null) {
        	for (String header : serviceRequest.headers.keySet()) {
        		request.setHeader(header, serviceRequest.headers.get(header));
        	}
        }
        
        return request;
    }
        
    /**
     * build the http request structure - url, query string
     */
    protected HttpRequest buildMethod(NSWPointServiceRequest request, String path) {
        if (request.method == NSWPointServiceRequest.RequestMethod.GET) {
            return buildGet(request, path);
        } else if (request.method == NSWPointServiceRequest.RequestMethod.POST) {
            return buildPost(request, path);
        } else {
            throw new NSWPointServiceException('Unsupported Method: ' + request.method);
        }
    }

    /**
     * build the URL for the passed service endpoint
     */
    protected URL buildUri(String endpoint) {
        String servicePath = endpoint;
        URL uri;
        try {
            uri = new URL(servicePath);
        } catch (Exception e) {
            throw new NSWPointServiceException('Invalid uri: ' + servicePath, e);
        }
        return uri;
    }

    /**
     * method to build GET request
     */
    protected virtual HttpRequest buildGet(NSWPointServiceRequest request, String endpoint){
        if(!endpoint.endswith('?')){
			endpoint += '?';
		}
		String resourceEndpoint = endpoint + request.requestBody;
        URL uri = buildUri(resourceEndpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(uri.toExternalForm());
        req.setMethod('GET');
        return req;
    }

    /**
     * method to build POST request
     */
    protected virtual HttpRequest buildPost(NSWPointServiceRequest request, String endpoint){
        URL uri = buildUri(endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(uri.toExternalForm());
        req.setMethod('POST');
        req.setBody(request.requestBody);
        return req;
    }
}