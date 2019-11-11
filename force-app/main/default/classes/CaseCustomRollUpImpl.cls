/*------------------------------------------------------------
Author:        Manish Damle
Company:       Arxxus.com
Description:   Helper class which will calculate the No of child cases 
               for a particular case and updates the Child Case Count Field on Case

Test Class:    CaseCustomRollUpImpl_Test
History
06/05/2015     Manish Damle       Created
12/09/2017     Ian F              Added check for null parentIds - code was selecting all cases with null parentId (over 350k)
                                  which threw an exception for >50k limit
------------------------------------------------------------*/
public without sharing class CaseCustomRollUpImpl {
    public static Boolean counterUpdated = false;
    
    public void calculateRollUp(map <Id, Case> newMap, map <Id, Case> oldMap) {  
        if(counterUpdated && !Test.isRunningTest()) {
            return;
        }
        set <Id> parentCaseIds = new set <Id> ();
        list <Case> casesToBeUpdated = new list <Case> ();
        
        for(Id key : newMap.keySet()) {
            if(newMap.get(key).ParentId != null)     {
                parentCaseIds.add(newMap.get(key).ParentId);
            }
        }
        
        if(oldMap != null) {
            for(Id key : newMap.keySet()) {
                if(oldMap.get(key).ParentId!=null && newMap.get(key).ParentId!=oldMap.get(key).ParentId) {
                    //Case reparented
                    parentCaseIds.add(oldMap.get(key).ParentId);
                }
            }
        }
        
        if (parentCaseIds.size()==0) return;
        
        Map<Id, Integer> parentVsChildCount = new Map<Id, Integer>();
        for(AggregateResult agResult : [Select COUNT(ID) CHILD_CASE, ParentId PARENT 
                                        From Case 
                                        Where ParentId IN : parentCaseIds 
                                        Group By ParentId] ) {
            parentVsChildCount.put((Id)agResult.get('PARENT'), Integer.valueOf(agResult.get('CHILD_CASE')));
        }
        for(Case caseRecord : [Select Id, Child_Cases_Count__c From Case Where Id In: parentCaseIds]) {
            caseRecord.Child_Cases_Count__c = parentVsChildCount.containsKey(caseRecord.Id) ? parentVsChildCount.get(caseRecord.Id) : 0;
            casesToBeUpdated.add(caseRecord);
        }
        
        List<Database.SaveResult> updateResults = database.update(casesToBeUpdated, false);
        counterUpdated = true;
        for(Database.SaveResult sr: updateResults) {
            if(!sr.isSuccess()) {
                counterUpdated = false;
            }
        }
    }
}