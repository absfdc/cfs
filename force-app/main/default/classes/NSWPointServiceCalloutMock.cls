@isTest
public class NSWPointServiceCalloutMock implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(NSWPointServiceMockResponse.getResponseStr());
        response.setStatusCode(200);
        if(NSWPointServiceMockResponse.errorResponse){
            response.setStatusCode(500);
        }
        return response; 
    }
}