//JIRA# SFCOE-1837 Send an email notification with User License overuse information - 26-05
//SFCOE-2876 Restructured to provide detail information and summary - Abhi Indulkar

//This is a Job that builds Maps of allowed and actual user license usage and sends that info. for agencies who are exceeding the maximum allowed license usage 

public class NotifyForLicenseOveruse Implements Schedulable{
    String emailBody =  '<html><head><style>table {border: 1px solid black;width: 100%;}th, td {text-align: left;    padding: 8px;}tr:nth-child(even){background-color: #f2f2f2}th {    background-color: #4CAF50;    color: white;} summary {  font-weight: bold;  background-color: lightgrey;}</style>'
                        + '</head><body><h2>Salesforce Agency License Overuse Alert!</h2>'
                        + '<table>  <tr>'
                        + '<th>License Allocated To</th>'
                        + '<th>Profile: Name</th>'
                        + '<th>Role: Name</th>'
                        + '<th>Allowed Usage</th>'
                        + '<th>Actual License Usage</th>'
                        + '<th>Nature of License</th></tr>';
    
    public void execute(SchedulableContext sc){ 
        countUserLicenses();
    }
    
    public void countUserLicenses(){
        Map<String, LicenceAllocationWrapper> forcecomLicAggrCountByAllocation= new Map<String, LicenceAllocationWrapper>();
        Map<String, LicenceAllocationWrapper> salesforceLicAggrCountByAllocation= new Map<String, LicenceAllocationWrapper>();
        
        String salesforceLicense = 'Salesforce';
        String forcecomAppSubscriptionLicense = 'Force.com - App Subscription';
        
        try{
            List<AggregateResult> aggrLicenseCountForcecom = [Select count(Id) actualCount, License_Allocated_To__c, Profile.Name profilename,UserRole.Name rolename from User where Profile.UserLicense.Name = :forcecomAppSubscriptionLicense and IsActive=true group by License_Allocated_To__c,Profile.Name,UserRole.Name];
            for(AggregateResult ar : aggrLicenseCountForcecom){
                String sLicenceAllocatedTo = (String)ar.get('License_Allocated_To__c');
                if(forcecomLicAggrCountByAllocation.containsKey(sLicenceAllocatedTo)){
                    forcecomLicAggrCountByAllocation.get(sLicenceAllocatedTo).aggrResult.add(ar);
                }else{
                    forcecomLicAggrCountByAllocation.put(sLicenceAllocatedTo, new LicenceAllocationWrapper(new List<AggregateResult>{ar}));
                }
            }
            System.debug(forcecomLicAggrCountByAllocation);

            List<AggregateResult> aggrLicenceCountSalesforce = [Select count(Id) actualCount, License_Allocated_To__c, Profile.Name profilename,UserRole.Name rolename from User where Profile.UserLicense.Name = :salesforceLicense and IsActive=true group by License_Allocated_To__c,Profile.Name,UserRole.Name];
            for(AggregateResult ar : aggrLicenceCountSalesforce){
                String sLicenceAllocatedTo = (String)ar.get('License_Allocated_To__c');
                if(salesforceLicAggrCountByAllocation.containsKey(sLicenceAllocatedTo)){
                    salesforceLicAggrCountByAllocation.get(sLicenceAllocatedTo).aggrResult.add(ar);
                }else{
                    salesforceLicAggrCountByAllocation.put(sLicenceAllocatedTo, new LicenceAllocationWrapper(new List<AggregateResult>{ar}));
                }
            }        
            
            //Compute Sum of licences by allocated agency
            calculateTotal(forcecomLicAggrCountByAllocation);
            calculateTotal(salesforceLicAggrCountByAllocation);

            List<Agency_Specific_License_limits__c> maxAllowedAgencyLicensesList = Agency_Specific_License_limits__c.getall().values();
            Map <String, Integer> maxForceComAllowedLicensesByAgency = new Map <String, Integer>();
            Map <String, Integer> maxSalesforceAllowedLicensesByAgency = new Map <String, Integer>();
            
            for(Agency_Specific_License_limits__c maxAllowedAgencyLicensesItem : maxAllowedAgencyLicensesList){
                maxForceComAllowedLicensesByAgency.put(maxAllowedAgencyLicensesItem.name, Integer.valueOf(maxAllowedAgencyLicensesItem.Max_Force_com_Licenses_Allowed__c));
                maxSalesforceAllowedLicensesByAgency.put(maxAllowedAgencyLicensesItem.name, Integer.valueOf(maxAllowedAgencyLicensesItem.Max_Service_Cloud_Licenses_Allowed__c));
            }
            
            
            if(!emailBody.contains('</html>')){
                
                for(String sLicenceAllocatedTo: forcecomLicAggrCountByAllocation.keySet()){
                    if(maxForceComAllowedLicensesByAgency.containsKey(sLicenceAllocatedTo)){
                        LicenceAllocationWrapper laWrap = forcecomLicAggrCountByAllocation.get(sLicenceAllocatedTo);
                        if (laWrap.iLicenceCount > maxForceComAllowedLicensesByAgency.get(sLicenceAllocatedTo)){
                            for(AggregateResult agr : laWrap.aggrResult){
                                String roleName = String.valueOf(agr.get('rolename')) != null ? String.valueOf(agr.get('rolename')) : '';
                                emailBody += '<tr><td>' + sLicenceAllocatedTo + '</td><td>' 
                                            + String.valueOf(agr.get('profilename')) + '</td><td>'
                                            + roleName +'</td><td>' 
                                            + '</td><td>' + String.valueOf(agr.get('actualCount')) + '</td><td></td></tr>';
                            }
                            emailBody += '<tr style="font-weight:bold;background-color: lightgreen;"><td></td><td></td><td>Summary for - '+ sLicenceAllocatedTo +'</td><td>' 
                                            + maxForceComAllowedLicensesByAgency.get(sLicenceAllocatedTo) + '</td><td>' 
                                            + laWrap.iLicenceCount + '</td><td>' + forcecomAppSubscriptionLicense +'</td></tr>';
                        }
                    }
                }        
                
                for(String sLicenceAllocatedTo: salesforceLicAggrCountByAllocation.keySet()){
                    if(maxSalesforceAllowedLicensesByAgency.containsKey(sLicenceAllocatedTo)){
                        LicenceAllocationWrapper laWrap = salesforceLicAggrCountByAllocation.get(sLicenceAllocatedTo);
                        if (laWrap.iLicenceCount > maxSalesforceAllowedLicensesByAgency.get(sLicenceAllocatedTo)){
                            for(AggregateResult agr : laWrap.aggrResult){
                                String roleName = String.valueOf(agr.get('rolename')) != null ? String.valueOf(agr.get('rolename')) : '';
                                emailBody += '<tr><td>' + sLicenceAllocatedTo + '</td><td>' 
                                            + String.valueOf(agr.get('profilename')) + '</td><td>'
                                            + roleName +'</td><td>' 
                                            + '</td><td>' + String.valueOf(agr.get('actualCount')) + '</td><td></td></tr>';
                            }
                            emailBody += '<tr style="font-weight:bold;background-color: lightgreen;"><td></td><td></td><td>Summary for - '+ sLicenceAllocatedTo +'</td><td>' 
                                            + maxSalesforceAllowedLicensesByAgency.get(sLicenceAllocatedTo) + '</td><td>' 
                                            + laWrap.iLicenceCount + '</td><td>Salesforce Service Cloud</td></tr>';
                        }
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

    private void calculateTotal(Map<String, LicenceAllocationWrapper> pAggrCountByAllocation){

            for(LicenceAllocationWrapper lw : pAggrCountByAllocation.values()){
                Integer total = 0;
                for(AggregateResult agr : lw.aggrResult){
                    total += Integer.valueOf(agr.get('actualCount'));
                }
                lw.iLicenceCount = total;
            }
    }

    private class LicenceAllocationWrapper {
        public Integer iLicenceCount {get; set;}
        public List<AggregateResult> aggrResult{get;set;}
        
        LicenceAllocationWrapper(List<AggregateResult> pAggrResult){
            this.aggrResult = pAggrResult;
        }
    }
}

/*
NotifyForLicenseOveruse nlo = new NotifyForLicenseOveruse();
nlo.countUserLicenses();
*/