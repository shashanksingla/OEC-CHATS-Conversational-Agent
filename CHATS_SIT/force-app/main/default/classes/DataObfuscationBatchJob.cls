/*
* This batch job is invoked as part of salesforce sandbox refresh activity
* to perform Data obfuscation as provided by custom metadata information.
* */

global class DataObfuscationBatchJob  implements Database.Batchable<sObject>{
    global  String queryString;
    global  List<String> fieldList;
    global  String objectName;
    global  Map<String, List<String>> objectNameToFieldsMap ;
    global  Map<String, List<String>> FieldCategToFieldsMap ;  
    
    global Database.QueryLocator start(Database.BatchableContext batchContext){
        //run this batch job only if it is sandbox
        boolean isSandboxInstance = false;
        for(Organization org : [Select isSandbox from Organization limit 1]){
            isSandboxInstance = org.isSandbox;
        }
        
        if(isSandboxInstance == TRUE){
             System.debug('###### queryString = '+queryString);
            return Database.getQueryLocator(queryString);
        }else if(Test.isRunningTest()){
            return Database.getQueryLocator(queryString+ ' limit 1');
        }else {
            return Database.getQueryLocator(queryString + ' limit 0');
        }
        
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> sobjList){
        
        for(sObject sObj : sobjList){
           
            for(String fieldCatName : FieldCategToFieldsMap.keySet()){
                System.debug('###### fieldCatName = '+fieldCatName);
                List<string> fieldList = FieldCategToFieldsMap.get(fieldCatName);
                for(String field: fieldList){
                    System.debug('###### field = '+field);
                    ApexUtil.obfuscateFieldData(objectName, sObj, field,fieldCatName);
                }
            }
        }
        //update sObjList;
        Database.SaveResult[] srList = Database.update(sObjList, true);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                //System.debug('Successfully inserted  ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
            
        }
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('######## Batch Job Completed.');
    }
    
    
}