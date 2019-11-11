//CLASS NOT IN USE FOR NOW> TOOLING API NOT USED.
@isTest
global class MockToolingAPIGetOFHttpResponseGenerator implements HttpCalloutMock{
	global HTTPResponse respond(HTTPRequest req) {
		system.debug('---------Mock Custom Field Response-------' + req.getEndpoint());
	    String responseBody = '{"size":12,"totalSize":12,"done":true,"queryLocator":null,' + 
							       '"entityTypeName":"CustomFieldDefinition","records":[' + 
							       '{"attributes":{"type":"CustomField","url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZKRMA2"},'+
							       '"Id":"00NO0000001aZKRMA2","DeveloperName":"Type"},{"attributes":'+
							       '{"type":"CustomField","url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZKgMAM"},'+
							       '"Id":"00NO0000001aZKgMAM","DeveloperName":"Modes"},{"attributes":'+
							       '{"type":"CustomField","url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZKlMAM"},'+
							       '"Id":"00NO0000001aZKlMAM","DeveloperName":"Parent_Id"},{"attributes":{"type":"CustomField",'+
							       '"url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZKvMAM"},"Id":'+
							       '"00NO0000001aZKvMAM","DeveloperName":"Value"},{"attributes":{"type":"CustomField","url"'+
							       ':"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZL0MAM"},"Id":"00NO0000001aZL0MAM", ' + 
							       '"DeveloperName":"Parent_Value"},{"attributes":{"type":"CustomField","url":' + 
							       '"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZLAMA2"},"Id":' + 
							       '"00NO0000001aZLAMA2","DeveloperName":"KPI"},{"attributes":{"type":"CustomField","url":' + 
							       '"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZLPMA2"},"Id":"00NO0000001aZLPMA2","DeveloperName":"Driver"},' + 
							       '{"attributes":{"type":"CustomField","url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZLjMAM"},' + 
							       '"Id":"00NO0000001aZLjMAM","DeveloperName":"Status_Staff_Facing"},{"attributes":{"type":"CustomField","url":' + 
							       '"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001aZLtMAM"},"Id":"00NO0000001aZLtMAM",' + 
							       '"DeveloperName":"Status_Customer_Facing"},{"attributes":{"type":"CustomField","url":' + 
							       '"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001au9FMAQ"},"Id":"00NO0000001au9FMAQ","DeveloperName":"Level_1_Value"},' + 
							       '{"attributes":{"type":"CustomField","url":"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001b1GmMAI"},' + 
							       '"Id":"00NO0000001b1GmMAI","DeveloperName":"Customer_Value"},{"attributes":{"type":"CustomField","url":' + 
							       '"/services/data/v28.0/tooling/sobjects/CustomField/00NO0000001b1R1MAI"},' + 
							       '"Id":"00NO0000001b1R1MAI","DeveloperName":"Accountability"}]}';
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json;charset=UTF-8');
		res.setBody(responseBody);
		res.setStatusCode(200);
		res.setStatus('OK');

        return res;
    }
}