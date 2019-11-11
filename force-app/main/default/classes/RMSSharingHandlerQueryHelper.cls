public class RMSSharingHandlerQueryHelper {
    
    public static Id rmsRoleAndSubordinateId;
    public static Set<Id> rmsUserIds;
    
    public static Id getRMSRoleAndSubordinateId() {
        if(rmsRoleAndSubordinateId != null) {
            return rmsRoleAndSubordinateId;
        }
        List<Group> rmsGroups = [SELECT Name, DeveloperName, Id, type, Relatedid 
                   FROM Group 
                   WHERE Type ='RoleAndSubordinates' 
                  Or (Type = 'Role' AND DeveloperName = 'RMS')];

        System.debug('rmsGroups : '+rmsGroups);
        Group rms_group;
        List<Group> lgList = new List<Group>();
        for(Group g : rmsGroups){
            if (g.Type == 'Role' && g.DeveloperName == 'RMS'){
                rms_group = g;
            } else {
                lgList.add(g);
            }
        }            
        List<Group> rmsRole = new List<Group>();
        for(Group g : lgList){ 
            if (g.RelatedId == rms_group.RelatedId ){
                rmsRole.add(g);
            }
        }
        rmsRoleAndSubordinateId = rmsRole.get(0).Id;
        return rmsRoleAndSubordinateId;
    }
    
    public static Set<Id> getRMSUserIds() {
        if(rmsUserIds != null) {
            return rmsUserIds;
        }
        rmsUserIds = new Set<Id>();
        for(User user : [SELECT Id FROM User 
                        WHERE Agency__c =: GlobalConstants.RMS_AGENCY]) {
            rmsUserIds.add(user.Id);
        }
        return rmsUserIds;
    }
}