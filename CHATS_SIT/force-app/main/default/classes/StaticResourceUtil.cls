public class StaticResourceUtil {

    
    public static StaticResource getStaticResourceDataByName(String resName){
        staticResource statResourceObj = null;
        try{
            statResourceObj = [SELECT Id, body from staticResource where name =:resName limit 1];
        }catch(Exception ex){
            System.debug('Error while retrieving static resource '+ex.getMessage());
        }
        
        return statResourceObj;
    }
    
    public static void populateObfuscateFieldListObj(String resFieldListName){
       staticResource obfuscateFieldList = getStaticResourceDataByName(resFieldListName);
       List<Obfuscate_Field_List__c> obfuscateFieldObjList = new List<Obfuscate_Field_List__c>();
       System.debug(' ### Static resource file Name is '+resFieldListName) ;
       String[] csvFileLines = new String[]{}; 
        blob body = obfuscateFieldList.body;
        //String encodedString = EncodingUtil.convertToHex(body);
        String decodeString =  EncodingUtil.base64Encode(body);
        String csvAsString = body.toString();
       System.debug('Body of file: ' + csvAsString      );
         // Split CSV String to lines
        csvFileLines = csvAsString.split('\n'); 
        for(Integer i=0; i<csvFileLines.size(); i++){
            Obfuscate_Field_List__c obfFieldObj = new Obfuscate_Field_List__c();
            String[] csvRecordData = csvFileLines[i].split(',');
            String objectAPIName = csvRecordData[0].trim();
            String fieldAPIName = csvRecordData[1].trim();
            String fieldCategory = csvRecordData[2].trim();
            String dataFormatt = csvRecordData[3].trim();
            if(i== 0){
                System.debug(' ### Static resource file Name objectAPIName is '+objectAPIName) ;
                System.debug(' ### Static resource file Name fieldAPIName is '+fieldAPIName) ;
                System.debug(' ### Static resource file Name fieldCategory is '+fieldCategory) ;
               if( !(objectAPIName == 'OBJECT_API_NAME' && fieldAPIName == 'FIELD_API_NAME' && fieldCategory == 'FIELD_CATEGORY')){
                    break;
               }
            }
            //validate corresponding column name to match for inserting data into tables
            if(i != 0){
                obfFieldObj.Object_Api_Name__c =csvRecordData[0].trim();
                obfFieldObj.Field_Api_Name__c =csvRecordData[1].trim();
                obfFieldObj.Field_Category__c =csvRecordData[2].trim();
                obfFieldObj.UniqueExternalId__c =csvRecordData[0].trim()+csvRecordData[1].trim();
                obfFieldObj.Data_Format__c=csvRecordData[3].trim();
                obfuscateFieldObjList.add(obfFieldObj);
            }
           // System.debug('array value at '+i + '  '+csvFileLines[i]);
        }
       // SYstem.debug('body == '+csvAsString);
       // 
       //delete all the records before we update this table to make sure all the time we use static resource source 
       
        List<Obfuscate_Field_List__c> deleteRecList = [select id from Obfuscate_Field_List__c];
        delete deleteRecList;
           
        System.debug(' ### Static resource file Name obfuscateFieldObjList size is '+obfuscateFieldObjList.size()) ;
        Schema.SObjectField uniqueExtField = Obfuscate_Field_List__c.Fields.UniqueExternalId__c;
        Database.UpsertResult[] upsertList = Database.upsert(obfuscateFieldObjList,uniqueExtField,false);
        for (Database.UpsertResult sr : upsertList) {
            if (sr.isSuccess()) {
                // Operation was successful
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());                    
                    System.debug('fields that affected this error: ' + err.getFields());
                    
                }
            }
        }
      // if(obfuscateFieldObjList.size() > 0)
            //upsert obfuscateFieldObjList;
    }
}