public with sharing class dynamicPicklistApexController {
    @auraEnabled
    public static List<PicklistEntryDefinition> getPicklistValues(string picklistType,map<string,string> keyParams){
        List<PicklistEntryDefinition> values = new List<PicklistEntryDefinition>();
        
        if(picklistType == 'GlobalPicklist'){
            values = getGlobalPicklist(picklistType, keyParams);
        }else if(picklistType =='TableFetchPicklist') {
            string method = keyParams.get('method');
            if(method == 'getManualCorrespondences'){
                values = getManualCorrespondences(picklistType, keyParams);    
            }else if(method =='getSystemCorrespondences'){
                values = getSystemCorrespondences(picklistType, keyParams);
            }else if(method == 'getAllCorrespondences'){
                values = getAllCorrespondences(picklistType, keyParams);
            }else if(method == 'getCountyCode'){
                values = getCountyCode(keyParams);
            }
        }
        return values;    
    }

    public class PicklistEntryDefinition implements Comparable {
        @AuraEnabled
        public String label {get; private set;}
        @AuraEnabled
        public String value {get; private set;}
        @AuraEnabled
        public Boolean isDefaultValue {get; private set;}

        public PicklistEntryDefinition(Schema.PicklistEntry p) {
            label = p.getLabel();
            value = p.getValue();
            isDefaultValue = p.isDefaultValue();
        }
        public PicklistEntryDefinition(string lbl, string val, boolean isDefaultVal) {
            label = lbl;
            value = val;
            isDefaultValue = isDefaultVal;
        }    
        public Integer compareTo(Object compareTo){
        /*
        *@description This method is responsible for comparing the picklist values for the field mentioned to the ones present in the system
        * @param String which is the Object Api Name
        * @return 0 if values are equal.
        */
            PicklistEntryDefinition compareToPL = (PicklistEntryDefinition)compareTo; 
            if (value == compareToPL.value){
                return 0;   
            }
              
            if (value > compareToPL.value){
                 return 1;
            }
                 
            return -1; 
        }
    }
    
    public static List<PicklistEntryDefinition> getGlobalPicklist(string picklistType,map <string,string> keyParams) {
        List<PicklistEntryDefinition> globalPickResult = new List<PicklistEntryDefinition>();
       
        string objectName = keyParams.get('objectName');
        string fieldName = keyParams.get('fieldName');
        List<Schema.PicklistEntry> ple = (Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues());
        for (Schema.PicklistEntry f: ple) {
            PicklistEntryDefinition p = new PicklistEntryDefinition(f);
            globalPickResult.add(p);
        }
        return globalPickResult;
    }
    public static List<PicklistEntryDefinition> getManualCorrespondences(string picklistType, map<string, string> keyParams){
        List<PicklistEntryDefinition> manualCorspdResult = new List<PicklistEntryDefinition>();
        //Removed unused variable on 5/14/2018 BG  
        list<T_DOC_RSN__c> res = [select NME_CORSPD__c, toLabel(NME_CORSPD__c) labelValue  from T_DOC_RSN__c where Is_Manual__c = true order by NME_CORSPD__c];
        
        for(T_DOC_RSN__c ls: res){
            PicklistEntryDefinition p = new PicklistEntryDefinition((string)ls.get('labelValue'),ls.NME_CORSPD__c,false);
            manualCorspdResult.add(p);
        }
        return manualCorspdResult;
    }
    
    public static List<PicklistEntryDefinition> getSystemCorrespondences(string picklistType, map<string, string> keyParams){
        List<PicklistEntryDefinition> systemCorspdResult = new List<PicklistEntryDefinition>();
        list<T_DOC_RSN__c> res = [select NME_CORSPD__c, toLabel(NME_CORSPD__c) labelValue from T_DOC_RSN__c where Is_Manual__c = false order by NME_CORSPD__c];
        for(T_DOC_RSN__c ls: res){
            PicklistEntryDefinition p = new PicklistEntryDefinition((string)ls.get('labelValue'),ls.NME_CORSPD__c,false);
            systemCorspdResult.add(p);
        }
        system.debug('systemCorspdResult-->' + systemCorspdResult);
        return systemCorspdResult;
    }
    
    public static List<PicklistEntryDefinition> getAllCorrespondences(string picklistType, map<string, string> keyParams){
        List<PicklistEntryDefinition> allCorspdResult = new List<PicklistEntryDefinition>();
        list<T_DOC_RSN__c> res = [select NME_CORSPD__c, toLabel(NME_CORSPD__c) labelValue, Is_Manual__c, Name, CDE_TYPE_RCPT__c, CND_TRIGR__c from T_DOC_RSN__c order by NME_CORSPD__c limit 100];
        string keyColName = keyParams.get('keyColName');        
        string valueColName = keyParams.get('valueColName');
        string colName;
        string valName;
        for(T_DOC_RSN__c ls: res){
            colName='';//ls.NME_CORSPD__c; 
            valName='';//ls.Name;
            if(String.isBlank(keyColName) ){
                colName = (string)ls.get('labelValue'); //ls.NME_CORSPD__c;
            }else {
                string cName = (string)ls.get(keyColName);
                colName = cName;
            }
            
            if(String.isBlank(valueColName) ){
                valName = ls.NME_CORSPD__c;
            }else {
                string vName = (string)ls.get(valueColName);
                colName = vName;
            }
            PicklistEntryDefinition p = new PicklistEntryDefinition(colName,valName,false);
            allCorspdResult.add(p);    
            }
        return allCorspdResult;
    }  
    
    public static List<PicklistEntryDefinition> getCountyCode(){
        list<T_COUNTY__c> res = [select Id, Name from T_COUNTY__c order by Name limit 100];     
        List<PicklistEntryDefinition> countyCodeResult = new List<PicklistEntryDefinition>();
        for(T_COUNTY__c countyList: res){
            PicklistEntryDefinition p = new PicklistEntryDefinition(countyList.Name,countyList.Id,false);
            countyCodeResult.add(p);
        }
        return countyCodeResult;
    }  
    
    public static List<PicklistEntryDefinition> getCountyCode(Map<String, String> keyParams){
        list<T_COUNTY__c> res;
        User user = [SELECT Profile.Name, Owner_County__c, Common_County__c 
                     FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
         //CCCAP-14993            
        if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team') && keyParams.containsKey('userRestriction')
            && keyParams.get('userRestriction') == 'true') {
                list<Decimal> countyCodeList = new list<Decimal>();
                if(string.isNotBlank(user.Owner_County__c)){
                    countyCodeList.add(Decimal.valueOf(user.Owner_County__c));            
                }                
                if(string.isNotBlank(user.Common_County__c)){
                    List<String> commonCountyValues = user.Common_County__c.split(';');
                    for(String countyValue : commonCountyValues){
                        if(String.isNotBlank(countyValue)){
                            countyCodeList.add(Decimal.valueOf(countyValue));
                        }
                    }
                }                
                system.debug('County list --'+countyCodeList);
                res = [select Id, Name from T_COUNTY__c WHERE CDE_COUNTY__c IN :countyCodeList order by Name limit 100];
                system.debug('the county list as per the assigned county --'+res);
            } else{
                res = [select Id, Name from T_COUNTY__c order by Name limit 100];
            }        
        List<PicklistEntryDefinition> countyCodeResult = new List<PicklistEntryDefinition>();
        for(T_COUNTY__c countyList: res){
            PicklistEntryDefinition p = new PicklistEntryDefinition(countyList.Name,countyList.Id,false);
            countyCodeResult.add(p);
        }
        return countyCodeResult;
    }
}