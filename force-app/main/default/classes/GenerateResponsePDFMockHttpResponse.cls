@isTest
global class GenerateResponsePDFMockHttpResponse implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
      
      RecordType rt = [Select Id From RecordType Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_NAME_MINCORR_ROAD limit 1];
   
      Case tempCase = new Case(Subject = 'Pothole',
                               Description = 'Theres a pothole in the east street, west end crossing in front of busstop',                       
                               Status = 'New',
                               RecordTypeId = rt.Id,
                               Priority = 'Normal',
                               Modes__c = 'MAGS', 
                               Portfolio__c = 'Roads, Maritime and Freight',
                               Signatory__c = 'Minister for Roads, Maritime and Freight');
                               
      insert tempCase;
      
      Attachment attach = new Attachment();    
      attach.Name = 'Dummy Conga PDF Response';
      Blob bodyBlob = Blob.valueOf('Dummy Conga PDF Response');
      attach.body = bodyBlob;
      attach.parentId = tempCase.id;
      insert attach;
      
      //Create a fake response
      HttpResponse res = new HttpResponse();
      res.setBody(''+attach.Id);
      res.setStatusCode(200);
      return res;
   }
}