/********************************************************************************************
* NAME         : APXPolicyRecordsServices
* DESCRIPTION  : This apex class is the service class to handle all the policy records.
* @AUTHOR SHUBHAM JAIN
* @DATE 09/25/2017
*   
*
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* Shubham Khandelwal             5/12/2018                          - changing variable name from lstIdSuccessRecords  to lstIdSuccRecs
*                                                                   - changing variable name from sourceSObjectAPIName  to srcSObjAPIName
* ----------------------------------------------------------------------------                 
********************************************************************************************/
public with sharing class APXPolicyRecordsServices {
    
    static List<SObject> lstSObject = new List<SObject>();
    public static Map<String,List<Policy_Object__mdt>> policyObjects_mdt = new Map<String,List<Policy_Object__mdt>>();
    private static List<String> policyObjectNames = new List<String>{'T_APPLN_CASE__c','T_APPLN_INDIV__c','T_APPLN_CUST__c','T_APPLN_DSBLTY__c',
            															'T_APPLN_ADR__c','T_APPLN_EMPLMT__c','T_APPLN_SELF_EMPLMT__c','T_APPLN_REL__c',
        															'T_APPLN_OTHER_INCOME__c','T_APPLN_EDUC__c','T_APPLN_DDTN__c','T_APPLN_CHILD_SUP__c'};
    // modified for CCCAP-14909         															
    public static void getPolicyObjectRecords(){
        list<Policy_Object__mdt> returnList = new List<Policy_Object__mdt>();
        for(Policy_Object__mdt mdt : [SELECT Source_Object_API_Name__c,
                                      Target_Object_API_Name__c, 
                                      (SELECT MasterLabel,Type__c,
                                       Source_Object_API_Name__c,
                                       Source_Value__c,
                                       Else_Source_Value__c,
                                       Else_Type__c,
                                       PEAK_Reference_Table__c,
                                       Rule_Type_Name__c FROM Policy_Object_Fields__r WHERE Active__c=true) 
                                      FROM Policy_Object__mdt WHERE Source_Object_API_Name__c IN :policyObjectNames AND Active__c=true])
        {
            returnList.add(mdt);
            if(policyObjects_mdt.containskey(mdt.Source_Object_API_Name__c)){
                policyObjects_mdt.get(mdt.Source_Object_API_Name__c).add(mdt);
            }else{
                policyObjects_mdt.put(mdt.Source_Object_API_Name__c, new List<Policy_Object__mdt>{mdt});
            }
        }
    }
    
    public static void insertLstSObject(List<SObject> lstSObject){
        List<Database.SaveResult> lstSaveResult= Database.insert(lstSObject,false);
        List<Id> lstIdSuccRecs = new List<Id>();
        for(Database.SaveResult saveResult:lstSaveResult){
            if(saveResult.isSuccess()){
                lstIdSuccRecs.add(saveResult.getId());
            }else{
                for(Database.Error error : saveResult.getErrors()){
                    System.debug(error.getMessage());
                }
            }
        }
    }
    
    public static Object getTypeCastedValue(String fieldType,String fieldValue){
        Object typeCastedValue =null;
        try{
            if(fieldType=='DATE'){
                typeCastedValue = Date.valueOf(fieldValue);
            }else if(fieldType=='DOUBLE'){
                typeCastedValue = Double.valueOf(fieldValue);
            }else if(fieldType=='DECIMAL'){
                typeCastedValue = DECIMAL.valueOf(fieldValue);
            }else if(fieldType=='INTEGER'){
                typeCastedValue = INTEGER.valueOf(fieldValue);
            }else if(fieldType=='BOOLEAN'){
                
                if(fieldValue=='Y'){
                    typeCastedValue = true;
                }else if(fieldValue=='N' || String.isEmpty(fieldValue) || fieldValue==null){
                    typeCastedValue = false;
                }else{
                    typeCastedValue = Boolean.valueOf(fieldValue);
                }
            }else{
                typeCastedValue = fieldValue+'';
            }
        }catch(Exception ex){
            System.debug('Type casting error:'+ex.getLineNumber()+':'+ex.getMessage());
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','APXPolicyRecordsServices');    
            exceptionMap.put('Method__c','getTypeCastedValue');            
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
        }
        return typeCastedValue;
    }
    
     public static List<SObject> createPolicyRecords(List<SObject> lstSourceObject, Boolean doDML){
        lstSObject.clear();        
        List<Policy_Object__mdt> lstPolicyObject;
        // added for CCCAP-14909
         if(policyObjects_mdt.isEmpty()){
             getPolicyObjectRecords();
         }
        String srcSObjAPIName;
        if(!lstSourceObject.isEmpty()){
            for(SObject sOb:lstSourceObject){
                srcSObjAPIName = sOb.getSObjectType()+'';
                lstPolicyObject = new List<Policy_Object__mdt>();
                lstPolicyObject = policyObjects_mdt.get(srcSObjAPIName);
                if(lstPolicyObject.isEmpty()){
                    System.debug('No PolicyObject Records Found');
                }else{
                    for(Policy_Object__mdt policyObject:lstPolicyObject){
                        if(Schema.getGlobalDescribe().containsKey(policyObject.Target_Object_API_Name__c)){
                            SObject targetSObject = Schema.getGlobalDescribe().get(policyObject.Target_Object_API_Name__c).newSObject() ;
                            for(Policy_Object_Field__mdt policyObjectField:policyObject.Policy_Object_Fields__r){
                                Object fieldValue;
                                if(Schema.getGlobalDescribe().get(policyObject.Target_Object_API_Name__c).getDescribe().fields.getMap().containsKey(policyObjectField.MasterLabel)){
                                    Schema.SObjectField field = Schema.getGlobalDescribe().get(policyObject.Target_Object_API_Name__c).getDescribe().fields.getMap().get(policyObjectField.MasterLabel);
                                    Schema.DisplayType fieldType = field.getDescribe().getType();
                                    Boolean isSourceValue = true;
                                    if(policyObjectField.Type__c=='Logic'){
                                        fieldValue = APXPolicyRecordsIfElseConditions.processRules(sOb,policyObjectField.Rule_Type_Name__c);
                                        System.debug('fieldValue after evaluating expression:'+fieldValue);
                                        if(fieldValue!=null){
                                            fieldValue = getTypeCastedValue(String.valueOf(fieldType),String.valueOf(fieldValue));
                                        }
                                    }else{
                                        if(String.isNotBlank(policyObjectField.Rule_Type_Name__c)){
                                            isSourceValue = (Boolean)APXPolicyRecordsIfElseConditions.processRules(sOb,policyObjectField.Rule_Type_Name__c);
                                        }
                                        String value,type;
                                        if(isSourceValue){
                                            value = policyObjectField.Source_Value__c;
                                            type = policyObjectField.Type__c;
                                        }else{
                                            value = policyObjectField.Else_Source_Value__c;
                                            type = policyObjectField.Else_Type__c;
                                        }
                                        if(type=='Value'){
                                            if(String.isNotBlank(value)){
                                                fieldValue = getTypeCastedValue(fieldType+'',value);
                                            }
                                        }else if(policyObjectField.Type__c=='Translate' && sOb.get(value)!=null){
                                            fieldValue = ConversionPicklistMappingUtility.translatePEAKToCHATSData(policyObjectField.PEAK_Reference_Table__c, String.valueOf(sOb.get(value)));
                                        }else{
                                            if(sOb.get(value)!=null){
                                                fieldValue = getTypeCastedValue(fieldType+'',sOb.get(value)+'');
                                            }else if(fieldType+''=='BOOLEAN' && sOb.get(value)==null){
                                                fieldValue = false;
                                            }
                                        }
                                    }
                                    targetSObject.put(policyObjectField.MasterLabel,fieldValue);
                                }else{
                                    System.debug('Field does not exist:'+policyObjectField.MasterLabel);
                                }
                            }
                            lstSObject.add(targetSObject);
                        }else{
                            System.debug('Target_Object_API_Name__c is incorrect. Please check');
                        }
                    } 
                }
                System.debug('Total Number of target object:'+lstSObject.size()+':['+lstSObject+']');
            }
            if(doDML){
                insertLstSObject(lstSObject);
            }
            return lstSObject;
        }else{
            System.debug('No Records to process');
            return null;
        }
    }
     public static List<Referral_Information__c> createRefData(String referralId,String referralType,List<SObject> lstSourceObject){    
        List<Referral_Information__c> refrenceInfoLst = new List<Referral_Information__c>();
        Map<String,Referral_Information__c> refMapToUpdate = new Map<String,Referral_Information__c>();
        Map<String,Referral_Information__c> childRefMapToUpdate = new Map<String,Referral_Information__c>();
        for(Referral_Information__c refObj : [Select id,Referral_Id__c,IDN_CLIENT__c,Referral_Type__c,ProviderId__c,Object_API_Name__c,Old_Value__c,Field_Name__c,Field_API_Name__c,CBMS_Object_Name__c,New_Value__c,isEditable__c from Referral_Information__c where Referral_Id__c=:referralId]){
            string key = refObj.Object_API_Name__c+'_'+refObj.CBMS_Object_Name__c+'_'+refObj.Field_API_Name__c;
            refMapToUpdate.put(key, refObj);
            string childKey = refObj.Referral_Id__c+'_'+refObj.IDN_CLIENT__c +'_'+refObj.ProviderId__c+'_'+refObj.Field_API_Name__c;
            childRefMapToUpdate.put(childKey, refObj);
        }
        for(SObject sOb:lstSourceObject){
            String sObjectAPIName = sOb.getSObjectType()+'';
            List<Referral_Object_Mapping__mdt> objectMappingLst =[SELECT CBMS_Object_API_Name__c,
                                                                  CHATS_Object_API_Name__c, Active__c,
                                                                  (SELECT MasterLabel,
                                                                   Field_API_Name__c,CBMS_Field_API_Name__c,
                                                                   Field_Label__c,
                                                                   Referral_Object_Mapping__c FROM Referral_Field_Mappings__r WHERE Active__c=true) FROM Referral_Object_Mapping__mdt WHERE CHATS_Object_API_Name__c = :sObjectAPIName  AND  Active__c=true];
            List<Referral_Object_Mapping__mdt> objectMappingLst1 =[SELECT CBMS_Object_API_Name__c,
                                                                  CHATS_Object_API_Name__c, Active__c,
                                                                  (SELECT MasterLabel,
                                                                   Field_API_Name__c,CBMS_Field_API_Name__c,
                                                                   Field_Label__c,
                                                                   Referral_Object_Mapping__c FROM Referral_Field_Mappings__r WHERE Active__c=true) FROM Referral_Object_Mapping__mdt WHERE  CBMS_Object_API_Name__c = :sObjectAPIName  AND  Active__c=true];
            objectMappingLst.addAll(objectMappingLst1);
            if(objectMappingLst != null && objectMappingLst.size()>0){
                for(Referral_Object_Mapping__mdt obj:objectMappingLst){
                    for(Referral_Field_Mappings__mdt policyObjectField:obj.Referral_Field_Mappings__r){
                        String value;
                        if(policyObjectField.Field_API_Name__c != null){
                                if(policyObjectField.Field_API_Name__c  =='NET_EARNED_INCOME__c'){
                                 value = String.valueOf(sOb.get('AMT_TANF_INCOME_HH_GROSS__c'));
                            }else{
                                value = String.valueOf(sOb.get(policyObjectField.Field_API_Name__c));
                            }
                            }else if(policyObjectField.CBMS_Field_API_Name__c != null){
                              value = String.valueOf(sOb.get(policyObjectField.CBMS_Field_API_Name__c));  
                            }
                        String fieldAPIName=policyObjectField.Field_API_Name__c;
                        IF(policyObjectField.Field_API_Name__c ==null){
                            fieldAPIName = policyObjectField.CBMS_Field_API_Name__c;
                        }
                        string keyStr =obj.CHATS_Object_API_Name__c+'_'+obj.CBMS_Object_API_Name__c+'_'+fieldAPIName;
                        Referral_Information__c refObj = refMapToUpdate.get(keyStr);
                        if(refObj!= null && obj.CBMS_Object_API_Name__c =='T_APPLN_CHILD_CARE__c'){
                            string childKey = refObj.Referral_Id__c+'_'+String.valueOf(sOb.get('IDN_CLIENT__c')) +'_'+String.valueOf(sOb.get('IDN_CBMS_PROVR__c'))+'_'+refObj.Field_API_Name__c;
                           // string childKey = refObj.Referral_Id__c+'_'+String.valueOf(sOb.get('IDN_CLIENT__c'))+'_'+refObj.Field_API_Name__c;
                            if(obj.CBMS_Object_API_Name__c =='T_APPLN_CHILD_CARE__c'){
                                refObj = childRefMapToUpdate.get(childKey);
                            }  
                        }
                        if(refObj== null){
                            refObj = new Referral_Information__c();
                            refObj.Referral_Id__c=referralId;
                            refObj.SF_Record_Id__c	=String.valueOf(sOb.get('Id'));
                            refObj.Referral_Type__c=referralType;
                            if(policyObjectField.Field_API_Name__c != null){
                                refObj.isEditable__c = true;
                            }else{
                               refObj.isEditable__c = false; 
                            }
                            if( sObjectAPIName=='T_APPLN_CHILD_CARE__c'){
                                refObj.IDN_CLIENT__c = String.valueOf(sOb.get('IDN_CLIENT__c'));
                                refObj.ProviderId__c = String.valueOf(sOb.get('IDN_CBMS_PROVR__c'));
                            }
                            if(obj.CBMS_Object_API_Name__c != null){
                                refObj.CBMS_Object_Name__c=obj.CBMS_Object_API_Name__c;
                            }
                             if(obj.CHATS_Object_API_Name__c != null){
                                refObj.Object_API_Name__c=obj.CHATS_Object_API_Name__c;
                            }
                            refObj.Old_Value__c=value;
                            if(policyObjectField.Field_API_Name__c != null){
                                refObj.Field_API_Name__c=policyObjectField.Field_API_Name__c;
                            }else if(policyObjectField.CBMS_Field_API_Name__c != null){
                              refObj.Field_API_Name__c=policyObjectField.CBMS_Field_API_Name__c;  
                            }
                            refObj.Field_Name__c=policyObjectField.Field_Label__c;
                            refrenceInfoLst.add(refObj);
                        }else{
                            refObj.New_Value__c=value;
                            refrenceInfoLst.add(refObj);
                            
                        }
                        
                    }   
                } 
            }
        }
        system.debug('refrenceInfoLst---'+refrenceInfoLst);
        if(refrenceInfoLst.size()>0){
            updateLstSObject(refrenceInfoLst);
        }
        return  refrenceInfoLst;
    }
    public static List<Referral_Information__c> updateRefDataIncome(String referralId,List<SObject> lstSourceObject){    
        List<Referral_Information__c> refrenceInfoLst = new List<Referral_Information__c>();
        Map<String,Referral_Information__c> refMapToUpdate = new Map<String,Referral_Information__c>();
        Map<String,Referral_Information__c> childRefMapToUpdate = new Map<String,Referral_Information__c>();
        for(Referral_Information__c refObj : [Select id,IDN_CLIENT__c,Referral_Id__c,Referral_Type__c,Object_API_Name__c,Old_Value__c,Field_Name__c,Field_API_Name__c,CBMS_Object_Name__c,New_Value__c,isEditable__c from Referral_Information__c where Referral_Id__c=:referralId and Field_API_Name__c=:'NET_EARNED_INCOME__c']){
            if(refObj.SF_Record_Id__c == null){
                refObj.SF_Record_Id__c = String.valueOf(lstSourceObject[0].get('Id'));
                refrenceInfoLst.add(refObj);
            }
        }
        if(refrenceInfoLst.size()>0){
            updateLstSObject(refrenceInfoLst);
        }
        return  refrenceInfoLst;
    }
     public static List<Referral_Information__c> updateRefData(String referralId,List<SObject> lstSourceObject){    
        Map<Id,Referral_Information__c> refrenceInfoLst = new Map<Id,Referral_Information__c>();
        Map<String,List<Referral_Information__c>> refMapToUpdate = new Map<String,List<Referral_Information__c>>();
        Map<String,List<Referral_Information__c>> childRefMapToUpdate = new Map<String,List<Referral_Information__c>>();
        for(Referral_Information__c refObj : [Select id,IDN_CLIENT__c,Referral_Id__c,Referral_Type__c,ProviderId__c,Object_API_Name__c,Old_Value__c,Field_Name__c,Field_API_Name__c,CBMS_Object_Name__c,New_Value__c,isEditable__c from Referral_Information__c where Referral_Id__c=:referralId]){
            string key = refObj.Object_API_Name__c+'_'+refObj.CBMS_Object_Name__c+'_'+refObj.Field_API_Name__c;
            List<Referral_Information__c> refs = new List<Referral_Information__c>();
            if(refMapToUpdate.containsKey(key)){
                refs = refMapToUpdate.get(key);
            }
            refs.add(refObj);
            refMapToUpdate.put(key, refs);
            string childKey = refObj.Referral_Id__c+'_'+refObj.IDN_CLIENT__c +'_'+refObj.ProviderId__c+'_'+refObj.Field_API_Name__c;
            refs = new List<Referral_Information__c>();
            if(childRefMapToUpdate.containsKey(childKey)){
                refs = childRefMapToUpdate.get(childKey);
            }
            refs.add(refObj);
            childRefMapToUpdate.put(childKey, refs);
            //change start for CCCAP-11072
            refs = new List<Referral_Information__c>();
            string provKey = refObj.Referral_Id__c+'_'+refObj.IDN_CLIENT__c +'_'+refObj.Field_API_Name__c; 
            if(childRefMapToUpdate.containsKey(provKey)){
                refs = childRefMapToUpdate.get(provKey);
            }
            refs.add(refObj);
            childRefMapToUpdate.put(provKey, refs);
            //change end for CCCAP-11072
        }
        for(SObject sOb:lstSourceObject){
            String sObjectAPIName = sOb.getSObjectType()+'';
            List<Referral_Object_Mapping__mdt> objectMappingLst =[SELECT CBMS_Object_API_Name__c,
                                                                  CHATS_Object_API_Name__c, Active__c,
                                                                  (SELECT MasterLabel,
                                                                   Field_API_Name__c,CBMS_Field_API_Name__c,
                                                                   Field_Label__c,
                                                                   Referral_Object_Mapping__c FROM Referral_Field_Mappings__r WHERE Active__c=true) FROM Referral_Object_Mapping__mdt WHERE CBMS_Object_API_Name__c = :sObjectAPIName AND  Active__c=true];
            if(objectMappingLst != null && objectMappingLst.size()>0){
                for(Referral_Object_Mapping__mdt obj:objectMappingLst){
                    for(Referral_Field_Mappings__mdt policyObjectField:obj.Referral_Field_Mappings__r){
                        String value ='';
                        if(policyObjectField.CBMS_Field_API_Name__c !='CDE_TYPE_INFO_CASE__c' && policyObjectField.Field_API_Name__c !='CDE_TYPE_INFO_CASE__c'){
                            if(policyObjectField.CBMS_Field_API_Name__c != null){
                                if(policyObjectField.CBMS_Field_API_Name__c =='CDE_COUNTY__c'){
                                    if(sOb.get(policyObjectField.Field_API_Name__c) != null){
                                   Decimal countyCode = Decimal.valueOf(String.valueOf(sOb.get(policyObjectField.Field_API_Name__c)));
                                    List<T_County__c> lstCounty = [SELECT Id,(SELECT Id,ADR_LINE_1__c,ADR_LINE_2__c,ADR_CITY__c,ADR_STATE__c,ADR_ZIP__c,ADR_ZIP_EXTN__c, Record_Type_Name__c FROM County3__r WHERE Record_Type_Name__c IN ('Mailing','Main_Location')) FROM T_County__c WHERE CDE_COUNTY__c =:countyCode];
                                    if(!lstCounty.isEmpty()){
                                        value= String.valueOf(lstCounty.get(0).Id);
                                    }
                                    }
                                }else{
                                    value= String.valueOf(sOb.get(policyObjectField.CBMS_Field_API_Name__c));
                                }
                                
                            }else{
                                value= String.valueOf(sOb.get(policyObjectField.Field_API_Name__c));
                            }  
                        }
                        string fieldAPIName = policyObjectField.Field_API_Name__c!=null?policyObjectField.Field_API_Name__c:policyObjectField.CBMS_Field_API_Name__c;
                        string keyStr =obj.CHATS_Object_API_Name__c+'_'+obj.CBMS_Object_API_Name__c+'_'+fieldAPIName;
                        if(refMapToUpdate.containsKey(keyStr)){
                            for(Referral_Information__c refObj : refMapToUpdate.get(keyStr)){
                                string childKey,provKey;
                                if(refObj != null && obj.CBMS_Object_API_Name__c =='T_APPLN_CHILD_CARE__c'){
                                    childKey = refObj.Referral_Id__c+'_'+String.valueOf(sOb.get('IDN_CLIENT__c')) +'_'+String.valueOf(sOb.get('IDN_CBMS_PROVR__c'))+'_'+refObj.Field_API_Name__c;
                                    provKey = refObj.Referral_Id__c+'_'+String.valueOf(sOb.get('IDN_CLIENT__c'))+'_'+refObj.Field_API_Name__c;
                                    if(childRefMapToUpdate.containsKey(childKey)){
                                        for(Referral_Information__c refObj1 : childRefMapToUpdate.get(childKey)){
                                            if(refObj1!= null){
                                                refObj1.New_Value__c=value;
                                                refrenceInfoLst.put(refObj1.Id,refObj1);
                                            }        
                                        }  
                                    }//change start for CCCAP-11072
                                    else if(childRefMapToUpdate.containsKey(provKey) && refObj.ProviderId__c!=String.valueOf(sOb.get('IDN_CBMS_PROVR__c'))){
                                        for(Referral_Information__c refObj1 : childRefMapToUpdate.get(provKey)){
                                            if(refObj1!= null){
                                                refObj1.New_Value__c=value;
                                                refObj1.ProviderId__c = String.valueOf(sOb.get('IDN_CBMS_PROVR__c'));
                                                refrenceInfoLst.put(refObj1.Id,refObj1);
                                            }
                                        }
                                    }//change end for CCCAP-11072   
                                }
                                else if(refObj!= null && obj.CBMS_Object_API_Name__c == 'T_APPLN_CASE__c'){
                                    refObj.New_Value__c=value;
                                    system.debug('value---'+value);
                                    system.debug('policyObjectField.Field_Label__c---'+policyObjectField.Field_Label__c);
                                    refrenceInfoLst.PUT(refObj.ID,refObj);
                                }
                            }   
                        }
                    }
                } 
            }
        }
        system.debug('refrenceInfoLst---'+refrenceInfoLst);
        if(refrenceInfoLst.size()>0){
            updateLstSObject(refrenceInfoLst.values());
        }
        return  refrenceInfoLst.values();
    }
    public static void updateLstSObject(List<SObject> lstSObject){
        List<Database.upsertResult> lstSaveResult= Database.upsert(lstSObject,false);
        List<Id> lstIdSuccRecs = new List<Id>();
        for(Database.upsertResult saveResult:lstSaveResult){
            if(saveResult.isSuccess()){
                lstIdSuccRecs.add(saveResult.getId());
            }else{
                for(Database.Error error : saveResult.getErrors()){
                    System.debug(error.getMessage());
                }
            }
        }
    }
}