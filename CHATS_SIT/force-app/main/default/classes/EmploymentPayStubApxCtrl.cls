public with sharing class EmploymentPayStubApxCtrl {
    @AuraEnabled
    public static LightningServerResponse getDoInit(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        List<PicklistOption> rateTypeOptions = new List<PicklistOption>();
        
        Boolean isSuccessful = true;
        String message='';
        Set<String> howVerifiedSelfPayStub = new Set<String> {'CCH','OTH','SML','LGR','TF'};
            Set<String> howVerifiedPayStub = new Set<String> {'STB','ELT','VER','WNW','CCH','OTH','OD'};
                system.debug('recordId--'+recordId);
        
        String sObjectName;
        Schema.DescribeFieldResult fieldResult = T_EMPLMT_PAY_STUB__c.CDE_SOURCE_VRFYD_PAY__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        rateTypeOptions.add(new PicklistOption(
            '--None--', ''                 
        )); 
        if(String.isNotBlank(recordId)){
            sObjectName = CHATSAuraUtility.getSobjectName(recordId);
            
        }else{
            system.debug('record id blank else--');
            for( Schema.PicklistEntry f : ple)
            {
                rateTypeOptions.add(new PicklistOption(
                    f.getLabel(), f.getValue()                 
                ));  
            }
        }
        system.debug('recordId--'+recordId);
        if(sObjectName =='T_EMPLMT_INCOME__c'){
            rateTypeOptions=  getPickListOptions(recordId,rateTypeOptions);
        }
        if(sObjectName =='T_EMPLMT_PAY_STUB__c'){
            List<T_EMPLMT_PAY_STUB__c> employmentPayStubLst = [Select id, Name,CDE_STATUS__c,AMT_TIPS_AVG__c,AMT_INCOME_GROSS__c,CDE_SOURCE_VRFYD_PAY__c,CDE_FREQ_PAY__c,CNT_WORKED_HOURS_STUB_PAY__c,
                                                               CDE_TYPE_VERIF__c,IDN_EMPLMT_INCOME__c,DTE_PAY__c from T_EMPLMT_PAY_STUB__c where id=:recordId WITH SECURITY_ENFORCED];
            if(employmentPayStubLst != null && employmentPayStubLst.size()>0){
                objectData.put('employmentPayStubRec',employmentPayStubLst[0]);
                rateTypeOptions=  getPickListOptions(employmentPayStubLst[0].IDN_EMPLMT_INCOME__c,rateTypeOptions);
            }
        }
        system.debug('rateTypeOptions---'+rateTypeOptions);
        objectData.put('rateTypeOptions',rateTypeOptions);
        objectData.put('getSobjectName',sObjectName);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static List<PicklistOption> getPickListOptions(String recordId, List<PicklistOption> rateTypeOptions){
        Schema.DescribeFieldResult fieldResult = T_EMPLMT_PAY_STUB__c.CDE_SOURCE_VRFYD_PAY__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Set<String> howVerifiedSelfPayStub = new Set<String> {'CCH','OTH','SML','LGR','TF'};
            Set<String> howVerifiedPayStub = new Set<String> {'STB','ELT','VER','WNW','CCH','OTH','OD'};
                T_EMPLMT_INCOME__c employIncome = [Select id,IDN_EMPLMT_INDIV__c,IDN_EMPLMT_INDIV__r.RecordType.DeveloperName from T_EMPLMT_INCOME__c where id=:recordId WITH SECURITY_ENFORCED limit 1 ];
        String RecordTypeName = employIncome.IDN_EMPLMT_INDIV__r.RecordType.DeveloperName; 
        system.debug('RecordTypeName--'+RecordTypeName);
        for( Schema.PicklistEntry f : ple)
        {
            if(RecordTypeName=='Self_Employment'){
                system.debug(' f.getLabel()- Self_Employment-'+ f.getLabel());
                if(howVerifiedSelfPayStub.contains(f.getValue())){
                    rateTypeOptions.add(new PicklistOption(
                        f.getLabel(), f.getValue()                 
                    ));  
                }
                
            }
            if(RecordTypeName=='Employment'){
                if(howVerifiedPayStub.contains(f.getValue())){
                    system.debug(' f.getLabel()--'+ f.getLabel());
                    rateTypeOptions.add(new PicklistOption(
                        f.getLabel(), f.getValue()                 
                    ));  
                }
                
            } 
            
        }
        return rateTypeOptions;
    }
    
}