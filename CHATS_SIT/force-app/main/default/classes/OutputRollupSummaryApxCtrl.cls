public with sharing class OutputRollupSummaryApxCtrl {
    
    @AuraEnabled
    public static Decimal getRollupSummaryValue(String query, String rollUpFieldAPIName, String rollupType, String recordId, Boolean isAuthObjRec){
        Map<String, Object> objectData = new map<String, Object>();
      //  Boolean isSuccessful; //This variable is used in this method
      //  String message;   //This variable is used in this method
        Decimal value = 0;
        try{
            if(isAuthObjRec){
                query = string.escapeSingleQuotes(query);
                query = query.replace('\\\'', '\'');
                System.debug('query:'+query);
                
                List<T_AUTH__c> detailRecords = Database.query(query);
                System.debug('detailRecords:'+detailRecords);
                
                for(T_AUTH__c objAuth : detailRecords){
                    if(objAuth.batchsit_t_auth_status__r != null && objAuth.batchsit_t_auth_status__r.size()>0){
                       value ++; 
                    }
                }
            }        
            else{
                query = string.escapeSingleQuotes(query);
                query = query.replace('\\\'', '\'');
                System.debug('query:'+query);
                
                List<SObject> detailRecords = Database.query(query);
                System.debug('detailRecords:'+detailRecords);
                if(rollupType=='COUNT'){
                   
                    value = detailRecords.size();
                }
                for(SObject detailRecord:detailRecords){
                    if(detailRecord.get(rollUpFieldAPIName)!=null){
                        if(rollupType=='SUM'){
                            value+=Decimal.valueOf(detailRecord.get(rollUpFieldAPIName)+'');
                        }else if(rollupType=='MAX' && (Decimal.valueOf(detailRecord.get(rollUpFieldAPIName)+'')>value || value==0)){
                            value=Decimal.valueOf(detailRecord.get(rollUpFieldAPIName)+'');
                        }else if(rollupType=='MIN' && (Decimal.valueOf(detailRecord.get(rollUpFieldAPIName)+'')<value || value==0)){
                            value=Decimal.valueOf(detailRecord.get(rollUpFieldAPIName)+'');
                        }
                    }
                }
            }
            objectData.put('value',value);
//            isSuccessful=true;
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'OutputRollupSummaryApxCtrl','Method__c'=>'getRollupSummaryValue'});
            //  isSuccessful=false;
    //        message = ex+'';
        }
        return value;
    }
}