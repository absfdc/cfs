//JIRA SFCOE-880 Synchronize the Issue and Location Taxonomy Fields for PBO Cases - 20-06

@isTest
public class CasePBOTaxonomyFieldsSyncTest {
    
    static testmethod void  testCase(){    
        
            Taxonomy_metadata__c bus = new Taxonomy_metadata__c(name='Bus',type__c='Mode');
            insert bus;
            Taxonomy_metadata__c planningtheTrip = new Taxonomy_metadata__c(name='Planning the Trip',type__c='Issue', Parent_Id__c=bus.Id,
                                                                            Customer_Value__c = 'Planning the Trip', Status_Staff_Facing__c = 'Active');
            insert planningtheTrip;
            Taxonomy_metadata__c timetable = new Taxonomy_metadata__c(name='Timetable',type__c='Issue', Parent_Id__c=planningtheTrip.Id,
                                                                      Customer_Value__c = 'Timetable', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert timetable;
            Taxonomy_metadata__c wrongInfo = new Taxonomy_metadata__c(name='Wrong Information',type__c='Issue', Parent_Id__c=timetable.Id,
                                                                      Customer_Value__c = 'Wrong Information', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert wrongInfo;
            Taxonomy_metadata__c availability = new Taxonomy_metadata__c(name='Availability',type__c='Issue', Parent_Id__c=timetable.Id,
                                                                      Customer_Value__c = 'Availability', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert availability;
        
        
        
        
            
            Taxonomy_metadata__c theBusJemalit = new Taxonomy_metadata__c(name='Jemalit',type__c='Location', Parent_Id__c=bus.Id,
                                                                          Customer_Value__c = 'Jemalit', Status_Staff_Facing__c = 'Active');
            insert theBusJemalit;
            Taxonomy_metadata__c transportOfficersOrange = new Taxonomy_metadata__c(name='Orange',type__c='Location', Parent_Id__c=theBusJemalit.Id,
                                                                                    Customer_Value__c = 'Orange', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert transportOfficersOrange;
            Taxonomy_metadata__c appearanceUnspecifiedRoute = new Taxonomy_metadata__c(name='Unspecified Route',type__c='Location', Parent_Id__c=transportOfficersOrange.Id,
                                                                                       Customer_Value__c = 'Unspecified Route', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert appearanceUnspecifiedRoute;
            
            Taxonomy_metadata__c appearanceSchoolSpecials = new Taxonomy_metadata__c(name='School Specials',type__c='Location', Parent_Id__c=transportOfficersOrange.Id,
                                                                                     Customer_Value__c = 'School Specials', Status_Staff_Facing__c = 'Active', Status_Customer_Facing__c = 'Active');
            insert appearanceSchoolSpecials;
            
            RecordType rt = [Select Id From RecordType where name = 'Bus'];//Private Operators
            
            Case c = new Case(Subject = 'Bus',
                              Description = 'bus service is just so...',
                              Status = 'New',
                              RecordTypeId = rt.Id,
                              Priority = 'Normal',
                              Modes__c = 'Bus', 
                              Issue_Level_1__c = 'Planning the Trip',
                              Issue_Level_2__c = 'Timetable',
                              Issue_Level_3__c = 'Wrong Information',
                              Taxonomy_Location_Type__c = 'Jemalit',
                              Taxonomy_Area__c = 'Orange',
                              Taxonomy_Location__c = 'School Specials'
                             );
            //c.Unsubstantiated__c = Case.Unsubstantiated__c.getDescribe().getPicklistValues()[0].getValue(),
            insert c;
            System.debug('*******New Case ID: '+c.id);
            Test.startTest();
            RecordType rtpo = [Select Id From RecordType where name = 'Private Operators'];
            c.RecordTypeId = rtpo.id;
            c.Issue_Level_3__c = 'Availability';
            c.Taxonomy_Location__c = 'Unspecified Route';
            update c;
            System.debug('*******Just Issue updated from Portal: '+c.id);   
        	Test.stopTest();
    }
    
}