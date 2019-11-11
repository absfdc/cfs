/*------------------------------------------------------------
Author:        Shrikant Hase
Company:       Arxxus.com
Description:   A handling class for a Feedback call flow

Test Class:    TimeOfIncidenceParser_Test
History
25 Oct 2016      Shrikant Hase     created
------------------------------------------------------------*/
global class TimeOfIncidenceParser implements process.Plugin{
/*------------------------------------------------------------
Author:        Shrikant Hase
Company:       Arxxus.com
Description:   Function concats Date and Time to send Datetime to flow
Inputs:        Process.PluginRequest
Output:        Process.PluginResult
History
25 Oct 2016      Shrikant Hase     created
------------------------------------------------------------*/
    global Process.PluginResult invoke(Process.PluginRequest request){
        DateTime dateTimeInstance, receivedDateTime;
        String inputTimeString;
        Date dateInstance;
        Timezone timeZoneInstance = UserInfo.getTimeZone();
        
        if(request.inputParameters.get('date') == null){
            receivedDateTime = DateTime.now();
        }
        else{
            receivedDateTime = (DateTime) request.inputParameters.get('date'); 
        }
        if(request.inputParameters.get('time') == null || request.inputParameters.get('time') == ''){
            inputTimeString = '00:00';
        }
        else{
            inputTimeString = (String) request.inputParameters.get('time');
            if(inputTimeString.contains(':') == false){
                inputTimeString = inputTimeString.left(2)+':'+inputTimeString.right(2);
            }
        }
        dateInstance = receivedDateTime.date();
        dateTimeInstance = DateTime.newInstance(dateInstance,Time.newInstance(Integer.valueOf(inputTimeString.substringBefore(':')),Integer.valueOf(inputTimeString.substringAfter(':')),00,00));    
        dateTimeInstance.addSeconds(timeZoneInstance.getOffset(dateInstance)/1000);
        return new Process.PluginResult('TimeAndDate',dateTimeInstance);
    }

/*------------------------------------------------------------
Author:        Shrikant Hase
Company:       Arxxus.com
Description:   A method describes inputs from flow and outputs to flow
Inputs:        None
History
25 Oct 2016      Shrikant Hase     created
------------------------------------------------------------*/
    global Process.PluginDescribeResult describe() { 
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.Name = 'IncidenceTimeParser';
        result.Tag = 'IncidenceTimeParser';
        result.inputParameters = new 
         List<Process.PluginDescribeResult.InputParameter>{ 
            new Process.PluginDescribeResult.InputParameter('date', Process.PluginDescribeResult.ParameterType.DATE, true),
            new Process.PluginDescribeResult.InputParameter('time', Process.PluginDescribeResult.ParameterType.STRING, true)
         }; 
        result.outputParameters = new 
        List<Process.PluginDescribeResult.OutputParameter>{              
            new Process.PluginDescribeResult.OutputParameter('TimeAndDate', 
                Process.PluginDescribeResult.ParameterType.DATETIME)
         }; 
        return result; 
   }
}