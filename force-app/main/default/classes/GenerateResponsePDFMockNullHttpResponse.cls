@isTest
global class GenerateResponsePDFMockNullHttpResponse implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
      
      return NULL;
   }
}