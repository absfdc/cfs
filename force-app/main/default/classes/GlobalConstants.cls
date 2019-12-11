/*------------------------------------------------------------
Author:        B. Cawrse
Company:       Salesforce
Description:   A global constants class for the project
Test Class:
History
<Date>        <Authors Name>     <Brief Description of Change>
25-MAR-2015   B. Cawrse          Created. Holds constants which are referenced across classes
10/03/2017    Arxxus             Updated. New constants related to MO integration added.
14/06/2017    Arxxus             added new constant for 'Newcastle Transport' agency- NEWCASTLE_TRANSPORT_AGENCY
06/07/2017    Arxxus             Updated. New constants related to Private Operator added.
25/08/2017    Arxxus             Updated. New constants for MO Enhancements added.
25/09/2017    Arxxus             Oct Release: added new constants for combined pdf. Removed variable for send for printing
19/11/2019    Abhi I             Transit Systems: added new constants Transit Systems agency
-------------------------------------------------------------*/

global with sharing class GlobalConstants {
 
    //********** B2C ACCOUNT CONSTANTS ******************
    public static final string SYSTEM_ADMINISTRATOR_PROFILE_NAME = 'System Administrator';
    public static final String B2C_ACCNT_RECTYPE_NAME = 'household'; //record type for the B2C Accounts created
    public static final String B2C_ACCNT_SUFFIX = ' Account'; //suffix added to contact name for B2C Accounts
    public static final String CUSTOMER_CONTACT_RECTYPE_NAME = 'Customer';//recordtype API name for contacts of type customer
    public static final String ADVICE_WAITING_TASK_STATUS= 'Waiting on someone else';//status text of new task, created on case wating for SME advice
    public static final String ADVICE_TASK_COMPLETED_STATUS='Completed';//advice task completion status text
    public static final String CASE_CLOSED_STATUS='Finalised';// closed case status text
    public static final String CASE_SOFTCLOSED_STATUS_STA='Closed with Customer';//STA request a status before soft close
    public static final String CASE_CLOSED_STATUS_MIN_CORRO='Completed';// closed case status text
    public static final String CASE_REOPENED_STATUS = 'Reopened';
    public static final String CASE_SIGNED_STATUS_MIN_CORRO='Signed';// closed case status text
    public static final String CASE_READY_FOR_PRINTING_STATUS_MIN_CORRO = 'Ready For Printing';  
    public static final String CASE_WAITING_APPROVAL_STATUS_MIN_CORRO = 'Awaiting Approval'; 
    public static final String CASE_NRR_STATUS_MIN_CORRO = 'Closed - NRR'; 
    public static final String ERRONEOUS_CASES_QUEUE_NAME_MIN_CORRO = 'ErroneousCases_MC';
    public static final String CASE_NOT_FOUND_STATUS_MIN_CORRO = 'Error - Case Not Found';
    public static final String ALLOCATION_STATUS_MIN_CORRO='Allocation';// Allocation case status text
    public static final String DRAFT_RESPONSE_STATUS_MIN_CORRO = 'Draft Response in progress';
    public static final String RESEARCH_STATUS_MIN_CORRO = 'Research';
    public static final String AWAITING_ADVICE_MIN_CORRO = 'Awaiting Advice';
    public static final String ON_HOLD_MIN_CORRO = 'On Hold';
    public static final String DRAFT_IN_PROGRESS_MIN_CORRO = 'Draft in Progress';
    public static final String CHILD_AP_RECORDTYPE_API_NAME = 'MCWS_Child_Action_Plan';
    public static final String PARENT_AP_NOTIFICATION_EMAIL_TEMPLATE = 'Child_Action_Plan_Status_Change_Notification';
    public static final String REJECTED_AP_NOTIFICATION_EMAIL_TEMPLATE = 'EmailToCOWhenIncorrectlyAssigned';
    public static final String CHILD_AP_STATUS_CHANGE_NOTIFICATION_EMAIL_TEMPLATE = 'EmailToPAPOwnerOnCAPStatusChanges';
    public static final String AP_SBMITTED_FOR_REVIEW_NOTIFICATION_EMAIL_TEMPLATE = 'EmailToCOWhenSMESubmitedAPForReview';
    public static final String NOREPLY_ORGWIDE_EMAIL = 'noreply email address';
    public static final String MO_AMEND_MIN_CORRO = 'MO Amend';
    
    public static final String CRGS_PROFILE_NAME ='CRGS Admin';
    public static final set <String> MAGS_PROFILE_NAMES = new set <String> {'TfNSW MAGS Officer', 'MAGS Officer', 'Senior MAGS Officer'};
    public static final set <String> MAGS_QUEUE_NAMES = new set <String> {'MCWS_Editor_Approval_Queue', 'MCWS_Manager_Approval_Queue', 'MCWS_Senior_MAGS_Approval_Queue'};
    public static final set <String> MAGS_ROLE_NAMES = new set <String> {'MAGS_Manager', 'Senior_MAGS_Officer', 'MAGS_Officer','MAGS_Editor'};
    public static final set <String> AP_DUE_DATE_CALCULATION_ALLOWED_ROLE_NAMES = new set <String> {'CRGS_Admin', 'MAGS_Manager', 'Senior_MAGS_Officer', 'MAGS_Officer','MAGS_Editor'};
    public static final set <String> CORRO_OFFICER_ROLE_NAMES = new set <String> {'Corro_Officer','RMS'};
    public static final map <String, String> MAGS_ROLE_NAMES_VS_DRAFT_STATUS = new map <String, String> {'Senior_MAGS_Officer' => 'Editor Review', 
                                                                                                         'MAGS_Officer' => 'Senior Review',
                                                                                                         'MAGS_Editor' => 'Manager Review'};
    public static final String MAGS_ROLE_EXECUTIVE_DIRECTOR_LABEL = 'Executive Director, Customer Relations & Government Services';
    public static final String MAGS_ROLE_EXECUTIVE_DIRECTOR = 'Executive_Director_CRGS';
    public static final String MAGS_ROLE_PRINCIPAL_MANAGER_LABEL = 'Principal MAGS Manager';
    public static final String MAGS_ROLE_PRINCIPAL_MANAGER = 'Principal_MAGS_Manager';
    public static final String MAGS_ROLE_MANAGER_LABEL = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    public static final String MAGS_ROLE_MANAGER = 'MAGS_Manager';
    public static final String MAGS_ROLE_SR_OFFICER_LABEL = 'Senior MAGS Officer';    
    public static final String MAGS_ROLE_SR_OFFICER = 'Senior_MAGS_Officer'; 
    public static final String MAGS_ROLE_OFFICER = 'MAGS_Officer'; 
    public static final String MAGS_ROLE_EDITOR = 'MAGS_Editor'; 
    public static final String MAGS_ROLE_EDITOR_LABEL = 'MAGS Editor';
    public static final String MAGS_ROLE_CRGS_ADMIN = 'CRGS_Admin';  
    public static final String MAGS_ROLE_CRGS_SUPER_ADMIN = 'CRGS_Super_Admin';  
    public static final String MAGS_OFFICER_QUEUE_API_NAME = 'Senior_MAGS_Officer_Queue_MC';
    public static final String RMS_CORRO_OFFICER_QUEUE_API_NAME = 'RMS_Corro_Officer_Queue';
    public static final String CASE_SOFTCLOSED_STATUS='Closed';//  Closed (soft close) state
    //origin of cloned case to denote, its been created because a customer emailed about a parent case that was closed long back
    public static final String CLONED_CASE_ORIGIN_CUSTOMER_COMMUNICATION='Closed Case';
    //status of cloned case created because a customer emailed about a parent case that was closed long back
    public static final String CLONED_CASE_STATUS_CUSTOMER_COMMUNICATION='New';
    public static final String REOPENED_CASE_STATUS_CUSTOMER_COMMUNICATION='Reopened';
    public static final String DEFAULT_WEBTOCASE_STATUS_TRIAGE = 'Triage';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String DEBUG ='Debug';//logging level
    public static final String ERROR ='Error';//logging level
    public static final String INFO ='Info';//logging level
    public static final String WARNING ='Warning';//logging level 
    public static final String SNSW_AGENCY = 'SNSW';
    public static final String STA_AGENCY = 'STA';
    public static final String AGENCY_SYDNEY_TRAINS='Sydney Trains';
    public static final String AGENCY_NSW_TRAINS='NSW Trains';
    public static final String TRANSIT_SYSTEMS_AGENCY = 'Transit Systems';
    
    public static final String NEWCASTLE_TRANSPORT_AGENCY = 'Newcastle Transport';

    public static final String JOB_COMPLETED ='COMPLETED';//job status completed
    public static final String JOB_ERROR ='ERROR';//job status errored
    public static final String JOB_DELETED ='DELETED';//job status deleted

    public static final String CASE_PRIORITY_HIGH ='High';//Case priority which is high
    public static final String MIN_CORRO_RECTYPE_NAME ='Ministerial_Correspondence';
    public static final String MIN_CORRO_RECTYPE_API_NAME ='General_Ministerial_Correspondence';
    public static final String MIN_CORR_RECORDTYPE_NAME = 'Ministerial Correspondence';
    public static final String WEB2CASE_ORIGIN ='Web';
    public static final String EZESCAN_EMAIL_CASE_ORIGIN ='Email';
    public static final String EZESCAN_CASE_ORIGIN ='Letter';
    public static final String CASE_ORIGIN_CFM_API ='CFM API';
    public static final String WEBTOCASE_DEFAULT_COUNTRY_AUS = 'Australia';

    public static final String TAXONOMY_STATUS_ACTIVE = 'Active';
    public static final String TAXONOMY_TYPE_CASE_CATEGORIZATION = 'Case Categorisation';
    public static final String TAXONOMY_TYPE_LOCATION = 'Location';
    public static final String TAXONOMY_TYPE_ISSUE = 'Issue';

    public static final String TAXONOMY_LEVEL_1_TRAIN = 'The Train';
    public static final String TAXONOMY_LEVEL_1_BUS = 'The Bus';
    public static final String TAXONOMY_LEVEL_1_FERRY = 'The Ferry';
    public static final String TAXONOMY_LEVEL_1_ROAD = 'Road';
    public static final String TAXONOMY_LEVEL_1_STATION = 'The Station';
    public static final String CASE_RECORD_TYPE_MULTI_ISSUE = 'Multi Issue';
    public static final String SUSPECTED_SPAM_CASE = 'SUSPECTED_SPAM_CASE';
    public static final String CASE_RECORD_TYPE_MULTI_ISSUE_DEV = 'Multi_Issue';
    public static final String RMS_AGENCY = 'RMS';
    public static final String SNSW_EMAIL_DOMAIN = '@service.nsw.gov.au';
    
    public static final String RMS_SOURCE_MARITIME = 'maritime';
    public static final String RMS_SOURCE_RMS = 'rms';
    public static final String RMS_SOURCE_RMS_INTRANET = 'rms intranet';
    public static final String RMS_PRIORITY_INDIVIDUAL_STANDARD= 'RMSIndividual - Standard';
    public static final String RMS_PRIORITY_MP_STANDARD = 'RMSMP - Standard';
    public static final String CASE_PRIORITY_MP_STANDARD = 'MP - Standard';
    public static final String CASE_PRIORITY_INDIVIDUAL_STANDARD= 'Individual - Standard';
    public static final String WEBTOCASE_SOURCE_SYDNEY_TRAINS = 'sydney trains';
    public static final String WEBTOCASE_SOURCE_NSW_TRAINS = 'nsw trains';
    public static final String WEBTOCASE_SOURCE_TNSW_TRAINS = 'tfnsw';

    public static final String MIN_CORR_WEBTOCASE_SOURCE_ROADS = 'Roads Webform';
    public static final String MIN_CORR_WEBTOCASE_SOURCE_TRANSPORT = 'Transport Webform';
    public static final String MIN_CORR_WEBTOCASE_SOURCE_West_Connex = 'WestConnex Webform';

    public static final String MIN_CORR_PORTFOLIO_ROADS = 'Roads, Maritime and Freight';
    public static final String MIN_CORR_PORTFOLIO_TRANSPORT = 'Transport and Infrastructure';
    public static final String MIN_CORR_PORTFOLIO_WestConnex = 'WestConnex';
    public static final String MIN_CORR_PORTFOLIO_OOS = 'Office of the Secretary';

    public static final String NOTEORATTACHMENT_PRIVACY_STANDARD = 'Standard'; 
    public static final String NOTEORATTACHMENT_PRIVACY_RESTRICTED = 'Restricted';
    public static final String NOTEORATTACHMENT_RECORDTYPENAME_ATTACHMENT = 'Attachment';
    
    public static final String ACTION_PLAN_NEW_STATUS = 'New';
    public static final String ACTION_PLAN_MCWS_AP_RECORD_TYPE_NAME = 'MCWS_Action_Plan';
    public static final String ACTION_PLAN_CLOSED_STATUS = 'Completed';
    public static final String ACTION_PLAN_TYPE_ADVICE_REQUEST = 'Advice Request';
    public static final String ACTION_PLAN_CFM_RECORDTYPE_NAME = 'CFM_Action_Plan'; 
    public static final String ACTION_PLAN_INCORRECT_ASSIGNMENT = 'Rejected-Incorrect Assignment';
    public static final String ACTION_PLAN_NEW_APPROVED = 'Action Plan in Review';
    public static final String ACTION_PLAN_CUST_RESP = 'Customer-Facing Response';
    
    public static final String CASE_NRR_RESPONSE_TYPE = 'No response required (NRR)';//Case Response type No Response required(NRR)
    public static final String CASE_RECORD_TYPE_MINCORRGENERAL = 'General Ministerial Correspondence';
    public static final String CASE_RECORD_TYPE_CAMPAIGN = 'Campaign';
    public static final String CASE_RECORD_TYPE_CAMPAIGNMEMBER = 'CampaignMember';
    public static final String CASE_ERROR_CHERRY_PICKING = 'You are not authorised to change ownership of this case. Please take ownership of the next priority case by clicking the \'Get Next\' button.';

    public static final String RMS_QUEUE_PREFIX = 'RMS_%'; 
    public static final String RMS_QUEUE_STRING = 'RMS_';
    public static final String RMS_QUEUE_TEST = 'RMS_AMD_Engineering_Services_CFM';
    public static final String STA_QUEUE_TEST = 'STA_Brookvale_Depot_CFM';
    public static final String HCF_BRANCH_NAME = 'HCF';
    public static final String CASE_RECORD_TYPE_STAFF = 'Staff'; 
    public static final String ACCOUNT_TYPE_AGENCY = 'Agency'; 
    public static final String ACCOUNT_TYPE_DIVISION = 'Division'; 
    public static final String CASE_ORIGIN_RMSWEBSITE = 'RMS Website';
    
    public static final String ACTION_PLAN_WAITING_APPROVAL = 'Awaiting Action Plan Approval';
    public static final String CASE_ID_PREFIX = '500';
    public static final String USER_ID_PREFIX = '005';
    public static final String GROUP_ID_PREFIX = '00G';
    public static set <String> MINCORRORRECORDTYPENAMES = new set <String> {'RMS_CE_Signatory', 'Roads_Freight_Ministerial_Correspondence', 'General_Ministerial_Correspondence','Transport_Ministerial_Correspondence', 'Campaign', 'CampaignMember'};
    public static set <String> MINCORROR_NON_CAMPAIGN_RECORD_TYPE_NAMES = new set <String> {'RMS_CE_Signatory', 'Roads_Freight_Ministerial_Correspondence', 'General_Ministerial_Correspondence','Transport_Ministerial_Correspondence'};        
    public static final String ASSIGNED_TO_AGENCY_STATUS = 'Received';
    public static final String CASE_IN_PROGRESS_STATUS = 'In Progress';

    public static final String CASE_RECORD_TYPE_NAME_MINCORR_ROAD = 'Roads_Freight_Ministerial_Correspondence';
    public static final String CASE_RECORD_TYPE_NAME_MINCORR_TRANSPORT = 'Transport_Ministerial_Correspondence';
    public static final String CASE_RECORD_TYPE_NAME_MINCORR_OOS = 'Office_of_the_Secretary_Ministerial_Correspondence';
    
    public static final String CASE_RECORD_TYPE_LABEL_MINCORR_ROAD = 'Roads & Freight Ministerial Correspondence';
    public static final String CASE_RECORD_TYPE_LABEL_MINCORR_TRANSPORT = 'Transport Ministerial Correspondence';
    public static final String CASE_RECORD_TYPE_LABEL_MINCORR_OOS = 'Office of the Secretary Correspondence';
    
    //DRAFT
    public static final set<String> draftStatus = new set<String> {'Senior Review', 'Editor Review', 'Manager Review'};
    public static final set<String> draftCaseClassifications = new set <String> {'Contentious', 'Highly Contentious'};
    public static final String DRAFT_MANAGER_REVIEW_STATUS = 'Manager Review';
    public static final String DRAFT_READY_FOR_PRINTING_STATUS = 'Ready For Printing';

    public static final String MIN_CORRO_MODE_NAME = 'MAGS'; 
    public static final String NON_MODAL_RECORD_TYPE_NAME = 'Non Mode';
    public static final String NON_MODAL_CASE_MODE = 'Non-modal';
    public static final String CASE_STATUS_AWAITING_ADVICE = 'Awaiting Advice';
    public static final String CASE_STATUS_ADVICE_RECEIVED = 'Advice Received';
    public static final Set<Id> SYS_ADMIN_IDS = new Map<Id, User>([select ProfileId from User where Profile.Name = 'System Administrator']).keySet();
    public static final String MIN_COR_API_INTEGRATION_USERNAME= 'MinCo Webform API Integration User';
    public static final String SIGNED_RESPONSE_DATA_CATEGORY_GROUP_NAME = 'SignedResponse';
    public static final String SIGNED_RESPONSE_DATA_CATEGORY_NAME = 'Signed_Response';
    public static final String STA_DEPOT_QUEUE_LIKE = 'STA_%_CFM'; 
    public static final String DEFAULT_MIN_CORRO_WEBTOCASE_STATUS = 'Pre-Registration';
    public static final String DEFAULT_EMAIL_MIN_CORRO_WEBTOCASE_STATUS = 'Registration';



    //Task
    public static final String TASK_PREVENT_DELETE_ERROR_MESSAGE = 'Non System Administrators can not delete task';
    public static final String TASK_PREVENT_UPDATE_ERROR_MESSAGE = 'Non System Administrators can not update completed task';
    public static final String EVENT_PREVENT_DELETE_ERROR_MESSAGE = 'Non System Administrators can not delete event';
    public static final String EVENT_PREVENT_UPDATE_ERROR_MESSAGE = 'Non System Administrators can not update completed event';
    public static final String EMAIL_MESSAGE_PREVENT_DELETE_ERROR_MESSAGE = 'Non System Administrators can not delete email messages';
    public static final String COMPLETED_TASK_RECORD_TYPE_NAME = 'CompletedTask';
    
    public static final String WEBTOCASE_SUCCESS_MSG = 'Thank you. Your case reference number is ';
    public static final String WEBTOCASE_SUCCESS_MSG_FOR_SNSW = 'Thank you. We have received your question, feedback or complaint.'; 
    
    public static final String CALL_STATUS_LEFT_A_MESSAGE = 'Left a message';
    public static final String CALL_STATUS_CALL_WENT_UNANSWERED = 'Call went unanswered';
    public static final String CALL_STATUS_LETTER_SENT_OUT = 'Letter sent out';
    public static final String CALL_STATUS_CONTACTED = 'Contacted';
    
    public static final String ACTION_PLAN_STATUS_ASSIGNED = 'Action Plan Assigned';
    public static final String ACTION_PLAN_STATUS_INPROGRESS = 'Action Plan in Progress';
    public static final String ACTION_PLAN_AGENCY_Q_NOT_FOUND = 'QUEUE-NOT-FOUND';
    public static final String ACTION_PLAN_TAKE_OWNERSHIP = 'Take Ownership';
    public static final String RMS_CE_SIGNATORY = 'Chief Executive, Roads and Maritime Services';
    public static final String AP_TYPE_AGENCY_RESPONSE = 'Agency Response';
    public static final String ACTION_PLAN_STATUS_AWAITING_SIG = 'Awaiting Signature';
    public static final String ACTION_PLAN_STATUS_READY_FOR_PRINT = 'Ready for Printing';
    
    public static final String ACTION_PLAN_AMENDMENT = 'Amendment';
    public static final String GIS_ADMIN_QUEUE = 'GIS_Admin_RMS_MC';
    public static final String ACTION_PLAN_REWORK = 'Rework';
    public static final String PERMISSION_SET_CORRO_OFFICER = 'RMS_Corro_Officer';
    public static final String DEFAULTBH='Default';//Name of the default business hour 
    public static final Integer WORKING_HOURS_PER_DAY = 8;

    public static final String AGENCY_TFNSW='TfNSW';
    public static final String AGENCY_HCF='HCF';
    public static final String AGENCY_MTS='MTS';

    public static final String MILESTONE_IN_PROGRESS='Attempted contact, Made contact and closed';
    public static final String MILESTONE_IN_PROGRESS2='Attempted contact, Made contact and closed 2';
    public static final String MILESTONE_IN_PROGRESS_TRAINS='Attempted contact, Made contact and closed - Trains';

    public static final String MILESTONE_SEND_LETTER='Send Letter';
    public static final String MILESTONE_CONTACT_MADE='Contact Made';
    public static final String MILESTONE_CASE_CLOSED='Case Closed';
    public static final String MILESTONE_CASE_CLOSED_95='Case closed SLA 95%';
    public static final String SITE_USER_NAME_SIGNATURE='Site';//The site user which gets created by default for running the code invoked by publicly accessed portion
    public static final String CASE_FILTER_SETTING_NAME='default';//the custom setting name for filtering certain case record type's fields such as description or subject for high priority keywords 
    
    public static final String ATTACHMENT_CATEGORY_AMENDMENT='Amendment';
    public static final String ATTACHMENT_CATEGORY_SIGNED_RESPONSE='Signed Response';
    public static final String ATTACHMENT_CONTENT_TYPE_PDF='application/pdf';
    public static final String MASTER_RECORD_TYPE_NAME = 'Master RT';
    public static final String EXTENSION_PDF = '.pdf';
    public static final string CONGA_QUERY_NAME = 'Document Print Query';
    public static final String CASE_OBJECT_CONFIGURATION_NAME_DEFAULT_CASE_OWNER='DefaultCaseOwner';

    global static final String TAXONOMY_STAFF_FACING='Active';
    global static final String TAXONOMY_MODE_TYPE='Mode';
    global static final String CASE_MULTIISSUE_MODE='Multi Issue';
    global static final String MULTI_ISSUE_TYPE='Multi-issue';
    global static final String CFM_MODES_CONFIG_NAME= 'default';
    public static final String DEFAULT_REFERRAL = 'Default';
    public static final String WEBTOCASE_SPAM_SETTING_NAME= 'WebToCase';
    public static final String TASK_CALL_STATUS_LEFT_MESSAGE='Left a message';
    public static final String TASK_CALL_STATUS_CALL_UNANSWERED='Call went unanswered';
    public static final String TASK_CALL_STATUS_CONTACTED='Contacted';
    public static final String TASK_CALL_STATUS_LETTER_SENT='Letter sent out';
    
    public static final String MODE_MARITIME = 'maritime';
    public static final String MODE_RMS_INTRANET = 'rms intranet';
    public static final String MODE_RMS = 'rms';
    public static final String MODE_SYDNEY_TRAINS = 'sydney trains';
    public static final String MODE_NSW_TRAINS = 'nsw trains';
    public static final String MODE_TFNSW_INTRANET = 'tfnsw intranet';
    public static final String MODE_TFNSW = 'tfnsw';
    public static final String MODE_NON_MODAL = 'non-modal';
    public static final String FEEDBACK_FOR_WEBSITE = 'website';
    public static final String FEEDBACK_FOR_APP = 'apps';
    public static final String SERCO_CANT_CHANGE_OWNER_OF_OTHERS_CASE='Serco_cant_change_owner_of_others_case';
    public static final String CONNECTION_USER_NAME = 'connection user';
    public static final String RESPONSIBLE_PARTY_SNSW = 'SNSW';
    public static final String RESPONSIBLE_PARTY_RMS = 'RMS';
    public static final String S2S_CONNECTION_ACCEPTED = 'Accepted';
    public static final String S2S_CONNECTION_NAME = 'Service NSW';
    public static final String DEFAULT_CASE_STATUS_FROM_SNSW = 'New';
    public static final String DEFAULT_CASE_TYPE_FROM_SNSW = 'Feedback';
    public static final String SNSW_HOLDING_QUEUE = 'SNSW Holding';
    public static final String SNSW_TRIAGE_QUEUE = 'SNSW Triage';
    public static final String AGENCY_SERCO = 'Serco';
    public static final String SERCO_AGENT_PROFILE = 'Serco Agent';
    
    //Attachment content types
    public static final String PDF = '%application/pdf'; 
    public static final String JPG = '%image/jpg'; 
    public static final String PNG = '%image/png' ;
    public static final String JPEG = '%image/jpeg';  
    public static final String MSWORD = '%application/msword'; 
    public static final String GIF = '%image/gif';
    public static final String PPT = '%application/vnd.ms-powerpoint';
    public static final String XLSX = '%application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    public static final String XLX = '%application/vnd.ms-excel';
    public static final String PPTX = '%application/vnd.openxmlformats-officedocument.presentationml.presentation';
    public static final String WORD = '%application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    
    
    public static final String UNSIGNED_RESPONSE = 'Unsigned Response';
    public static final String ENCLOUSER = 'Enclosures';    
    public static final String INCOMING = 'Incoming';    
    public static final String ATTACHMENT_CATEGORY_AS_PRECEDENTS = 'Precedents';
    public static final String ATTACHMENT_CATEGORY_AS_PREVIOUS_CORRESPONDANCE = 'Previous Correspondence';    
    public static final String SIGNED_RESPONSE = 'Signed Response';
    public static final String MINISTER_OF_ROAD = 'Minister_of_Road';
    public static final String MINISTER_OF_TRANSPORT = 'Minister_of_Transport';
    public static final String MINISTER_OF_WESTCONNEX = 'Minister_for_Western_Sydney_WestConnex_and_Sport';
    public static final String MINISTER_OF_REGIONAL_TRANSPORT_AND_ROADS = 'Minister_for_Regional_Transport_and_Roads';
    public static final String MINISTER_OF_OOS = 'Secretary_Transport_for_NSW';
    public static final String QUEUE_FOR_READY_OF_PRINTING = 'CRGS Admin - Ready for printing';
    public static final String MAGS_MANAGER_SIGNATORY_ROLE = 'Manager, Ministerial & Government Services - Roads, Maritime and Freight';
    public static final String MAGS_APPROVED_MIN_CORRO = 'MAGS Approved';
    public static final String AWAITING_MO_CONTACT_APPROVAL_MIN_CORRO = 'Awaiting MO Contact Approval';
    public static final String MO_CONTACT_REJECTED_MIN_CORRO = 'MO Contact Rejected';
    public static final String SIGNATORY_REJECTED_MIN_CORRO = 'Signatory Rejected';
    
    public static final String AWAITING_MO_SIGNATORY_APPROVAL_MIN_CORRO = 'Awaiting Signature';
    
    
    public static final Set<String> MO_DLO_AND_PA_ROLE_NAMES = new Set<String> {'Policy_Advisor_WestConnex','DLO_WestConnex','Policy_Advisor_Transport', 'DLO_Transport', 'Policy_Advisor_Road', 'DLO_Road', 'Executive_Director', 'Senior_Executive_Coordinator'};
    public static final set<String> MO_SIGNATORY_ROLE_NAMES = new set<String> {'Chief_of_Staff_WestConnex','Minister_for_Western_Sydney_WestConnex_and_Sport','Executive_Director_CRGS', 'Principal_MAGS_Manager', 'MAGS_Manager', 'Minister_of_Road', 'Chief_of_Staff_Road', 'Parliamentary_Secretary', 'Minister_for_Regional_Transport_and_Roads', 'Minister_of_Transport', 'Chief_of_Staff_Transport', 'Parliamentary_Secretary_Regional_Roads_Rail', 'Parliamentary_Secretary_for_Regional_Transport', 'Parliamentary_Secretary_for_Regional_Roads_and_Infrastructure', 'RMS_Chief_Executive', 'Secretary_Transport_for_NSW'};
    public static final String MO_SIGNED_AND_EMAILED_MIN_CORRO  = 'Signed and Emailed';  

    public static final String CASE_SIGNATURE_IMAGE_URI  = 'feedback/services/apexrest/mincor/v1/GenerateSignature?';
    
    public static final String MAGS_TEAM_A_QUEUE_NAME = 'Team_A';
    public static final String MAGS_TEAM_B_QUEUE_NAME = 'Team_B';
    public static final String MAGS_TEAM_C_QUEUE_NAME = 'Team_C';
    public static final String MAGS_TEAM_D_QUEUE_NAME = 'Team_D';
    public static final String MAGS_TEAM_E_QUEUE_NAME = 'Team_E';
    public static final String MAGS_TEAM_F_QUEUE_NAME = 'Team_F';

    public static final String DRAFT_THUNDERHEAD_URL_END_STRING = '?srPos=0&srKp=500&sfdc.override=1';

    public static final String ATTACHMENT_CATEGORY_ADVICE = 'Advice';

    public static final String EMAIL_AUTHOR='EmailAuthor';
    public static final String CASE_RESPONSE_TYPE_ADMIN_REFERRAL='Referred to other portfolio';
    public static final String CASE_RESPONSE_TYPE_PARTIAL_REFERRAL='Partial Referral';
    public static final String CASE_CONTACT_REFERRAL_TEMPLATE='caseContactReferralTemplate';
    
    public static final Map<String, String> TEAM_QUEUES_AND_TEAM_PICKLIST = new Map<String, String>{'Team A' => 'Team A', 'Team B' => 'Team B', 'Team C' => 'Team C', 'Team D' => 'Team D', 'Team E' => 'Team E', 'Team F' => 'Team F'};

    public static final String MINISTER_COMM_PREFERENCE_EMAIL = 'Email';

    public static final String ROADS_MO_CONTACT_REJECTED = 'Roads Manager Queue';
    public static final String TRANSPORT_MO_CONTACT_REJECTED = 'Transport Manager Queue'; 
    public static final String WestConnex_MO_CONTACT_REJECTED = 'WestConnex Manager Queue'; 
    public static final String OOS_MO_CONTACT_REJECTED = 'Office of the Secretary Manager Queue'; 
    public static final String EXECUTIVE_DIRECTOR_SIGNATORY_ROLE = 'Executive Director, Customer Relations & Government Services';
    public static final String PRINCIPAL_MAGS_MANAGER_SIGNATORY_ROLE = 'Principal Manager, Ministerial & Government Services';

    public static final Set<String> MO_SIGNATORY_ROLES_FOR_REJECTION = new Set<String>{'Minister_for_Western_Sydney_WestConnex_and_Sport', 'Minister_of_Road', 'Chief_of_Staff_Road', 'Parliamentary_Secretary', 'Minister_of_Transport', 'Minister_for_Regional_Transport_and_Roads', 'Chief_of_Staff_Transport', 'Parliamentary_Secretary_Regional_Roads_Rail', 'Parliamentary_Secretary_for_Regional_Transport', 'Parliamentary_Secretary_for_Regional_Roads_and_Infrastructure', 'RMS_Chief_Executive', 'Secretary_Transport_for_NSW'};
    public static final Set<String> MO_MANAGER_ROLES_FOR_REJECTION = new Set<String>{'Executive_Director_CRGS','Principal_MAGS_Manager','MAGS_Manager'};
    
    public static final Set<String> CONGA_PRINT_ACCESS_ROLE_NAMES = new Set<String> {'Policy_Advisor_Transport', 'DLO_Transport', 'Policy_Advisor_Road', 'DLO_Road', 'Executive_Director', 'Senior_Executive_Coordinator', 'MO_Office_Manager_Road', 'MO_Office_Manager_Transport'};
    
    public static final String MO_VIEW_CUSTOMER_CONTACT_EMAIL_TEMPLATE = 'MOViewCustomerContactEmailTemplate';
    public static final String MO_VIEW_ADDITIONAL_CORRO_CONTACT_EMAIL_TEMPLATE = 'MOViewAdditionalCorroContactEmailTemplate';
    public static final String MO_VIEW_STAFF_CONTACT_EMAIL_TEMPLATE = 'MOViewStaffContactEmailTemplate';
    
    public static final String ACTION_PLAN_TYPE_AGENCY_RESPONSE = 'Agency Response';
    public static final String APPROVAL_STATUS_PENDING = 'Pending';
    public static final String MO_APPROVAL_EMAIL_TEMPLATE_TYPE = 'MO View Email Attachment';
    public static final String REJECTED_STATUS_MIN_CORRO = 'Rejected Action Plan';
    
    public static final String CASE_REVIEW_STATUS = 'Review';
    public static final String DIGITAL_PROCESS_SEND_EMAIL = 'Send Email Process';
    public static final String CASE_RECORD_TYPE_NAME_WESTCONNEX = 'WestConnex_Ministerial_Correspondence';
    public static final String CASE_RECORD_TYPE_NAME_WESTCONNEX_1 = 'WestConnex Ministerial Correspondence';
    public static final String RESPONSIBLE_MAGS_OFFICER_USER_ID = 'User Id';
    
    //variable for Private Operator
   public static final String PRIVATE_OPERATOR_RECORD_TYPE = 'Private_Operators';
   public static final String LIGHT_RAIL_RECORD_TYPE = 'Light_Rail';
   public static final String SUCCESS_PROCESSING_STATUS = 'Success';
   public static final String FAILED_PROCESSING_STATUS = 'Failed';
   public static final String BU_STAGINING_JOB_ID = 'Job Id';
   public static final String CASE_STATUS_REASSIGNED = 'Re-assigned';
   
   //Exception Handling Boolean - Added by Ian F, tfNSW, 05/09/2017
   public static Boolean THROW_EXCEPTIONS = false;
   static{
       List<User> u = [select Throw_Exceptions__c from User where Id=:UserInfo.getUserId()];
       if (u!=null && u.size()>0){
          THROW_EXCEPTIONS = u[0].Throw_Exceptions__c; 
       }  
   }
   
   //25/08/2017: Arxxus => variable for MO Enhancements Aug Release
   public static final String BUSINESSHOURS_NAME = 'TfNSW';
   public static final Integer numberOfBusinessHrsInADay = 8;
   
    
   // oct 2017 combined pdf link on Manage supporting documents
   public static final String combinedPDFQ0 = 'Combined PDF';
   public static final String combinedPDFQ1 = 'Combined PDF Limit 1';

   //25/08/2017: Arxxus => variable for MO Enhancements OCT Release
   public static final String DRAFT_APPROVAL_STATUS_REJECTED = 'Rejected';
 
}