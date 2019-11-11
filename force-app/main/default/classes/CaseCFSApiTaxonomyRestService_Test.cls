@isTest
private class CaseCFSApiTaxonomyRestService_Test {
    
    static testMethod void getAllTest() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{}';
           
        req.requestBody = Blob.valueOf(JSONString);   

        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
    }
    
    static testMethod void getIssueTest() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{"Type":"Issue"}';
           
        req.requestBody = Blob.valueOf(JSONString);

        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
    }
    
    static testMethod void getModeTest() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{"Mode":"Road"}';
           
        req.requestBody = Blob.valueOf(JSONString);
           
        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
        
    }
    
    static testMethod void getAllLevelsTest() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{"Type":"Issue",'+
                              '"Mode":"Road",'+
                              '"Level1":"Roads",'+
                              '"Level2":"Traffic Management & Safety",'+
                              '"Level3":"Safety barriers"'+
                            '}';
           
        req.requestBody = Blob.valueOf(JSONString);
        
        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==200);
        
    }
    
    static testMethod void getFieldNameError() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{"Type":"Issue",'+
                              '"Mode":"Road",'+
                              '"Issue1":"Roads",'+
                              '"Level2":"Traffic Management & Safety",'+
                              '"Level3":"Safety barriers"'+
                            '}';
           
        req.requestBody = Blob.valueOf(JSONString);
        
        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
        
    }
    
    static testMethod void getJSONError() {
        setupTaxonomy();
        RestRequest req = new RestRequest();
        RestContext.response = new RestResponse();
        
        req.requestURI = System.URL.getSalesforceBaseUrl() + '/services/apexrest/v1/salesforce/taxonomy';
        req.httpMethod = 'POST';
        
        String JSONString = '{"Type":"Issue",'+
                              '"Mode":"Road",'+
                              '"Issue1":"Roads",'+
                              '"Level2":"Traffic Management & Safety"'+
                              '"Level3":"Safety barriers"'+
                            '}';
           
        req.requestBody = Blob.valueOf(JSONString);
        
        RestContext.request = req;

        CaseCFSApiTaxonomyRestService.doPost();
        
        RestResponse res = RestContext.response;
        System.Assert(res.statusCode==400);
        
    }
    
    public static void setupTaxonomy() {      
        Taxonomy_Metadata__c mode = new Taxonomy_Metadata__c(Type__c='Issue', Status_Customer_Facing__c='Active', 
        Status_Staff_Facing__c='Active', Name='Road', Agency__c='RMS', Customer_Value__c ='Road');
        insert mode;
        
        Taxonomy_Metadata__c level1 = new Taxonomy_Metadata__c(Type__c='Issue', Status_Customer_Facing__c='Active', 
        Status_Staff_Facing__c='Active', Name='Roads', Agency__c='RMS', Customer_Value__c ='Roads', Parent_Id__c = mode.Id);
        insert level1;

        Taxonomy_Metadata__c level2 = new Taxonomy_Metadata__c( Type__c='Issue', Parent_Id__c = level1.Id,Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Traffic Management & Safety',  Agency__c='RMS', Customer_Value__c ='Traffic Management & Safety');
        insert level2;

        Taxonomy_Metadata__c level3 = new Taxonomy_Metadata__c( Type__c='Issue', Parent_Id__c = level2.Id, Status_Customer_Facing__c='Active', Status_Staff_Facing__c='Active',  Name='Safety barriers',  Agency__c='RMS', Customer_Value__c ='Safety barriers');
        insert level3;
    }
}