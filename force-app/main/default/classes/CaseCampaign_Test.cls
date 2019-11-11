@isTest
    private class CaseCampaign_Test {
       
        @testSetup
        static void setup() {
            list <CaseRecordTypesToExcludeFromRtFlip__c> cs = new list <CaseRecordTypesToExcludeFromRtFlip__c>();
            cs.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name = 'Campaign', Record_Type_Name__c = 'Campaign'));
            cs.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name = 'Campaign Member', Record_Type_Name__c = 'Campaign Member'));
            cs.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name = 'General Ministerial Correspondence', Record_Type_Name__c = 'General Ministerial Correspondence'));
            cs.add(new CaseRecordTypesToExcludeFromRtFlip__c(Name = 'RMS CE Signatory', Record_Type_Name__c = 'RMS CE Signatory'));
            insert cs;
            
            map<String,Id> recordTypes = new map<String,Id>();
            for(RecordType rt : [Select Id, DeveloperName 
                                 From RecordType 
                                 Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN 
                                    Or DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER]) {
                recordTypes.put(rt.DeveloperName, rt.Id);
            }   
            
            Case campaign = getCaseRecord();
            campaign.Subject = 'CAMPAIGN';
            campaign.Taxonomy_Moment__c = 'A';
            campaign.Taxonomy_Transaction__c = 'B';
            campaign.Taxonomy_Location_Type__c = 'C';
            campaign.Taxonomy_Symptom__c = 'D';
            campaign.RecordTypeId = recordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN);
            insert campaign;
            Test.startTest(); 
            Case campaignMember1 = getCaseRecord();
            campaignMember1.Subject = 'CAMPAIGN MEMBER';
            campaignMember1.RecordTypeId = recordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER);
            campaignMember1.ParentId = campaign.Id;
            insert new list <Case> {campaignMember1};
                Test.stopTest();
        }
        
        @isTest
        static void campaignCanNotBeClosedIfItHasOpenCampaignMembersTest2() {
            //ProcessEmailsWithScannedDocuments_Test.createPrefixSuffixConfigurationCustomSetting('Scanned email |||', '|||'); 
            map<String,Id> recordTypes = new map<String,Id>();
            for(RecordType rt : [Select Id, DeveloperName 
                                 From RecordType 
                                 Where DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN 
                                    Or DeveloperName =: GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER]) {
                recordTypes.put(rt.DeveloperName, rt.Id);
            }
            
            Case campaign = getCaseRecord();
            campaign.RecordTypeId = recordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGN);
            insert campaign;
            system.debug('----------campaign---------' + campaign);
            
            Case campaignMember1 = getCaseRecord();
            campaignMember1.ParentId = campaign.Id;
            campaignMember1.RecordTypeId = recordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER);
            Case campaignMember2 = getCaseRecord();
            campaignMember2.ParentId = campaign.Id;
            campaignMember2.RecordTypeId = recordTypes.get(GlobalConstants.CASE_RECORD_TYPE_CAMPAIGNMEMBER);
            
            insert new list<case> { campaignMember2,campaignMember1};
            Test.startTest();
            list <Case> cases = [Select Id From Case Where ParentId =: campaign.Id];
            system.assertEquals(2, cases.size());
            campaign.Status = GlobalConstants.CASE_CLOSED_STATUS_MIN_CORRO;
            Database.SaveResult result = Database.update(campaign,false);
            system.debug('----------result---------' + result);
            system.assertEquals(false, result.isSuccess());
            Test.stopTest();
        }
        
        @isTest
        static void copyCampaignDetailsToCampaignMember() {
            Case CampaignCase = [Select Id, ParentId From Case Where Subject = 'CAMPAIGN' limit 1];
            Case CampaignMemberCase = [Select Id, RecordTypeId, ParentId From Case Where Subject = 'CAMPAIGN MEMBER' limit 1];
            //System.assertEquals(null, CampaignMemberCase.ParentId);
            Test.startTest();
                CampaignMemberCase.ParentId = CampaignCase.Id;
                update CampaignMemberCase;
                Case c= [Select Id,Taxonomy_Moment__c,Taxonomy_Location_Type__c, ParentId From Case Where Subject = 'CAMPAIGN MEMBER' limit 1];
               // system.assertEquals('A', c.Taxonomy_Moment__c);
               // system.assertEquals('C', c.Taxonomy_Location_Type__c);
            Test.stopTest();
        }
        
        private static Case getCaseRecord() {
            return new Case(Status = 'Registered',
                            Subject = 'Campaign Testing',
                            Description = 'Campaign Testing Description'
                           );
        }
            
    }