public with sharing class EmailPublisherAction_CX {

    public String orgWideEmail {get; set;}
    public String emailVsDisplayName {get; set;}
    boolean isFlipUserAddress = false;
    
    public static List <Id> metroRoles;
    static {
        metroRoles = new List <Id>();
        for(UserRole role : [Select Id, DeveloperName From UserRole Where DeveloperName like 'Syd_Metro%']){
            metroRoles.add(role.Id);
        }
    }    
    
    
    public EmailPublisherAction_CX(ApexPages.StandardController controller) {
        Map<String, String> emailVsDisplayNameMap = new Map<String, String>();
        orgWideEmail = '';
        map <String,String> emailAddressVsEmailName = new map<String,String>();
        for(OrgWideEmailAddress oWEmailAddress : [Select Id,Address, DisplayName From OrgWideEmailAddress limit 1000]) {
            emailAddressVsEmailName.put(oWEmailAddress.Address, String.escapeSingleQuotes(oWEmailAddress.DisplayName));
        }
        System.debug('--------emailAddressVsEmailName-------' + emailAddressVsEmailName);        
        map <String,ProfileVsOrgWideEmailAddMappings__c> profileVsEmailAddresses = ProfileVsOrgWideEmailAddMappings__c.getAll();
        Profile CurrentUserProfile = [Select Id, Name from Profile Where Id =: UserInfo.getProfileId()];
        if(profileVsEmailAddresses.containsKey(CurrentUserProfile.Name)){
            ProfileVsOrgWideEmailAddMappings__c settings = profileVsEmailAddresses.get(CurrentUserProfile.Name);
            System.debug('------Emails Settings----' + settings.OrgWideEmailAddresses__c);
            

            System.debug('settings.name: ' + settings.name);
            /*
            if(! (('CRGS Admin').equalsIgnoreCase(settings.name) || ('GIS Admin').equalsIgnoreCase(settings.name) || ('HCF Case Manager').equalsIgnoreCase(settings.name) || 
            ('MAGS Officer').equalsIgnoreCase(settings.name) ||('HCF Case Manager').equalsIgnoreCase(settings.name) || ('Maritime Case Manager').equalsIgnoreCase(settings.name) || 
            ('NotASystemAdmin').equalsIgnoreCase(settings.name) || ('NSW Trains Case Manager').equalsIgnoreCase(settings.name) || ('RMS Case Manager').equalsIgnoreCase(settings.name) || 
            ('HCF Case Manager').equalsIgnoreCase(settings.name) || ('RMS Corro Officer').equalsIgnoreCase(settings.name) || ('Senior Corro Officer').equalsIgnoreCase(settings.name) || 
            ('Senior MAGS Officer').equalsIgnoreCase(settings.name) || ('Senior Corro Officer').equalsIgnoreCase(settings.name) || ('STA Case Manager').equalsIgnoreCase(settings.name) || 
            ('SYD Trains Case Manager').equalsIgnoreCase(settings.name) || ('SYD Trains ViewAll').equalsIgnoreCase(settings.name) || ('System Administrator').equalsIgnoreCase(settings.name) || 
            ('TfNSW Case Manager').equalsIgnoreCase(settings.name) || ('TfNSW MAGS Officer').equalsIgnoreCase(settings.name) || ('TMC Case Manager').equalsIgnoreCase(settings.name) || 
            ('Transport Project GM').equalsIgnoreCase(settings.name) ))
            isFlipUserAddress = true;
            */

            
            if(settings.OrgWideEmailAddresses__c != null && settings.OrgWideEmailAddresses__c != '') {
                //Multiple email address check
                if(settings.OrgWideEmailAddresses__c.contains(',')) {
                    list <String> emails = settings.OrgWideEmailAddresses__c.split(',');
                    if(emails != null && emails.size() > 0){
                        for(String email : emails) {
                            orgWideEmail += email + ',';
                            if(emailAddressVsEmailName.containskey(email)) {
                                emailVsDisplayNameMap.put(email, emailAddressVsEmailName.get(email));
                            }
                        }
                        System.debug('------Emails Available----' + orgWideEmail);
                    }
                } else {
                    //Single email address is allowed
                    if(!metroRoles.contains(UserInfo.getUserRoleId()))
                    	orgWideEmail += settings.OrgWideEmailAddresses__c + ',';
                    else orgWideEmail += settings.OrgWideEmailAddresses__c;
                    
                    if(emailAddressVsEmailName.containskey(settings.OrgWideEmailAddresses__c)) {
                        emailVsDisplayNameMap.put(settings.OrgWideEmailAddresses__c, emailAddressVsEmailName.get(settings.OrgWideEmailAddresses__c));
                    }
                }
            }
        }
        
        /*
        if(isFlipUserAddress){
             orgWideEmail = UserInfo.getUserEmail() + ',' + orgWideEmail.substring(0,orgWideEmail.lastIndexOf(','));
        }
        else
		*/

        if(!metroRoles.contains(UserInfo.getUserRoleId()))
        	orgWideEmail += UserInfo.getUserEmail() ;
        
        emailVsDisplayNameMap.put(UserInfo.getUserEmail(), UserInfo.getName());
        emailVsDisplayName = JSON.serialize(emailVsDisplayNameMap);
    }
}