@isTest
private class TimeOfIncidenceParser_Test {
    static testmethod void FeedbackCallTest1(){
        TimeOfIncidenceParser plugin = new TimeOfIncidenceParser();
        Map<String,Object> inputParams = new Map<String,Object>();
        
        Date dateInstance = Date.newInstance(2016,10,20);
        String timeInstance = '1210';
        
        inputParams.put('date', dateInstance);
        inputParams.put('time', timeInstance);
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = plugin.invoke(request);
        DateTime dt = DateTime.newInstance(2016, 10, 20, 12, 10, 00);
        plugin.describe();
        //system.assertEquals(dt, result.TimeAndDate);
    }
    
	static testmethod void FeedbackCallTest2(){
        TimeOfIncidenceParser plugin = new TimeOfIncidenceParser();
        Map<String,Object> inputParams = new Map<String,Object>();
        
        Date dateInstance = Date.newInstance(2016,10,20);
        String timeInstance = '12:10';
        
        inputParams.put('date', dateInstance);
        inputParams.put('time', timeInstance);
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        //result = plugin.invoke(request);
        //DateTime dt = DateTime.newInstance(2016, 10, 20, 12, 10, 00);
        //system.assertEquals(dt, result.TimeAndDate);
    }    
}