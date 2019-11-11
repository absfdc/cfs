/**
 * Copyright 2014 Arxxus Technology Partners Pty Ltd. All rights reserved.
 * Arxxus PROPRIETARY/CONFIDENTIAL. Use is subject to license terms.
 * 
 * Arxxus Utilities Framework
 * @author Arxxus
 */
 
global class ATP_CSVParser implements Iterator<List<String>> {
    
    /** the header Row Raw Data */
    private String rawHeaderRow;
    
    private List<String> headerRow;
    
    /** the parsed input file as list of Strings */
    private  List<String> lines;
    
    /** handle to current iteration index */
    private Integer iterationIx = 1;
    
    /** the raw file as String */
    public String rawFileData {get;set;}
    
    /** parsed input file as list of fields */
    private final List<List<String>> allFields;
    
    /** field Separator */
    private final String FIELDSEP;
    
    /** row Separator */
    private final String ROWSEP;
	
    private static final String COMMASEP = ',';
    /**
     * return the header line
     */
    public String getRawHeaderRow() {
        return this.rawHeaderRow;
    }
    
    /**
     * return the raw header row
     */
    public List<String> getHeaderRow() {
        return this.headerRow;
    }
    
    
    /**
     * Create an instance of the Parser with passed Blob
     */
    public ATP_CSVParser(Blob contentFile, boolean hasHeaderRow, String fieldSep) { 
        this(contentFile, hasHeaderRow, fieldSep, '\r\n');
    }
    
    /**
     * Create an instance of the Parser with passed Blob
     */
    public ATP_CSVParser(Blob contentFile, boolean hasHeaderRow, String fieldSep, String rowSep) { 
        this(contentFile.toString(), hasHeaderRow, fieldSep, rowSep);
    }
    

    /**
     * Create an instance of the Parser with passed String
     */
    public ATP_CSVParser(String contentFile, boolean hasHeaderRow, String fieldSep){
        this.FIELDSEP = fieldSep;
        this.ROWSEP   = rowSep;
        this.allFields = parseCSV(contentFile, hasHeaderRow);        
    }

    /**
     * Create an instance of the Parser with passed String
     */
    public ATP_CSVParser(String contentFile, boolean hasHeaderRow, String fieldSep, String rowSep){
        this.FIELDSEP = fieldSep;
        this.ROWSEP   = rowSep;
        this.allFields = parseCSV(contentFile, hasHeaderRow);        
    }
    /**
    * Default header row exists, comma field sep
    */    
    public ATP_CSVParser(String contentFile, boolean hasHeaderRow){
        this.FIELDSEP = COMMASEP;
        this.ROWSEP   = '\r\n';
        this.allFields = parseCSV(contentFile, hasHeaderRow);        
    }
    
    /**
    * adapted from http://wiki.developerforce.com/page/Code_Samples#Parse_a_CSV_with_APEX
    */
    private List<List<String>> parseCSV(String contents, Boolean hasHeaderRow ) {
       
        List<List<String>> allFields = new List<List<String>>();
        allFields = CSVReader.readCSVFile(Blob.valueOf(contents));
        List<String> rawData = new List<String>();

        if(hasHeaderRow) {
            this.headerRow = allFields.get(0);

            for(String tempString : this.headerRow) {
                
                rawData.add(tempString);
            }

            this.rawHeaderRow = rawData.get(0);
            allFields.remove(0);
            System.debug('Header Row ' + this.headerRow);
        }
          
        System.debug('All Fields = ' + allFields);
        
        return allFields;       
    }
    
    //iterator methods
    /**
     * Check if the fields data list has remaining rows
     */
    global Boolean hasNext(){ 
      return allFields.size() > 0;
    }    
    
    /**
     * return the next available row of fields
     */
    global List<String> next(){
        iterationIx++;
        return allFields.remove(0);
    }
    
    /**
     * return the raw row data corresponding to the
     * current iteration handle -1 
     * This is to correspond to the same data as fetched in the preceding next call
     * Note that to use this correctly, the calls must be in the following order:
     * List<String> data = iterator.next();
     * String rawData = iterator.rawRowAtIteratorIndex();
     */
    public String rawRowAtIteratorIndex() {
        String line = lines.get(iterationIx-1);
        line.replaceAll('DBLQT', '"');
        return line;
    }
    
    /*
    * return the number of rows of data in
    * csv file.This will include header row as well.
    */
    
    public Integer numberOfRawRowRecords(){
        return this.allFields.size();
    }
    
}