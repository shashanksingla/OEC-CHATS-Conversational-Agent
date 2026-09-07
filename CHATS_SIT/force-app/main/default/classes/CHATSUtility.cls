public with sharing class CHATSUtility {
    
    public static Boolean checkCountyWithUserCounty(Id countyId){
        Boolean countyMatched = true;
        User user = [SELECT Owner_County__c,Common_County__c , Profile.Name 
                     FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        //CCCAP-14993
        if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) {
            countyMatched = false;
            List<T_COUNTY__c> counties = [SELECT CDE_COUNTY__c FROM T_COUNTY__c WHERE Id = :countyId];
            if(!counties.isEmpty()){
                String county = String.valueOf(counties.get(0).CDE_COUNTY__c);
                if(user.Owner_County__c == county || (String.isNotBlank(user.Common_County__c) && new Set<String>(user.Common_County__c.split(';')).contains(county))) {
                       countyMatched = true;
                   }
            }
        }
        return countyMatched;
    }

    public static Boolean checkCountyforProvider(Id providerId){
        Boolean countyMatched = true;
        User user = [SELECT Owner_County__c, Common_County__c, Profile.Name 
                     FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        //CCCAP-14993
        if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) {
            countyMatched = false;
            
            for(T_PROVR_FISCAL_AGREMENT__c cs : [SELECT CDE_COUNTY__c, CDE_COUNTY__r.CDE_COUNTY__c 
                                                 FROM T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c =: providerId]){
                String county = String.valueOf(cs.CDE_COUNTY__r.CDE_COUNTY__c);
                if(user.Owner_County__c == county || (String.isNotBlank(user.Common_County__c) && new Set<String>(user.Common_County__c.split(';')).contains(county))) {
                       countyMatched = true;
                   }
            }            
        }
        return countyMatched;
    }
    //corrected below method for CCCAP-14433 by Shashank
    public static map<Id, Boolean> checkCountyWithUserCountyBulk(set<Id> countyIdSet){
        map<Id, Boolean> countyMatchedMap = new Map<Id, Boolean>();
        User user = [SELECT Owner_County__c, Common_County__c, Profile.Name 
                     FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Boolean countyMatched = true;        
        for(T_COUNTY__c rec : [SELECT CDE_COUNTY__c FROM T_COUNTY__c WHERE Id IN :countyIdSet]){
            //CCCAP-14993
            if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) {
                countyMatched = false;
                String county = String.valueOf(rec.CDE_COUNTY__c);
                if(user.Owner_County__c == county || (String.isNotBlank(user.Common_County__c) && new Set<String>(user.Common_County__c.split(';')).contains(county))) {
                       countyMatched = true;
                   }
            }else{
                countyMatched = true;
            }
            countyMatchedMap.put(rec.Id, countyMatched);
        }
        return countyMatchedMap;
    }

    /*
	Description: get Picklist Values to Labels List
    Author: Vineet Srivasatava
	Date: 4/02/2018   
	Param: fieldResult
	Return: lstPicklistValuesToLabel
	*/
    public static List<AgeGroupWrapper> getPicklistValuesToLabelList(Schema.DescribeFieldResult fieldResult){
        List<AgeGroupWrapper> lstPicklistValuesToLabel = new List<AgeGroupWrapper>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        AgeGroupWrapper ageGroup;
        for( Schema.PicklistEntry f : ple){
            ageGroup = new AgeGroupWrapper();
            ageGroup.ageGroupLabel = f.getLabel();
            ageGroup.ageGroupValue = f.getValue();
            lstPicklistValuesToLabel.add(ageGroup);
        }       
        return lstPicklistValuesToLabel;
    }
    
    /*
	Description: get Picklist Values to Labels Map
    Author: Vineet Srivasatava
	Date: 4/02/2018   
	Param: fieldResult
	Return: mapPicklistValuesToLabel
	*/
    public static Map<String, String> getPicklistValuesToLabelMap(Schema.DescribeFieldResult fieldResult){
        Map<String, String> mapPicklistValuesToLabel = new Map<String, String>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            mapPicklistValuesToLabel.put(f.getValue(), f.getLabel());
        }       
        return mapPicklistValuesToLabel;
    }   
    
    public static List<FieldInformationWrapper.fieldDefinition> getFieldDefinition(String sObjectName, List<String> fieldAPINames) {
        SObjectType sObjectNameType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String,Schema.SObjectField> sObjectFields = sObjectNameType.getDescribe().fields.getMap();
        List<FieldInformationWrapper.fieldDefinition> mapOfObjectToField = new List<FieldInformationWrapper.fieldDefinition>();
        FieldInformationWrapper.fieldDefinition fieldInfo;
        Schema.SObjectField field;
        for(String eachFieldAPIName : fieldAPINames) {
            field = sObjectFields.get(eachFieldAPIName);
            fieldInfo = new FieldInformationWrapper.fieldDefinition();
            fieldInfo.fieldAPIName = eachFieldAPIName;
            fieldInfo.objectName = sObjectName;
            fieldInfo.dataType = String.valueOf(field.getDescribe().getType());
            fieldInfo.fieldLabel = String.valueOf(field.getDescribe().getLabel());
            if(field.getDescribe().getReferenceTo()!=null && !field.getDescribe().getReferenceTo().isEmpty()){
                if(eachFieldAPIName=='OwnerId') {
                    fieldInfo.referenecedObjectName = 'User';
                } else {
                    fieldInfo.referenecedObjectName = String.valueOf(field.getDescribe().getReferenceTo().get(0));
                }
            }
            mapOfObjectToField.add(fieldInfo);
        }
        return mapOfObjectToField;
    }
    
    @future
    public static void createTemplateUser(){
        UserRole ur =[Select Id From UserRole where DeveloperName = 'Template_Administrator'];
        // Profile required for user creation
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'newUser', Email='newuser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='newuserchats@testorg.com', UserRoleId =ur.Id);
        insert u;
        List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name='System_Administrator_PS' LIMIT 1];
        if(!psList.isEmpty()){
        	PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psList[0].Id, AssigneeId =u.Id);
            insert psa;
        }
    }
    
    /*
    Author: Rishav Maji
	Description: Merges/replaces braced fields in a string with actual value from an object
	Input Params: object (contains the fields to merge), String (initial text to merge into)
	Input String format: [ObjectAPI.FieldAPI] (e.g. [User.Email] including squire brackets[] )
	Return: String (in merged format, see test class for execution example)
	Limitation: for lookup fields it works upto 3 levels (e.g. for Account obj <Account.Contact.Owner.Name> will work but <Account.Contact.Owner.Profile.Name> wont)
	*/
    public static String mergeText(SObject obj, String inputString){
        String outputString = inputString;
        String inputStringTemp = inputString;
        List<String> mergeFieldAPIList = new List<String>();
        String objectAPI = obj.getSObjectType().getDescribe().getName();
        Integer mergeFieldsCount = inputString.countMatches('[');
        for(Integer i=0; i<mergeFieldsCount; i++){
            String fieldAPI = inputStringTemp.substringBetween('[',']');
            mergeFieldAPIList.add(fieldAPI);
            inputStringTemp = inputStringTemp.remove('['+fieldAPI+']');
        }
        inputStringTemp = inputString;
        for(String mergeFieldAPI : mergeFieldAPIList){
            if(mergeFieldAPI.contains(objectAPI)) {
                mergeFieldAPI = mergeFieldAPI.removeStart(objectAPI+'.');
                Integer lookupLevel = mergeFieldAPI.countMatches('.');
                String toReplace = '['+objectAPI+'.'+mergeFieldAPI+']';
                if(lookupLevel == 0){ // for Account obj <Account.Name>
                    try {
                        inputStringTemp = inputStringTemp.replace(toReplace, (String) obj.get(mergeFieldAPI));
                    } catch(Exception ex) {
                        inputStringTemp = inputStringTemp.replace(toReplace, '');
                    }
                } else if(lookupLevel == 1) { // for Account obj <Account.Contact.Name>
                    List<String> mergeFieldAPISplitted = mergeFieldAPI.split('\\.');
                    try {
                        inputStringTemp = inputStringTemp.replace(toReplace, (String) obj.getSobject(mergeFieldAPISplitted[0]).get(mergeFieldAPISplitted[1]));
                    } catch(Exception ex) {
                        inputStringTemp = inputStringTemp.replace(toReplace, '');
                    }
                } else if(lookupLevel == 2) { // for Account obj <Account.Contact.Owner.Name>
                    List<String> mergeFieldAPISplitted = mergeFieldAPI.split('\\.');
                    try {
                        inputStringTemp = inputStringTemp.replace(toReplace, (String) obj.getSobject(mergeFieldAPISplitted[0]).getSobject(mergeFieldAPISplitted[1]).get(mergeFieldAPISplitted[2]));
                    } catch(Exception ex) {
                        inputStringTemp = inputStringTemp.replace(toReplace, '');
                    }
                } else { // for Account obj <Account.Contact.Owner.Profile.Name>
                    continue; // will not work from 4+ levels
                }
            } else {
                continue;
            }
        }
        outputString = inputStringTemp;
        System.debug('[CHATSUtility.mergeText]--outputString-->'+outputString);
        return outputString;
    }
    /*
	Description: get Picklist Values to Labels Map
    Author: Vineet Srivasatava
	Date: 7/12/2021   
	Param: fieldResult
	Return: mapPicklistLabelToValue
	*/
    public static Map<String, String> getPicklistLabeltoValueMap(Schema.DescribeFieldResult fieldResult){
        Map<String, String> mapPicklistLabelToValue = new Map<String, String>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            mapPicklistLabelToValue.put(f.getLabel(),f.getValue());
        }       
        return mapPicklistLabelToValue;
    }

    /** CCCAP-15329
     * Returns the 4th Monday of the current month if today >= that date.
     * Otherwise returns the previous month's 4th Monday.
     */
    public static Date getUPKCutoffDate() {
        Date today = Date.today();
        Date cutoff = getUPKFourthMonday(today.year(), today.month());
        if (today >= cutoff) {
            return cutoff;
        }
        Integer prevMonth = today.month() == 1 ? 12 : today.month() - 1;
        Integer prevYear  = today.month() == 1 ? today.year() - 1 : today.year();
        return getUPKFourthMonday(prevYear, prevMonth);
    }

    private static Date getUPKFourthMonday(Integer yr, Integer mo) {
        Date knownMonday  = Date.newInstance(2026, 1, 5); // known Monday anchor
        Date firstOfMonth = Date.newInstance(yr, mo, 1);
        Integer dow = Math.mod(knownMonday.daysBetween(firstOfMonth), 7);
        Integer daysToFirstMon = Math.mod(7 - dow, 7);
        return firstOfMonth.addDays(daysToFirstMon + 21);
    }
}