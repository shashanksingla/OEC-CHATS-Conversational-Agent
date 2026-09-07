public with sharing class DynamicFormGenerationController implements IRequest{
    public class customException extends Exception {}
    public static final String CLOSED = 'CLS';
    public String jsonParam;
    private static Map<String, Object > requestObj;
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }      
        if (methodName == 'fetchUserdata') {
            response = fetchUserdata();
        } else if(methodName == 'getFieldDefinition'){
            List<Object> objList = (List<Object>)requestObj.get('lstObjectToField');
            List<String> objectFieldList = new List<String>();
            for(Object obj : objList){
                objectFieldList.add((String)obj);
            }
            response = getFieldDefinition(objectFieldList);
        } else if(methodName == 'getDataOnLoadInCHATS'){
            response = getDataOnLoadInCHATS(getMapValue('fieldList'), (Id)requestObj.get('sObjectId'), getMapValue('objectName'));
        } else if (methodName == 'newFiscalAgreement'){
            response = newFiscalAgreement(getMapValue('providerId'), (Boolean)requestObj.get('isUpdate'));
        } else if (methodName =='checkCountyWithOwnerCounty'){
            response = checkCountyWithOwnerCounty(getMapValue('countyId'), getMapValue('ownerId'));
        } else if (methodName == 'checkCountyWithUserCounty'){
            response = checkCountyWithUserCounty(getMapValue('countyId'));
        } else if (methodName == 'fiscalCountyValidation'){
            response = fiscalCountyValidation(getMapValue('fiscalAgreementId'));
        } else if (methodName == 'SCfiscalCountyValidation'){
            response = SCfiscalCountyValidation(getMapValue('slotContractId'));
        } else if (methodName == 'closeFiscalAgreementUpdate'){
            response = closeFiscalAgreementUpdate(getMapValue('fisacalAgrRecordId'), getMapValue('endDate'), getMapValue('reasonOfClosure'), getMapValue('fiscalAgreementStatus'));
        } else if (methodName == 'closeSCAddendumUpdate'){
            response = closeSCAddendumUpdate(getMapValue('SCRecordId'), getMapValue('endDate'), getMapValue('reasonOfClosure'));
        } else if (methodName == 'validateIndivAge'){
            List<Object> rawList = (List<Object>)requestObj.get('caseIndivList');
            String sObjJson = JSON.serialize(rawList);
            List<T_SBSD_CASE_INDIV__c> caseIndivList = (List<T_SBSD_CASE_INDIV__c>)JSON.deserialize(sObjJson, List<T_SBSD_CASE_INDIV__c>.class);
            response = validateIndivAge(caseIndivList);
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }

    @AuraEnabled
    public static LightningServerResponse fetchUserdata(){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        //Only checking for System Administrator in overrideFiscalAgreementUpsert_lwc
        List<Profile> profiles = [select Name from profile where id = :Userinfo.getProfileId()]; 
        if(!profiles.isEmpty()){
            objectData.put('userProfileName', profiles.get(0).Name);
        }
        objectData.put('userName', Userinfo.getUserName());
        return new LightningServerResponse(isSuccessful,message, objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse checkCountyWithUserCounty(String countyId){
        T_COUNTY__c county = [Select Name from T_COUNTY__c where Id =:countyId limit 1];
        return new LightningServerResponse(true,null, new Map<String,Object>{'countyMatched'=>CHATSUtility.checkCountyWithUserCounty(countyId), 'countyName'=>county.Name});
    }
    
    @auraEnabled
    public static LightningServerResponse fiscalCountyValidation(String fiscalAgreementId){
        T_PROVR_FISCAL_AGREMENT__c fa = [Select CDE_COUNTY__c, CDE_COUNTY__r.Name from T_PROVR_FISCAL_AGREMENT__c where Id =:fiscalAgreementId limit 1];
        return new LightningServerResponse(true,null, new Map<String,Object>{'countyMatched'=>CHATSUtility.checkCountyWithUserCounty(fa.CDE_COUNTY__c), 'countyName'=>fa.CDE_COUNTY__r.Name});
    }
    @auraEnabled
    public static LightningServerResponse SCfiscalCountyValidation(String slotContractId){
        T_SLOT_CONTRACT_ADDENDUM__c fa = [Select CDE_COUNTY__c, CDE_COUNTY__r.Name from T_SLOT_CONTRACT_ADDENDUM__c where Id =:slotContractId limit 1];
        return new LightningServerResponse(true,null, new Map<String,Object>{'countyMatched'=>CHATSUtility.checkCountyWithUserCounty(fa.CDE_COUNTY__c), 'countyName'=>fa.CDE_COUNTY__r.Name});
    }

    @auraEnabled
    public static LightningServerResponse checkCountyWithOwnerCounty(String countyId, String ownerId){
        Boolean countyMatched = true;
        Boolean ownerCountyMatched = true;
        Map<Id, User> userMap = new Map<Id, User>([SELECT Owner_County__c, Common_County__c 
                                                     FROM User WHERE Id = :UserInfo.getUserId() OR Id = :ownerId]);
        
        // CCCAP-14993 Using permission set
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId(), ownerId};
        Set<String> bypassPermissionSets = new Set<String>{'System_Administrator_PS', 'CCCAP_Program_Internal_Team'};
        Map<Id, Set<String>> userPermissionSetMap = new Map<Id, Set<String>>();
        
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name 
                                            FROM PermissionSetAssignment 
                                            WHERE AssigneeId IN :userIds 
                                            AND PermissionSet.Name IN :bypassPermissionSets]){
        if (!userPermissionSetMap.containsKey(psa.AssigneeId)) {
            userPermissionSetMap.put(psa.AssigneeId, new Set<String>());
    }
        userPermissionSetMap.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }
        
        List<T_COUNTY__c> counties1 = [SELECT Name, CDE_COUNTY__c FROM T_COUNTY__c WHERE Id = :countyId];
        String countyName = '';
        if(!counties1.isEmpty()){
            String county = String.valueOf(counties1.get(0).CDE_COUNTY__c); 
            countyName = counties1[0].Name;
            
            // Check if owner has bypass permission sets - if NOT in map, they don't have bypass permissions
            if(!userPermissionSetMap.containsKey(ownerId)){
                // Owner does NOT have System_Administrator_PS or CCCAP_Program_Internal_Team - check county match
                ownerCountyMatched = false;            
                User user = userMap.get(ownerId);
                if(user != null && (user.Owner_County__c == county || (user.Common_County__c != null && new Set<String>(user.Common_County__c.split(';')).contains(county)))){
                    ownerCountyMatched = true;
                }                
            }
            
            // Check if current user has bypass permission sets - if NOT in map, they don't have bypass permissions
            if(!userPermissionSetMap.containsKey(UserInfo.getUserId())){
                // Current user does NOT have System_Administrator_PS or CCCAP_Program_Internal_Team - check county match
                countyMatched = false; 
                User user = userMap.get(UserInfo.getUserId());
                if(user != null && (user.Owner_County__c == county || (user.Common_County__c != null && new Set<String>(user.Common_County__c.split(';')).contains(county)))){
                    countyMatched = true;
                }                
            }
            if(UserInfo.getUserId() == ownerId && countyMatched == false){
                ownerCountyMatched = true;
            }
        }
        
        return new LightningServerResponse(true, null, new Map<String,Object>{'ownerCountyMatched'=>ownerCountyMatched, 
            																  'countyMatched'=>countyMatched,
            																  'countyName'=>countyName});
    }
    
    @AuraEnabled
    public static List<FieldInformationWrapper.fieldDefinition> getFieldDefinition(List<String> lstObjectToField) {
        Map<String, List<String>> objectToFieldMapping = new Map<String, List<String>>();
        //create map of objects to fields
        System.debug(lstObjectToField);
        String objName;
        String fieldName;
        List<String> lstOfFieldNames;
        if(lstObjectToField.size()>0) {
            for(String eachObjectToField : lstObjectToField) {
                objName = eachObjectToField.substringBefore('.');
                fieldName = eachObjectToField.substringAfter('.');
                System.debug(objName);
                System.debug(fieldName);
                objName = objName.trim().replaceAll('"', '');
                fieldName = fieldName.trim().replaceAll('"', '');
                lstOfFieldNames = new List<String>();
                if(objectToFieldMapping.containsKey(objName)) {
                    lstOfFieldNames = objectToFieldMapping.get(objName);
                    lstOfFieldNames.add(fieldName);
                    objectToFieldMapping.remove(objName);
                } else {
                    lstOfFieldNames.add(fieldName);
                }
                System.debug(lstOfFieldNames);
                objectToFieldMapping.put(objName, lstOfFieldNames);
            }    
        }
        List<FieldInformationWrapper.fieldDefinition> lstOfObjectToFieldDefinition = new List<FieldInformationWrapper.fieldDefinition>();
        
        if(objectToFieldMapping.size()>0) {
            List<FieldInformationWrapper.fieldDefinition> fieldDefinition;
            for(String eachObject : objectToFieldMapping.keySet()) {
                //get field definition
                fieldDefinition  = new List<FieldInformationWrapper.fieldDefinition>();
                fieldDefinition = CHATSUtility.getFieldDefinition(eachObject,objectToFieldMapping.get(eachObject));
                lstOfObjectToFieldDefinition.addAll(fieldDefinition);
            }
        }
        System.debug(lstOfObjectToFieldDefinition);
        return lstOfObjectToFieldDefinition;
    }

    
    @AuraEnabled
    public static SObject getDataOnLoadInCHATS(String fieldList, Id sObjectId, String objectName) {
        List<FieldInformationWrapper.fieldDefinition> listOfFields = (List<FieldInformationWrapper.fieldDefinition>)JSON.deserialize(String.escapeSingleQuotes(fieldList), List<FieldInformationWrapper.fieldDefinition>.class);
        SObject sOb;
        
        //get parent object name
        String parentObjectName = null;
        if(String.isNotEmpty(sObjectId)){
            parentObjectName = (String.escapeSingleQuotes(String.valueOf(sobjectId.getsobjecttype())));
            
        }
        //get object to field mapping
        if(listOfFields.size()>0) {
            String dynamicQuery = 'SELECT Id';
            for(FieldInformationWrapper.fieldDefinition eachFieldDefinition : listOfFields) {
                dynamicQuery += ', '+eachFieldDefinition.fieldAPIName; 
            }
            dynamicQuery += ' FROM '+parentObjectName + ' WHERE';
            dynamicQuery +=  ' Id = \''+string.escapeSingleQuotes(sObjectId)+'\'';
            List<sObject> sObjects = Database.query(dynamicQuery);
            if(!sObjects.isEmpty()){
                sOb = sObjects.get(0);
            }
        }
        return sOb;
    }
	
	@AuraEnabled
    public static LightningServerResponse newFiscalAgreement(String providerId, Boolean isUpdate){
        List<T_CHATS_PROVR_STATUS__c> providerRecords= [SELECT Id,CDE_COUNTY_OWNER__c FROM T_CHATS_PROVR_STATUS__c WHERE Id = :providerId AND (CDE_STATUS_PROVR__c = 'OPEN' OR (CDE_STATUS_PROVR__c='Pending' and DTE_BEGIN_EFFV__c!=null))];
        Boolean canCreateNewAgreement = false;
        if(!providerRecords.isEmpty() || isUpdate){
           canCreateNewAgreement = true;
        }
        if(canCreateNewAgreement){
                         
            return new LightningServerResponse(true, null, null);
        }else{
            return new LightningServerResponse(false, Label.NEW_PROVR_FISCAL_AGREEMENT_ERROR, null);
        }
    } 
    
    @AuraEnabled
    public static Boolean closeFiscalAgreementUpdate(String fisacalAgrRecordId, String endDate, String reasonOfClosure, String fiscalAgreementStatus){
        Boolean updateDone = False;
        Set<Id> serviceIds = new Set<Id>();
        Set<Id> countyIds = new Set<Id>();
        List<T_PROVR_FISCAL_AGREMENT__c> updatedfiscalAgrRecList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        try{
            Id closedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
            List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrRecList=[Select Id,ID_SERVICE__c,CDE_COUNTY__c,DTE_BEGIN_AGRMT__c,DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id=:fisacalAgrRecordId and ID_SERVICE__c!=null and CDE_COUNTY__c!=null Limit 1];
            if(fiscalAgrRecList.size()>0) {
                for(T_PROVR_FISCAL_AGREMENT__c FAEach:fiscalAgrRecList) {
                    serviceIds.add(FAEach.ID_SERVICE__c);
                    countyIds.add(FAEach.CDE_COUNTY__c);
                }
                List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrRecListExisting=[Select Id,DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id !=:fisacalAgrRecordId and ID_SERVICE__c IN:serviceIds and CDE_COUNTY__c IN:countyIds and DTE_BEGIN_AGRMT__c>Today Limit 1]; 
                if(!(fiscalAgrRecListExisting.size()>0)) {
                    for(T_PROVR_FISCAL_AGREMENT__c fiscalAgmnt:fiscalAgrRecList) { 
                    	fiscalAgmnt.CDE_REASON_END_AGRMT__c = reasonOfClosure;
                    	fiscalAgmnt.DTE_END_AGRMT__c = date.valueof(endDate);   
                        if(fiscalAgmnt.DTE_END_AGRMT__c == system.today() || fiscalAgmnt.DTE_END_AGRMT__c < system.today()){
                        fiscalAgmnt.CDE_TYPE_STATUS__c='CLS';
                        fiscalAgmnt.RecordTypeId=closedRecordTypeId;
                        }
                    }
                    update fiscalAgrRecList;
                    updateDone = true;
                }else {
                    updateDone = false;
                }
            }
        }
        catch(Exception ex){ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'DynamicFormGenerationController','Method__c'=>'CloseFiscalAgreementUpdate'});
        }
        return updateDone;
    }
    @AuraEnabled
    public static Boolean closeSCAddendumUpdate(String SCRecordId, String endDate, String reasonOfClosure){
        Boolean updateDone = False;
        Savepoint sp = Database.setSavepoint();
        List<T_SLOT_CONTRACT_ADDENDUM__c>SCAddRecListone=new List<T_SLOT_CONTRACT_ADDENDUM__c>();
        try{ 
            List<T_SLOT_CONTRACT_ADDENDUM__c> SCAddRecList=[Select Id,CDE_COUNTY__c,DTE_BEGIN_ADDENDUM__c,DTE_END_ADDENDUM__c from T_SLOT_CONTRACT_ADDENDUM__c where Id=:SCRecordId AND CDE_COUNTY__c!=null Limit 1];
            if(SCAddRecList.size()>0) {
                for(T_SLOT_CONTRACT_ADDENDUM__c SCEach:SCAddRecList) {
                    SCEach.DTE_END_ADDENDUM__c = date.valueof(endDate);
                    SCEach.CDE_REASON_END_ADDENDUM__c = reasonOfClosure;
                    SCAddRecListone.add(SCEach);
                    
                }
                update SCAddRecListone;
                updateDone = true;
            }    
            else {
                updateDone = false;
            }
            if(updateDone==true)
            {
                updateRelatedSlot(SCRecordId,endDate);
            }
        }
        catch(Exception ex){
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'DynamicFormGenerationController','Method__c'=>'CloseFiscalAgreementUpdate'});
            updateDone = false;
        }
        return updateDone;
    }
    public static void updateRelatedSlot(String SCRecordId,String endDate)
    {
        Date endDt=date.valueOf(endDate);
        List<T_SLOT_CONTRACT__c> slotList=[SELECT DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IDN_ADDENDUM__c, Id FROM T_SLOT_CONTRACT__c where IDN_ADDENDUM__c=:SCRecordId];
   		List<T_SLOT_CONTRACT__c> toUpdate=new List<T_SLOT_CONTRACT__c>();
        List<T_SLOT_CONTRACT__c> toDelete=new List<T_SLOT_CONTRACT__c>();
        if(slotList.size()>0)
        {
            for(T_SLOT_CONTRACT__c indiSlot: slotList)
            {
                if(indiSlot.DTE_END_SLOT__c>endDt && indiSlot.DTE_BEGIN_SLOT__c<=endDt)
                {
                  indiSlot.DTE_END_SLOT__c=endDt;
                  toUpdate.add(indiSlot);
                }else if(indiSlot.DTE_END_SLOT__c>endDt && indiSlot.DTE_BEGIN_SLOT__c>endDt)
                {
                    toDelete.add(indiSlot);
                }
            }
            if(!toUpdate.isEmpty()){
                if(Schema.sObjectType.T_SLOT_CONTRACT__c.isUpdateable()){
                    update toUpdate;
                }else{
                    throw new customException('Insufficient object-level Update permission');
                }                
            }
            if(toDelete.size()>0)
            {
                if(Schema.sObjectType.T_SLOT_CONTRACT__c.isDeletable()){
	                SlotContractUtility.ALLOW_DELETE=true;
                    delete toDelete;
                }else{
                    throw new customException('Insufficient object-level delete permission');
                }
            }
        }
    }
    @AuraEnabled
    public static LightningServerResponse validateIndivAge(List<T_SBSD_CASE_INDIV__c> caseIndivList){
        Map<String,String> caseIndivMap = new Map<String,String>();
        Map<String,Boolean> indivMap = new Map<String,Boolean>();
        Set<ID> caseIds = new Set<Id>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        Boolean teenParent = false;
        Date nullDate;
        try{
            for( T_SBSD_CASE_INDIV__c caseIndiv :caseIndivList){
            if(caseIndiv.IND_CRTKR__c){
                caseIndivMap.put(caseIndiv.id,caseIndiv.IDN_CLIENT__c);
                caseIds.add(caseIndiv.IDN_CASE__c);
            }
            
        }
        
        
        for(T_SBSD_CASE_INDIV__c caseInd : [Select id from T_SBSD_CASE_INDIV__c where IDN_CASE__c IN:caseIds AND IND_CRTKR__c = True 
                                                     AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY)]){
                                                         objectData.put('primaryCareTakerExist',true);
                                                         
            
        }
        for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id, IDN_CLIENT__c, 
                                         IDN_CLIENT__r.NAM_LAST__c,
                                         IDN_CLIENT__r.NAM_FIRST__c, 
                                         IDN_CLIENT__r.IDN_STATE__c, 
                                         IDN_CLIENT__r.Age__c,
                                         (SELECT Id, DTE_END_EFFV__c FROM Child_Care_Requests__r ORDER BY DTE_BEGIN_EFFV__c DESC)
                                         FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN :caseIds AND IDN_CLIENT__r.Age__c <: Integer.valueOf(System.Label.Teen_Parent_Age_Limit) 
                                         AND IDN_CLIENT__r.Has_Allowed_Relationship__c = false and id IN:caseIndivMap.keySet()
                                         AND IND_CRTKR__c = false AND (DTE_END_EFFV__c=:nullDate OR DTE_END_EFFV__c >= Today)]){
                                             objectData.put('IndivAgeLessThan21',true);
                                             isSuccessful = false;
                                             
                                         }
       
       
        }catch(Exception ex){
            
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
       
    }
}