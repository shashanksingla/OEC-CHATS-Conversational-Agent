public with sharing class AuthEncumbRelatedListController implements IRequest{

    public static String EXEMPT = System.Label.Exempt_Provider_Type;
    public String jsonParam;
    private static Map<String, Object> requestObj;

    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }

        if (methodName == 'fetchRelatedObjectdata') {
            response = fetchRelatedObjectdata(getMapValue('recordId'));
        } else if (methodName == 'fetchRelatedArchivedObjectdata') {
            response = fetchRelatedArchivedObjectdata(getMapValue('recordId'), getMapValue('monthStr'), getMapValue('yearStr'));
        } else if (methodName == 'getAuthEncumbRecordId') {
            String recordId = getAuthEncumbRecordId(getMapValue('externalId'));
            response = new LightningServerResponse(true, 'Success', new Map<String, object>{'recordId' => recordId});
        } 
        return response;
    }

    private static String getMapValue(String fieldName){
        return (String)requestObj.get(fieldName);
    }

    @AuraEnabled
    public static String getAuthEncumbRecordId(String externalId){
        String recordId;
       if(String.isNotBlank(externalId)){
            List<batchsit_t_auth_encmbr__x> encumbList = [Select id ,ExternalId from batchsit_t_auth_encmbr__x where ExternalId =:externalId WITH SECURITY_ENFORCED];
            if(encumbList != null && encumbList.size()>0){
                recordId =encumbList[0].id;
            }
        }
        return recordId;
    }

    @AuraEnabled
    public static LightningServerResponse fetchRelatedObjectdata(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Map<String, String> rateTypeMap = new Map<String, String>();
        Map<String, String> statusMap = new Map<String, String>();
        Boolean isSuccessful = true;
        String message;
        String isErrorWebservice = '';
        Boolean attendedFlg;
        List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
        List<authEncumbranceRelatedListWrap> authEncumbranceRelatedList = new List<authEncumbranceRelatedListWrap>();
        List<batchsit_t_sbsd_indiv_care_level__x> careLevels = new List<batchsit_t_sbsd_indiv_care_level__x>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2 = new Map<String, batchsit_t_auth_encmbr__x>();
        try {
            T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c, IDN_CLIENT__r.DTE_DOB__c,
                                 IDN_PROVR__r.CDE_TYPE_PROVR__c, IDN_CASE__c, Protective_Services_Indicator__c
                                 FROM T_AUTH__c where id =:recordId WITH SECURITY_ENFORCED];
            Schema.DescribeFieldResult fieldResult = T_FISCAL_SCH__c.CDE_RATE_TYPE__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry f : ple){
                rateTypeMap.put(f.getValue(), f.getLabel());
            }  
            Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00690__c.getDescribe();
            List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
            for(Schema.PicklistEntry f : ple1){
                statusMap.put(f.getValue(), f.getLabel());
            }
            if(authRec != null){
                if(!Test.isRunningTest()){
                    fetchedEncumberence = HerokuService.authEncumbrancefetch(authRec.IDN_EXTNL__c);
                } else {
                    fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =(system.today()).addDays(1),idn_auth__c ='Test123',cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId='Test123',ind_0_36_months__c='Y'));
                    fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =(system.today()).addDays(1),idn_auth__c ='Test123',cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId='Test234',ind_0_36_months__c='N'));
                }
                for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence){
                    authEncumbranceRelatedListWrap encumb = new authEncumbranceRelatedListWrap();
                    encumb.ExternalId = anAuthEncmbr.ExternalId;
                    encumb.encumbId = anAuthEncmbr.ExternalId;
                    encumb.status = statusMap.get(String.valueOf(anAuthEncmbr.cde_status_encmbr__c));
                    encumb.rateType = rateTypeMap.get(String.valueOf(anAuthEncmbr.cde_type_unit_care__c)) ;
                    encumb.dateOfCare = anAuthEncmbr.dte_care__c;
                    encumb.actualAttendedHours = anAuthEncmbr.cnt_hour_attnd_actual__c;
                    encumb.authorizedHours = anAuthEncmbr.cnt_Hour_Care__c;
                    encumb.attendedFlag = HerokuService.globalAttended.get(encumb.ExternalId);
                    encumb.ind0to36months = anAuthEncmbr.ind_0_36_months__c == 'Y' ? true : false; //added for CCCAP-14174
                    authEncumbranceRelatedList.add(encumb);
                }
                // objectData.put('fetchedEncumberence',fetchedEncumberence);
            }
        } catch(Exception ex) {
            String message1 = ex.getMessage();
            if(fetchedEncumberence == null || fetchedEncumberence.size() <=0){
                message1 = 'Problem in connecting with external system.';
            }
            return new LightningServerResponse(false, message1, null);
        }
        return new LightningServerResponse(isSuccessful,'Validation check',new Map<String, object>{'authEncumbranceRelatedList' => authEncumbranceRelatedList});
    }
    @AuraEnabled
    public static LightningServerResponse fetchRelatedArchivedObjectdata(String recordId, String monthStr, string yearStr){
        Map<String, Object> objectData = new map<String, Object>();
        Map<String, String> rateTypeMap = new Map<String, String>();
        Map<String, String> statusMap = new Map<String, String>();
        Boolean isSuccessful = true;
        String message;
        String isErrorWebservice = '';
        Boolean attendedFlg;
        List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
        List<authEncumbranceRelatedListWrap> authEncumbranceRelatedList = new List<authEncumbranceRelatedListWrap>();
        List<batchsit_t_sbsd_indiv_care_level__x> careLevels = new List<batchsit_t_sbsd_indiv_care_level__x>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2 = new Map<String, batchsit_t_auth_encmbr__x>();
        try {
            T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c, IDN_CLIENT__r.DTE_DOB__c,
                                 IDN_PROVR__r.CDE_TYPE_PROVR__c, IDN_CASE__c, Protective_Services_Indicator__c
                                 FROM T_AUTH__c where id =:recordId WITH SECURITY_ENFORCED];
            Schema.DescribeFieldResult fieldResult = T_FISCAL_SCH__c.CDE_RATE_TYPE__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry f : ple){
                rateTypeMap.put(f.getValue(), f.getLabel());
            }  
            Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00690__c.getDescribe();
            List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
            for(Schema.PicklistEntry f : ple1){
                statusMap.put(f.getValue(), f.getLabel());
            }
            if(authRec != null){
                if(!Test.isRunningTest()){
                    fetchedEncumberence = HerokuService.authEncumbrancefetchArchived(authRec.IDN_EXTNL__c,monthStr,yearStr);
                } else {
                    fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =(system.today()).addDays(1),idn_auth__c ='Test123',cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId='Test123',ind_0_36_months__c='Y'));
                    fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =(system.today()).addDays(1),idn_auth__c ='Test123',cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId='Test234',ind_0_36_months__c='N'));
                }
                for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence){
                    authEncumbranceRelatedListWrap encumb = new authEncumbranceRelatedListWrap();
                    encumb.ExternalId = anAuthEncmbr.ExternalId;
                    encumb.encumbId = anAuthEncmbr.ExternalId;
                    encumb.status = statusMap.get(String.valueOf(anAuthEncmbr.cde_status_encmbr__c));
                    encumb.rateType = rateTypeMap.get(String.valueOf(anAuthEncmbr.cde_type_unit_care__c)) ;
                    encumb.dateOfCare = anAuthEncmbr.dte_care__c;
                    encumb.actualAttendedHours = anAuthEncmbr.cnt_hour_attnd_actual__c;
                    encumb.authorizedHours = anAuthEncmbr.cnt_Hour_Care__c;
                    encumb.attendedFlag = HerokuService.globalAttended.get(encumb.ExternalId);
                    encumb.ind0to36months = anAuthEncmbr.ind_0_36_months__c == 'Y' ? true : false; //added for CCCAP-14174
                    authEncumbranceRelatedList.add(encumb);
                }
                // objectData.put('fetchedEncumberence',fetchedEncumberence);
            }
        } catch(Exception ex) {
            String message1 = ex.getMessage();
            if(fetchedEncumberence == null || fetchedEncumberence.size() <=0){
                message1 = 'Problem in connecting with external system.';
            }
            return new LightningServerResponse(false, message1, null);
        }
        return new LightningServerResponse(isSuccessful,'Validation check',new Map<String, object>{'authEncumbranceRelatedList' => authEncumbranceRelatedList});
    }

}