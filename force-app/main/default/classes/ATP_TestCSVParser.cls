/**
 * Copyright 2014 Arxxus Technology Partners Pty Ltd. All rights reserved.
 * Arxxus PROPRIETARY/CONFIDENTIAL. Use is subject to license terms.
 * 
 * Arxxus Utilities Framework
 * @author raghu
 */
 
 
 /**
  * Test CSV Parser 
  */
 @isTest
 public class ATP_TestCSVParser {
    
    public static testmethod void testBlobData(){
        String testData = 'Header1, Header2\r\n'
                       + 'value1,value2\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        System.assert(true, (p.next().size()==2));
        
    }
    
    public static testmethod void testStringData() {
        String testData = 'Header1, Header2\r\n'
                       + 'value1,value2\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(testData, true, ',' , '\r\n');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        System.assert(true, (p.next().size()==2));
    }

   
    public static testmethod void testfieldSep() {
        String testData = 'Header1, Header2\r\n'
                       + 'value1,value2\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(testData, true, ',' );
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        System.assert(true, (p.next().size()==2));
    }

    
    public static testmethod void testDefaultHeaderRow() {
        String testData = 'Header1, Header2\r\n'
                       + 'value1,value2\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(testData, true);
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        System.assert(true, (p.next().size()==2));
    }

    public static testmethod void testrawRowAtIteratorIndex() {
        String testData = 'Header1, Header2\r\n'
                       + 'value1,value2\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(testData, true,',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        System.assert(true, (p.next().size()==2));
        //String line = p.rawRowAtIteratorIndex();
    }
    
    public static testmethod void testDblQuoteData() {
        String testData = 'Header1, Header2\r\n'
                       + '"value1","value2"\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        List<String> row = p.next();
        System.assert(true, (row.size()==2));
        System.assert(true, row.get(0).equals('"value1"'));
        System.assert(true, row.get(1).equals('"value2"'));
    }
    
    public static testmethod void testDblQuotedCommaData() {
        String testData = 'Header1, Header2\r\n'
                       + '"value1, valuex","value2, valuey"\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        List<String> row = p.next();
        System.assert(true, (row.size()==2));
        System.assert(true, row.get(0).equals('"value1, valuex"'));
        System.assert(true, row.get(1).equals('"value2, valuey"'));
    }

    public static testmethod void testDblQuotedDblQuoteData() {
        String testData = 'Header1, Header2\r\n'
                       + '"value1, ""valuex","value2, ""valuey"\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        List<String> row = p.next();
        System.assert(true, (row.size()==2));
        System.assert(true, row.get(0).equals('"value1, ""valuex"'));
        System.assert(true, row.get(1).equals('"value2, ""valuey"'));
    }

    public static testmethod void testRandomWorstCaseData() {
        String testData = 'Header1, Header2\r\n'
                       + '"""value1, ""valuex""","""value2, ""valuey"""\r\n';
    
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        System.assert(true, p.getRawHeaderRow().equals('Header1, Header2'));
        System.assert(true, p.hasNext());
        List<String> row = p.next();
        System.assert(true, (row.size()==2));
        System.assert(true, row.get(0).equals('"""value1, ""valuex"""'));
        System.assert(true, row.get(1).equals('"""value2, ""valuey"""'));
    }
    
    public static testmethod void testProfilingLimits() {
        Integer maxCpuTime = Limits.getLimitCpuTime();
        
        Integer maxRows = 6000; //10000;

        String testData = 'Header1, Header2\r\n';
        Integer count = 0;
        while(count< maxRows){
            testData += '"value1","value2"\r\n';
            count++;
        }
        //start profiling
        Integer cpuTime1 = Limits.getCpuTime();
        ATP_CSVParser p = new ATP_CSVParser(Blob.valueOf(testData), true, ',');
        
        while (count>0){
            p.next();
            count--;
        }
        
        Integer cpuTime2 = Limits.getCpuTime();
        
        System.debug('Transaction Millsecs = [' + (cpuTime2 - cpuTime1) + ']');
        //end profiling
    }
 }