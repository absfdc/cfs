//CLASS NOT IN USE FOR NOW> TOOLING API NOT USED.
@isTest
global class MockToolingAPIGetCOHttpResponseGenerator implements HttpCalloutMock {
	
	global HTTPResponse respond(HTTPRequest req) { 
		system.debug('---------Mock Custom Object Response-------' + req.getEndpoint());
        // Create a fake response
        String responseBody = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":' + 
        					  '"CustomEntityDefinition","records":[{"attributes":{"type":"CustomObject","url":' + 
        					  '"/services/data/v28.0/tooling/sobjects/CustomObject/01IO00000001IgBMAU"},' + 
        					  '"Id":"01IO00000001IgBMAU","DeveloperName":"Taxonomy_Metadata"}]}';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        res.setBody(responseBody);
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
}