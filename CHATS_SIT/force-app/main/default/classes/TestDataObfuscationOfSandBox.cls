public class TestDataObfuscationOfSandBox {

    
    public void testObfSandboxFromObject(){
        // System.debug('#### Organization ID :'+ context.organizationId());
        // System.debug('### Applying Data Obfuscation for the Sandbox Name: '+ context.sandboxName());
        //Run data obfuscation in batch mode
        
        StaticResourceUtil.populateObfuscateFieldListObj('ObfuscateFieldList');
        
      
        List<Obfuscate_Field_List__c> obfuscateFieldObjList = [SELECT Field_Api_Name__c, Object_Api_Name__c, Field_Category__c,Data_Format__c  FROM Obfuscate_Field_List__c ORDER BY Object_Api_Name__c];
        
        //Map Object to fields list
       Map<String, Map<String, List<String>>> objectNameFieldMap = new Map<String, Map<String,List<String>>>();
       Map<String,List<String>> ObjectToFieldMap = new Map<String, List<String>>();

System.debug('T-01');

       for(Obfuscate_Field_List__c mdt: obfuscateFieldObjList){
System.debug('T-01-01');
           System.debug('################ Object_Api_Name__c ### = '+mdt.Object_Api_Name__c);
           String upperCaseObjectAPiName =   mdt.Object_Api_Name__c;
           upperCaseObjectAPiName = upperCaseObjectAPiName.toLowerCase();
           
           String lowerCaseFieldAPIName = mdt.Field_Api_Name__c;
           lowerCaseFieldAPIName = lowerCaseFieldAPIName.toLowerCase();
          
           String upperCaseFieldCategory = mdt.Field_Category__c;
           upperCaseFieldCategory = upperCaseFieldCategory.toUpperCase();
           
           String upperCaseDataFormat = mdt.Data_Format__c;
           upperCaseDataFormat = upperCaseDataFormat.toUpperCase();
           
           if(objectNameFieldMap.get(upperCaseObjectAPiName) == null){
               List<String> fieldList = new List<String>();
               Map<String, List<String>> fieldCatToFieldListMap = new Map<String, List<String>>();
               fieldList.add(lowerCaseFieldAPIName);
               fieldCatToFieldListMap.put(upperCaseFieldCategory,fieldList);
                
               //ObjectToFieldMap.put(mdt.Object_Api_Name__c,fieldList);
               objectNameFieldMap.put(upperCaseObjectAPiName, fieldCatToFieldListMap);
           }else{
               /*List<String> fieldList =  ObjectToFieldMap.get(mdt.Object_Api_Name__c);
               fieldList.add(mdt.Field_Api_Name__c);
               ObjectToFieldMap.put(mdt.Object_Api_Name__c,fieldList);*/
               
               Map<String, List<String>> fieldCatToFieldListMap = objectNameFieldMap.get(upperCaseObjectAPiName);
               if(fieldCatToFieldListMap.get(upperCaseFieldCategory) != null){
                   List<String> fList = fieldCatToFieldListMap.get(upperCaseFieldCategory);
                   fList.add(lowerCaseFieldAPIName);
                   fieldCatToFieldListMap.put(upperCaseFieldCategory, fList);
               }else{
                   List<String> fList = new List<String>();
                   fList.add(lowerCaseFieldAPIName);
                   fieldCatToFieldListMap.put(upperCaseFieldCategory, fList);                   
               }
               objectNameFieldMap.put(upperCaseObjectAPiName, fieldCatToFieldListMap);
           }
       }
System.debug('T-02');      
        //Iterate Map Key List
        //for(String ObjectName: ObjectToFieldMap.keySet()){
        for(String ObjectName: objectNameFieldMap.keySet()){  
             //check for existence of Object
System.debug('T-02-01');       
             
            if(!ApexUtil.isvalidObject(objectName))
                continue;
            
             Map<String, List<String>> fieldCatToFieldListMap = objectNameFieldMap.get(ObjectName);
             List<String> selectableFieldList = new List<String>();
             for(String fieldCatName: fieldCatToFieldListMap.keySet()){
                //check for validFieldList and build ValidFieldLists
                List<String> fieldList = fieldCatToFieldListMap.get(fieldCatName);
                System.debug('################ fieldList ### = '+fieldList);
                List<String> validFieldList = new List<String>();   
                
                for(String fieldName: fieldList){
                    System.debug('################ ObjectName ### = '+ObjectName);
                    System.debug('################ fieldName ### = '+fieldName);
                    if( ApexUtil.isvalidField(ObjectName, fieldName)){
                        validFieldList.add(fieldName);
                        selectableFieldList.add(fieldName);
                    }
                }
                fieldCatToFieldListMap.put(fieldCatName,validFieldList);
             }
             //validFieldList= validFieldList.length() > 0 ? validFieldList.substring(0, validFieldList.length()-1):'';
             System.debug('################ selectableFieldList.size() ### = '+selectableFieldList.size());
            String commaSeparatedFieldList ='';
            for(String fName : selectableFieldList){
                commaSeparatedFieldList = commaSeparatedFieldList + fName +',';
            }
            //build query String
            String selectClause = commaSeparatedFieldList.length() > 0 ? 'SELECT Id, '+ commaSeparatedFieldList.substring(0, commaSeparatedFieldList.length()-1):'SELECT Id ';
            String whereClause ='';
            String queryStr = selectClause + ' FROM '+ObjectName ;
            if(ObjectName.equalsIgnoreCase('User')){
                whereClause = 'where name not in (\'Platform Integration User\',  \'Automated Process\' , \'Data.com Clean\') ' ;
                queryStr = queryStr + ' '+whereClause;
            }
            
            System.debug('################ queryStr ### = '+queryStr);
            DataObfuscationBatchJob dataObfuscationJobObj = new DataObfuscationBatchJob();
            dataObfuscationJobObj.objectName = ObjectName;
            dataObfuscationJobObj.FieldCategToFieldsMap = fieldCatToFieldListMap;
            //dataObfuscationJobObj.fieldList = (validFieldList).split(',');
            System.debug('################ dataObfuscationJobObj.fieldList ### = '+fieldCatToFieldListMap);
            dataObfuscationJobObj.queryString = queryStr;
            System.debug('###### queryString = '+queryStr);
            Database.executeBatch(dataObfuscationJobObj, 100);
        }
    }

    
    
}