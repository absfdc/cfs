/**
Overview:       This class refreshes the Access Token used by the Einstein API when it makes callouts to retrieve predictions from
                the Einstein model.
                It will be initially scheduled to run every 24 hours.
Created Date :  20/Feb/2018
Created By:     Ian Fitzgerald, TNSW Salesforce Practice
 */
global class RefreshEinsteinToken implements Schedulable {

	   global void execute(SchedulableContext SC) {
           refreshToken();
	   }
	   
	   @future(callout=true)	
	   static public void refreshToken(){
	   	   try{
	   	       //Retrieve the Custom Metadata Type Settings
    	       Einstein_API_Settings__c settings = [SELECT Einstein_Base_URL__c, Einstein_Registration_Email__c, PEM_FileName__c, Token_Expiration_Time__c
	                                                FROM Einstein_API_Settings__c  limit 1];
	                                                    
	           String AUTH = settings.Einstein_Base_URL__c+'/oauth2/token';
	       
	           //Create the JWT                                             
    	       JWT jwt = new JWT('RS256');
           
               //Read the Key from the PEM file
               ContentVersion base64Content = [SELECT Title, VersionData FROM ContentVersion where Title=:settings.PEM_FileName__c ORDER BY Title limit 1];
               String keyContents = base64Content.VersionData.tostring();
               keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
               keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
               keyContents = keyContents.replace('\n', '');
               jwt.pkcs8 = keyContents;
               
                   jwt.iss = 'developer.force.com';
               jwt.sub = settings.Einstein_Registration_Email__c;
               jwt.aud = AUTH;
               jwt.validFor = integer.valueOf(settings.Token_Expiration_Time__c);
               String access_token = JWTBearerFlow.getAccessToken(AUTH, jwt);
               if (access_token==null || access_token.length()==0){
               	   System.debug('RefreshEinsteinToken : JWTBearerFlow did not return an Access Token');
    		
                   List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

                   ApplicationLogMessage message = new ApplicationLogMessage();
                   message.source = 'RefreshEinsteinToken';
                   message.sourceFunction = 'refreshToken';
                   message.logMessage = 'JWTBearerFlow did not return an Access Token';
                   message.debugLevel = GlobalConstants.ERROR;
                   messages.add(message);
                   ApplicationLogUtility.logMessage(messages);
                   messages.clear();
               }
               else{
                   settings.Einstein_Access_Token__c  = access_token;
           
                   update settings;
               }
	   	   }
    	catch(Exception e){
    		System.debug(e);
    		
            List<ApplicationLogMessage> messages = new List<ApplicationLogMessage>();

            ApplicationLogMessage message = new ApplicationLogMessage();
            message.source = 'RefreshEinsteinToken';
            message.sourceFunction = 'refreshToken';
            message.logMessage = e.getMessage();
            message.ex = e;
            message.debugLevel = GlobalConstants.ERROR;
            messages.add(message);
            
            ApplicationLogUtility.logMessage(messages);
            messages.clear();
            //THROW_EXCEPTIONS is a global constant, it is set to the current user's "Throw Exceptions" value 
            //"Throw Exceptions" is a checkbox on the User record. 
            if (GlobalConstants.THROW_EXCEPTIONS){
                Throw(e);
            }
    	}
	   }
	   
}