public with sharing class WebformContactController {
    
    public transient List<SelectOption> states;
    public transient List<SelectOption> previouslyRaisedIssueOptions;
    public transient String outsideAus {get; set;}
    
    public WebformContactController() {
    
    }
    
    public void setStates(List<SelectOption> options) {
        states = options;
    }
    
    public List<SelectOption> getStates() {
        states = new List<SelectOption>();
        states.add(new SelectOption('', 'NA'));
        Map<String, AusStates__c> ausStates = AusStates__c.getAll();
        Map<Integer, String> orderVsState = new Map<Integer, String>();
        List<Integer> sortOrder = new List<Integer>();
        for(AusStates__c state: ausStates.values()) {
            sortOrder.add((Integer)state.Sort_order__c);
            orderVsState.put((Integer)state.Sort_order__c, state.Name);
        }
        sortOrder.sort();
        outsideAus = '';
        for(Integer index : sortOrder) {
            String stateLabel;
            if(ausStates.get(orderVsState.get(index)).Outside_Australia__c) {
                outsideAus = orderVsState.get(index);
                stateLabel = '';
            } else {
                stateLabel = orderVsState.get(index);
            }            
            states.add(new SelectOption(stateLabel, orderVsState.get(index)));
        }
        return states;
    }
    
    public void setPreviouslyRaisedIssueOptions(List<SelectOption> optionValues) {
        previouslyRaisedIssueOptions= optionValues;
    }
    
    public List<SelectOption> getPreviouslyRaisedIssueOptions() {
        previouslyRaisedIssueOptions = new List<SelectOption>();        
        Schema.DescribeFieldResult fieldResult = Case.User_have_raised_the_issue_previously__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry fieldValue : ple) {
            previouslyRaisedIssueOptions.add(new SelectOption(fieldValue.getValue(),fieldValue.getLabel()));
        }       
        return previouslyRaisedIssueOptions;
    }
}