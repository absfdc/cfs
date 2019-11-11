/*------------------------------------------------------------
Author:        Arxxus
Description:   wrapper class to store attachment information
History
<Date>        <Authors Name>     <Brief Description of Change>
12-DEC-2016   Arxxus          Comments and cleanup
------------------------------------------------------------*/

global class AttachmentInfo {
    
    public AttachmentInfo() {
    
    }

    public Id attachmentId {get;set;}
    public String name {get; set;}
    public String body {get; set;}
    public String contentType {get; set;}
    public String caseNumber{get; set;}
    public String currentCaseNumber{get; set;}
    public Date createdDate {get; set;}
    public String createdBy {get; set;}
    public Integer totalCount {get; set;}
    public String rejectionComment {get; set;}

}