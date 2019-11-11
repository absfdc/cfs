/*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   Utility class for picking up the Case records from the various queues.
                   This class can be used for other objects as well.
                   (Note: WS -> Web Service) 
    TestClass:     RetrieveNextUtils_WS_Test                   
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    14/05/2015     Brett Cawrse       Added setting IsGetNext to support anti-Cherry Picking
    21/03/2017     Arxxus             Optimised getAllSubRoleIds method to reduce soql query usage
    -----------------------------------------------------------------------------------*/
global with sharing class RetrieveNextUtils_WS {
    private static map <Id, Group> grMap;
    private static set <Id> queues;
    
    //map that will store all the child role ids for a parent role id
    private static Map<Id, Set<Id>> parentAndChildRoles;
    
    static  {
        
        parentAndChildRoles = new Map<Id, Set<Id>>();
        
        queues = new set <Id>();
        grMap = new map <Id,Group> ([Select Id,DeveloperName, Type, RelatedId From Group limit 10000]);
        for(Group g : grMap.values()) {
            if(g.Type == 'Queue') {
                queues.add(g.Id);
            }
        }
        
        //preparing map containing parent role id vs set of child roles ids 
        //which can be used further recursively in getAllSubRoleIds method
        Set<Id> childRoleIds = new Set<Id>();
        for(UserRole ur : [Select Id, ParentRoleId 
                           FROM UserRole
                           WHERE ParentRoleId != NULL
                           LIMIT 40000]) {
        
         childRoleIds = parentAndChildRoles.containsKey(ur.ParentRoleId) ? parentAndChildRoles.get(ur.ParentRoleId) : new Set<Id>();
         childRoleIds.add(ur.Id);
         parentAndChildRoles.put(ur.ParentRoleId, childRoleIds);
        }
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will find out all the cases present in queues of which the 
                   user is member of. Single case record will be picked from the queue based
                   on following criteria.
                   1. Priority (High > Medium)
                   2. Oldest case in queue. (Created Date will be used) 
                   
                   Priority | Priority Number
                   ---------------------------
                   High     | 1
                   ---------------------------
                   Normal   | 2
                   ---------------------------
    Inputs:        User Id
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    09/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
     webservice static String retrieveNextCase(String userId) {
        if (userId == '' || userId == null) {
            //If user id param is blank or not sent then use current user's Id.
            userId = UserInfo.getUserId();
        }

        User userRecord = [Select Id, Name, UserRoleId From User Where Id =: userId limit 1];
        //First find out which queues this user is a member of
        set <Id> groupIds = getGroupsForUser(queues, userRecord, null);
        system.debug('----Group Ids Found----' + groupIds);
        if(groupIds.size() > 0 ) {
            //Find an open case that is assigned to one of those queues
            //Order By clause is used because query will first pick the records based on 
            //Priority in asceding order and then filter the records based on Created Date
            //This will give us single oldest case record with high priority.
            List<String> closedCaseStatuses = new List<String>();
            closedCaseStatuses.add(GlobalConstants.CASE_CLOSED_STATUS);
            closedCaseStatuses.add(GlobalConstants.CASE_SOFTCLOSED_STATUS_STA);
            closedCaseStatuses.add(GlobalConstants.CASE_SOFTCLOSED_STATUS);
            
            List<String> trainsAgency = new List<String>();
            trainsAgency.add(GlobalConstants.AGENCY_SYDNEY_TRAINS);
            trainsAgency.add(GlobalConstants.AGENCY_NSW_TRAINS);
            list <Case> cases = [Select Id, OwnerId ,(select Id,OwnerId from Cases where OwnerId In: groupIds ), Parent.Id, Parent.OwnerId
                                From Case
                                Where (OwnerId In: groupIds AND Status NOT IN :closedCaseStatuses) 
                                    OR (OwnerId In: groupIds AND Status IN :closedCaseStatuses AND OwnerAgency__c NOT IN :trainsAgency)
                                Order By Priority_In_Numbers__c ASC, CreatedDate ASC limit 1];
            system.debug('----Cases----' + cases);                                                
            if (cases.size() == 1) {        
                //If we found one, assign it to the current user
                List<Case> casesForUpdate= new List<Case>();
                 
                Case caseObj = cases[0];
                caseObj.OwnerId = userId;
                caseObj.IsGetNext__c = true;
                casesForUpdate.add(caseObj);
                Database.SaveResult result;
                Database.SaveResult[] results = Database.update(casesForUpdate,false);
                for (Database.SaveResult sr:results){
                    System.debug('Save result details: ' + sr);
                    if(sr.getId()==caseObj.Id) result=sr;
                }
                system.debug('----Case Updated----' + result);
                if(result != null && result.isSuccess()) {
                    return caseObj.Id;
                } else {
                    String error = 'Error: ';
                    for(Database.SaveResult sr : results) {                    
                        for(Database.Error err : sr.getErrors()) {
                            error += err.getMessage();
                        }
                    }
                    return error;
                }
                    
            } else {
                return 'No cases are available at this time.';
            }
        } else {
            return 'You are not a member of any queue or public group. Please contact administrator.';
        }
        return null;
    }
      
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This method will fetch all the Queues for which this user is a member.
    Inputs:        set of queue ids, user id, map of Public Group Id and Queue id 
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    13/04/2015     Manish Damle       Created
    -----------------------------------------------------------------------------------*/
    @testVisible
    public static set <Id> getGroupsForUser(set <Id> groups, User userRecord, map <Id, Id> groupIdVsPublicGroupIds) {
        //final list of all the groups of which user is member
        system.debug('---------groupIdVsPublicGroupIds-----------' + groupIdVsPublicGroupIds);
        set <Id> groupIds = new set <Id>();
        set <Id> publicGroupIds = new set<Id>();
        //Object prefixes
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        String roleType = Schema.SObjectType.UserRole.getKeyPrefix();
        map <Id, Id> publicGroupVsParentGroupId = new map <Id, Id>();
        map <Id, set <Id>> groupVsRoleIds = new map <Id,set <Id>>();
        map <Id, set <Id>> groupVsRoleAndSubordinatesIds = new map <Id,set <Id>>();
        
        for(GroupMember m : [Select Id, UserOrGroupId, GroupId, Group.type From GroupMember Where GroupId IN: groups]) {
            System.debug('----Group Member----' + m);
            //Check whether the User is active user or not. It should be direct member of the Queue
            if(((String) m.UserOrGroupId).startsWith(userType) && m.UserOrGroupId == userRecord.Id) {
                system.debug('----Direct Member----' + m.UserOrGroupId + ' = ' +  userRecord.Id); 
                if(m.Group.type  == 'Queue') {
                    groupIds.add(m.GroupId);
                } if(groupIdVsPublicGroupIds != null 
                     && m.Group.type  == 'Regular' 
                        && groupIdVsPublicGroupIds.containsKey(m.GroupId) 
                            && groupIdVsPublicGroupIds.get(m.GroupId) != null) {
                                
                    groupIds.add(groupIdVsPublicGroupIds.get(m.GroupId));
                    system.debug('----Regular----' + m.UserOrGroupId + ' = ' + groupIdVsPublicGroupIds.get(m.GroupId)); 
                }
            } else if(grMap.get(m.UserOrGroupId) != null 
                      && (grMap.get(m.UserOrGroupId).RelatedId != null && ((String) grMap.get(m.UserOrGroupId).RelatedId).startsWith(roleType)) ) {
                          system.debug('----Group Type----' + grMap.get(m.UserOrGroupId).type); 
                          if(grMap.get(m.UserOrGroupId).type == 'Role') { //Group member is Role
                              if(groupVsRoleIds.containsKey(m.GroupId)) {
                                  groupVsRoleIds.get(m.GroupId).add(grMap.get(m.UserOrGroupId).RelatedId);
                              } else {
                                  groupVsRoleIds.put(m.GroupId, new set <Id> {grMap.get(m.UserOrGroupId).RelatedId});
                              }
                          } else if(grMap.get(m.UserOrGroupId).type == 'RoleAndSubordinates') { //Group member is Role And Subordinates
                              if(groupVsRoleAndSubordinatesIds.containsKey(m.GroupId)) {
                                  groupVsRoleAndSubordinatesIds.get(m.GroupId).add(grMap.get(m.UserOrGroupId).RelatedId);
                              } else {
                                  set <Id> RoleAndSubordinatesIds = new set <Id>();
                                  roleAndSubordinatesIds.add(grMap.get(m.UserOrGroupId).RelatedId);
                                  roleAndSubordinatesIds.addAll(getAllSubRoleIds(roleAndSubordinatesIds));
                                  groupVsRoleAndSubordinatesIds.put(m.GroupId, roleAndSubordinatesIds);
                              }
                          }
                          
           } else if(((String)m.UserOrGroupId).startsWith(groupType)) {
               //Group has another group as a member.
               publicGroupVsParentGroupId.put(m.UserOrGroupId, m.GroupId); //Create a map of Public Group and its parent queue
               publicGroupIds.add(m.UserOrGroupId);
           }
        }//end for
        
        system.debug('---Group With Role---------------------' + groupVsRoleIds);
        system.debug('---Group With Roles And Subordinates---' + groupVsRoleAndSubordinatesIds);
        system.debug('---Public Group Vs Parent Group IdS---' + groupIdVsPublicGroupIds);
        
        if(groupVsRoleIds.size() > 0) {
            for(Id groupId : groupVsRoleIds.keySet()) {
                if(groupVsRoleIds.get(groupId) == null) 
                    continue;
                for(Id roleId : groupVsRoleIds.get(groupId)) {
                    if(roleId == userRecord.UserRoleId)  {
                        if(groupIdVsPublicGroupIds != null && groupIdVsPublicGroupIds.containsKey(groupId)) {
                            system.debug('---Public Group Found Role-' + groupId  + '---'+ groupIdVsPublicGroupIds.get(groupId) );
                            groupIds.add(groupIdVsPublicGroupIds.get(groupId));
                        } else {
                            groupIds.add(groupId);
                        } 
                        break;
                    }
                }
            }
        }  
        
        if(groupVsRoleAndSubordinatesIds.size()>0) {
            system.debug('---groupVsRoleAndSubordinatesIds-');
            for(Id groupId : groupVsRoleAndSubordinatesIds.keySet()) {
                if(groupVsRoleAndSubordinatesIds.get(groupId) == null) 
                    continue;
                for(Id roleId : groupVsRoleAndSubordinatesIds.get(groupId)) {
                    system.debug('---roleId-' + roleId + '--' + userRecord.UserRoleId);
                    if(roleId == userRecord.UserRoleId)  {
                        if(groupIdVsPublicGroupIds != null && groupIdVsPublicGroupIds.containsKey(groupId)) {
                            system.debug('---Public Group Found-' + groupIdVsPublicGroupIds.get(groupId) );
                            groupIds.add(groupIdVsPublicGroupIds.get(groupId));
                        } else {
                            groupIds.add(groupId);
                        } 
                        break;
                    }
                }
            }
        }
        
        if(publicGroupIds.size() > 0) {
            system.debug('----publicGroupIds----' + publicGroupVsParentGroupId); 
            groupIds.addAll(getGroupsForUser(publicGroupIds, userRecord, publicGroupVsParentGroupId));
        }
        
        return groupIds;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Manish Damle
    Company:       Arxxus.com
    Description:   This is recursive function to fecth the role ids
    Inputs:        User Id
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    13/04/2015     Manish Damle       Created
    21/03/2017     Arxxus             Optimised method to reduce soql query usage.
                                      Previous code in commented state for reference purpose.
    -----------------------------------------------------------------------------------*/
    private static Set<Id> getAllSubRoleIds(Set<Id> roleIds) {
        
        Set<Id> currentRoleIds = new Set<Id>();
        
        System.debug('Input roleIds: '+roleIds);
        
        for(Id tempRoleId : roleIds) {
         
         if(parentAndChildRoles.containsKey(tempRoleId))
          currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
        
        if(currentRoleIds.size() > 0)
         currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        
        return currentRoleIds;
        
        /*
        set<Id> currentRoleIds = new set<Id>();
        
        //Get all of the roles underneath the passed roles
        for(UserRole userRole :[Select Id 
                                From UserRole 
                                Where ParentRoleId IN :roleIds 
                                And ParentRoleID != null limit 40000]) {
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0)
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        
        return currentRoleIds;
        */
    }
}