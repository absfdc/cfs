//JIRA# SFCOE-1837 Send an email notification with User License overuse information - 26-05
//This is a Job that builds Maps of allowed and actual user license usage and sends that info. for agencies who are exceeding the maximum allowed license usage 

public class NotifyForLicenseOveruse Implements Schedulable{
    String emailBody = '<html><head><style>table {    border-collapse: collapse;    width: 100%;}th, td {    text-align: left;    padding: 8px;}tr:nth-child(even){background-color: #f2f2f2}th {    background-color: #4CAF50;    color: white;}</style></head><body><h2>Salesforce Agency License Overuse Alert!</h2><table>  <tr>    <th>Agency</th>    <th>Allowed Usage</th>    <th>Actual License Usage</th>      <th>Nature of License</th></tr>';
    
    public void execute(SchedulableContext sc){	
        countUserLicenses();
    }
    
    public void countUserLicenses(){
        Map<String, Integer> actualAgencyVsUserCountforcecom= new Map<String, Integer>();
        Map<String, Integer> actualAgencyVsUserCountSalesforceLicense= new Map<String, Integer>();
        
        String salesforceLicense = 'Salesforce';
        String forcecomAppSubscriptionLicense = 'Force.com - App Subscription';
        
        try{
            List<AggregateResult> agencyVsUserCountforcecom = [Select count(Id) actualuserCount, agency__c from User where Profile.UserLicense.Name = :forcecomAppSubscriptionLicense and IsActive=true group by agency__c];
            for(AggregateResult ar : agencyVsUserCountforcecom){
                System.debug('Force.com Licenses: '+ar.get('actualuserCount')+'-'+ar.get('agency__c'));
                if(ar.get('agency__c')!=null && String.valueof(ar.get('agency__c')).length()>0)
                    if(!actualAgencyVsUserCountforcecom.keyset().contains(String.valueOf(ar.get('agency__c'))))
                    actualAgencyVsUserCountforcecom.put(String.valueOf(ar.get('agency__c')), Integer.valueOf(ar.get('actualuserCount')));
                else if(!actualAgencyVsUserCountforcecom.keyset().contains('No Agency specified on User'))
                    actualAgencyVsUserCountforcecom.put('No Agency specified on User', Integer.valueOf(ar.get('actualuserCount')));
            }
            
            List<AggregateResult> agencyVsUserCountSalesforce = [Select count(Id) actualuserCount, agency__c from User where Profile.UserLicense.Name = :salesforceLicense and IsActive=true group by agency__c];
            for(AggregateResult ar : agencyVsUserCountSalesforce){
                System.debug('Salesforce Licenses: '+ar.get('actualuserCount')+'-'+ar.get('agency__c'));
                if(ar.get('agency__c')!=null && String.valueof(ar.get('agency__c')).length()>0)
                    if(!actualAgencyVsUserCountSalesforceLicense.keyset().contains(String.valueOf(ar.get('agency__c'))))
                    actualAgencyVsUserCountSalesforceLicense.put(String.valueOf(ar.get('agency__c')), Integer.valueOf(ar.get('actualuserCount')));
                else if(!actualAgencyVsUserCountSalesforceLicense.keyset().contains('No Agency specified on User'))
                    actualAgencyVsUserCountSalesforceLicense.put('No Agency specified on User', Integer.valueOf(ar.get('actualuserCount')));
            }        
            
            List<Agency_Specific_License_limits__c> maxAllowedAgencyLicensesList = Agency_Specific_License_limits__c.getall().values();
            Map <String, Integer> maxForceComAllowedAgencyLicensesMap = new Map <String, Integer>();
            Map <String, Integer> maxSalesforceAllowedAgencyLicensesMap = new Map <String, Integer>();
            
            for(Agency_Specific_License_limits__c maxAllowedAgencyLicensesItem : maxAllowedAgencyLicensesList){
                maxForceComAllowedAgencyLicensesMap.put(maxAllowedAgencyLicensesItem.name, Integer.valueOf(maxAllowedAgencyLicensesItem.Max_Force_com_Licenses_Allowed__c));
                maxSalesforceAllowedAgencyLicensesMap.put(maxAllowedAgencyLicensesItem.name, Integer.valueOf(maxAllowedAgencyLicensesItem.Max_Service_Cloud_Licenses_Allowed__c));
            }
            
            
            if(!emailBody.contains('</html>')){
                
                for(String keyId: actualAgencyVsUserCountforcecom.Keyset()){
                    if(maxForceComAllowedAgencyLicensesMap.keyset().contains(keyId)){
                        if (actualAgencyVsUserCountforcecom.get(keyId) > maxForceComAllowedAgencyLicensesMap.get(keyId))
                            emailBody += '<tr><td>' + keyId + '</td><td>' + maxForceComAllowedAgencyLicensesMap.get(keyId) 
                            + '</td><td>' + actualAgencyVsUserCountforcecom.get(keyId) + '</td><td>' + forcecomAppSubscriptionLicense +'</td></tr>';
                    }
                }        
                
                for(String keyId: actualAgencyVsUserCountSalesforceLicense.Keyset()){
                    if(maxSalesforceAllowedAgencyLicensesMap.keyset().contains(keyId)){
                        if (actualAgencyVsUserCountSalesforceLicense.get(keyId) > maxSalesforceAllowedAgencyLicensesMap.get(keyId))
                            emailBody += '<tr><td>' + keyId + '</td><td>' + maxSalesforceAllowedAgencyLicensesMap.get(keyId) 
                            + '</td><td>' + actualAgencyVsUserCountSalesforceLicense.get(keyId) + '</td><td>Salesforce Service Cloud</td></tr>';
                    }
                }
                
            }
            
            emailBody = emailBody + '</table></body></html>';
            sendmail(emailBody);
            
        }catch(Exception e){
            ApplicationLogUtility.logMessage('Error','NotifyForLicenseOveruse','countUserLicenses',e.getMessage(),'',Null,Null,'','',userinfo.getuserid());
        }
    }
    
    public void sendmail(String emailBody){
        List<String> agencyEmails = new List<String>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<Agency_Specific_License_Email_Config__c> agencyEmailsConfiguration = Agency_Specific_License_Email_Config__c.getall().values();
        for(Agency_Specific_License_Email_Config__c agencyEmailConfiguration: agencyEmailsConfiguration){
            agencyEmails.add(agencyEmailConfiguration.Recepient_Email__c);
        }
        
        email.setSubject('Salesforce User License Overuse Alert!');
        email.setHTMLBody(emailBody);
        email.setToAddresses(agencyEmails);
        Messaging.sendEmail(New Messaging.SingleEmailMessage[]{email});
    }
}