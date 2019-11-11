/*
Date        :December 2017 
Description :Core Service Class for callout to DFSI Cases. Class to be run as Feedback Site Guest User
*/
public with sharing class DFSICoreService {
    
    private static final string DFSINamedCred='DFSI';
    
    //Method to Authenticate and Callout using Named Credentials    
    public static HTTPResponse doDFSICallout(string DFSIendpoint, String method){
        return doDFSICallout(DFSIendpoint, method, null);
    }
    
    public static HTTPResponse doDFSICallout(string DFSIendpoint, string method,  String contentType){
        return doDFSICallout(DFSIendpoint, method, contentType, '');
    }

        //Method to Authenticate and Callout using Named Credentials with content type as well
    public static HTTPResponse doDFSICallout(string DFSIendpoint, String method, String contentType, String JSONbody){
        
        HttpRequest req = new HttpRequest();
       
        req.setEndpoint('callout:'+getDFSINamedCred(DFSINamedCred)+'/'+DFSIendpoint); //Named credential name from custom setting
        req.setMethod(method);
        if(contentType != null)  {
            req.setHeader('Content-Type', contentType);
            req.setHeader('Sforce-Auto-Assign', 'False');
            req.setTimeOut(120000);
            req.setBody(JSONbody);
        }
        
        system.debug('DFSI request is '+req);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        return res;
    }
    //this method will query the custom settings and get the named credential name
    public static string getDFSINamedCred(string methodName){
        return DFSIEndpoint__c.getValues(methodName).DFSINamedCred__c;
    }
    
    //this method will query the custom settings and return the DFSI URL
    public static string getDFSIMethodURL(string methodName){
        return DFSIEndpoint__c.getValues(methodName).DFSIMethodURL__c;
    }    

    //exception handling method
    public static void writeToApplicationLog(string source,string function,string logmessage,Exception e,string debugLevel){
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
        
        ApplicationLogMessage message= new ApplicationLogMessage();
        message.source=source;
        message.sourceFunction=function;
        message.logMessage=logmessage;
        message.ex=e;
        message.debugLevel=debuglevel;
        messages.add(message);
        ApplicationLogUtility.logMessage(messages);
        messages.clear();
    }
    
    public static void writeToApplicationLogAndSendEmail(string source,string function,string logmessage,Exception e,string debugLevel){
        List<ApplicationLogMessage> messages =new List<ApplicationLogMessage>();
        
        ApplicationLogMessage message= new ApplicationLogMessage();
        message.source=source;
        message.sourceFunction=function;
        message.logMessage=logmessage;
        message.ex=e;
        message.debugLevel=debuglevel;
        messages.add(message);
        ApplicationLogUtility.logMessage(messages, true);
        messages.clear();
    }
    
}