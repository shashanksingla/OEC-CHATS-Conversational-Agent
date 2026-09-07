public with sharing class subPaymentSearch implements IRequest{
    public String jsonParam;
    private static Map<String, Object > requestObj;
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);        
        if (methodName == 'doSearchSubPayment') {
            response = doSearchSubPayment(getMapValue('paymentId'),getMapValue('providerId'),getMapValue('caseId'),getMapValue('countyId'),getMapValue('servicePeriodId'),getMapValue('stateId'),getMapValue('childFirstName'),getMapValue('childLastName'));
        } else if(methodName == 'doSearchSubpymntId'){
            response = doSearchSubpymntId(getMapValue('subPaymentId'));
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    @auraEnabled
    public static LightningServerResponse doSearchSubpymntId(String subPaymentId){
        Map<String, Object> objectData = new map<String, Object>();
        List<batchsit_t_sub_pmt__x> subPaymentList = new List<batchsit_t_sub_pmt__x>([select id from batchsit_t_sub_pmt__x where idn_pmt_sub__c=:decimal.valueOf(subpaymentId)]);
        if(subPaymentList!=null && !subPaymentList.isEmpty()){
            objectData.put('subPaymntSfId', subPaymentList[0]?.Id);    
        }
        LightningServerResponse resp = new LightningServerResponse(true, null, objectData);
        resp.status = RequestStatus.OK;
        return resp;
    }
    @AuraEnabled
    public static LightningServerResponse doSearchSubPayment(String paymentId, String providerId,String caseId, String countyId,String servicePeriodId, String stateId,String childFirstName, String childLastName){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;String message;
        try{
            SubPaymentSearchApxCtrl.throwException = true;
            List<SubPaymentSearchApxCtrl.subpaymentWrapper> subPaymentList = SubPaymentSearchApxCtrl.doSubPaymentSearch(paymentId, providerId, caseId, countyId, servicePeriodId, stateId, childFirstName, childLastName,null);
            Schema.DescribeFieldResult fieldResult2 = Field_Utility__c.R00716__c.getDescribe();
            List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
            if(subPaymentList!=null && !subPaymentList.isEmpty()){
                for(SubPaymentSearchApxCtrl.subpaymentWrapper subPayment:subPaymentList){
                    for(Schema.PicklistEntry f : ple2){
                        if(subPayment.subPymtStatus == f.getValue()){
                            subPayment.subPymtStatus = f.getLabel();
                        }
                    }   
                }
                objectData.put('SubpaymentSearchResults', subPaymentList);    
            }
            isSuccessful = true;
        }catch(System.CalloutException e) {
            message = 'The search has timed out. Please add additional search criteria to further reduce the search results and try again.';
        }catch(Exception Ex){
            message = 'The search has timed out. Please add additional search criteria to further reduce the search results and try again.';
        }
        LightningServerResponse resp = new LightningServerResponse(isSuccessful, message, objectData);
        return resp;
    }
    @AuraEnabled
    public static LightningServerResponse subPaymentPicklistMap(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Map<String, String> subPaymentStatusList = new Map<String, String>();
        Boolean isSuccessful = false;
        String message = '';
        try{
            List<batchsit_t_sub_pmt__x> subPaymentInfo = [select Id,ExternalId,idn_auth__c,idn_auth__r.NAM_FIRST__c, idn_slot_contract__r.CDE_COUNTY__r.Name, idn_slot_contract__c,
                                                          idn_auth__r.CDE_COUNTY__r.Name,idn_auth__r.NAM_LAST__c,idn_auth__r.IDN_CASE__r.Name,idn_auth__r.IDN_PROVR__r.Name,
                                                          cde_status_pmt_sub__c, amt_total_pmt_sub__c, amt_slot_pmt_sub__c, amt_copay_pmt_sub__c, amt_rate_pmt_sub__c,
                                                          idn_pmt_sub__c, idn_auth__r.Id, idn_auth__r.Name, idn_pmt__r.Id, idn_pmt__r.Name, idn_period_serv__r.Id, idn_period_serv__r.Name,
                                                          idn_slot_contract__r.Id, idn_slot_contract__r.Name
                                                          from batchsit_t_sub_pmt__x
                                                          where Id = :recordId];
            
            Schema.DescribeFieldResult R00716 = Field_Utility__c.R00716__c.getDescribe();
            List<Schema.PicklistEntry> R00716List = R00716.getPicklistValues();
            for(Schema.PicklistEntry p : R00716List){
                subPaymentStatusList.put(p.getValue(), p.getLabel());
            }
            
            for(batchsit_t_sub_pmt__x subPaymentData : subPaymentInfo){
                if(!String.isBlank(subPaymentData.cde_status_pmt_sub__c) && !subPaymentStatusList.isEmpty()){
                    subPaymentData.cde_status_pmt_sub__c = subPaymentStatusList.get(subPaymentData.cde_status_pmt_sub__c);
                }
            }
            objectData.put('subPaymentInfo', subPaymentInfo);
            isSuccessful = true;
        }
        catch(Exception exp){
            isSuccessful = false;
            message = exp.getLineNumber()+':'+exp.getMessage();
            ExceptionLoggingServices.captureExceptionLog(exp, new Map<String,Object>{'Class__c'=>'subPaymentSearch','Method__c'=>'subPaymentPicklistMap'});
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    @AuraEnabled
    public static LightningServerResponse subPaymentDetailsPicklistMap(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Map<String, String> subPaymentDetailStatusList = new Map<String, String>();
        Map<String, String> subPaymentDetailLevelCareList = new Map<String, String>();
        Map<String, String> subPaymentDetailTimeTrndlList = new Map<String, String>();
        Map<String, String> subPaymentDetailTypeInfoList = new Map<String, String>();
        Map<String, String> subPaymentDetailUnitCareList = new Map<String, String>();
        Map<String, String> subPaymentDetailPrgFundingList = new Map<String, String>();
        Boolean isSuccessful = false;
        String message = '';
        String subPaymentId;
        try{
            List<batchsit_t_sub_pmt_detail__x> subPaymentDetailInfo;
            If(Test.isRunningTest()){
                subPaymentDetailInfo = new  List<batchsit_t_sub_pmt_detail__x>{new batchsit_t_sub_pmt_detail__x(cde_status_detail_pmt_sub__c='abs', 
                                                                                                                cde_level_care__c='def',
                                                                                                                cde_time_trdnl__c='jkl',
                                                                                                                cde_type_info_addntl__c='kem',
                                                                                                                cde_type_unit_care__c='xyz',
                                                                                                                idn_prog_fndg__c='lmn' )};
                                                                                                                    
                                                                                                                    
            } else {
                subPaymentDetailInfo = [select Id, ExternalId, amt_copay__c, amt_rate__c, amt_total__c, cde_level_care__c,amt_act_paid__c,amt_reg_paid__c,
                                      idn_fiscal_rat_fee__c, amt_trans_paid__c , cde_status_detail_pmt_sub__c, cde_time_trdnl__c, 
                                      cde_type_info_addntl__c, amt_slot_paid__c, ind_0_36_months_enroll_pmt__c,
                                      cde_type_unit_care__c, cde_unit_care_actual__c,
                                      cde_unit_care_exptd__c, dte_care__c, idn_prog_fndg__c, idn_detail_pmt_sub__c,
                                      idn_pmt_sub__c, ind_adjmt__c, nbr_seq_hist__c
                                      from batchsit_t_sub_pmt_detail__x
                                      where Id = :recordId];
            }
            
            Boolean claimExists = false;
            Boolean recoveryExists = false;
            if(subPaymentDetailInfo.size()>0){
                for(batchsit_t_sub_pmt__x subPmt : [Select id,idn_pmt_sub__c,idn_slot_contract__c,idn_auth__c from batchsit_t_sub_pmt__x where ExternalId =:subPaymentDetailInfo[0].idn_pmt_sub__c]){
                    subPaymentId = subPmt.Id;
                    objectData.put('subPaymentId', subPaymentId);
                    Boolean isVacantSlot = subPmt.idn_slot_contract__c != null && subPmt.idn_auth__c == null;
                    objectData.put('vacantSlotPayment', isVacantSlot);
                }
                list<String> adjStatus = new List<String>{'2', '3', '4', '5'};
                for(T_ADJMT_DETAIL__c adjd : [SELECT Id, CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c, IDN_ADJMT__r.CDE_TYPE_ADJMT__c
                                              FROM T_ADJMT_DETAIL__c WHERE IDN_DETAIL_PMT_SUB__c = :subPaymentDetailInfo[0].ExternalId
                                               AND CDE_STATUS_DETAIL_ADJMT__c IN : adjStatus]){
                                                   if(adjd.IDN_ADJMT__r.CDE_TYPE_ADJMT__c == '1'){
                                                       claimExists = true;
                                                   }
                                                   if(adjd.IDN_ADJMT__r.CDE_TYPE_ADJMT__c == '2'){
                                                       recoveryExists = true;
                                                   }
                }
            }
            system.debug(subPaymentDetailInfo);
            Schema.DescribeFieldResult R00716 = Field_Utility__c.R00716__c.getDescribe();
            List<Schema.PicklistEntry> R00716List = R00716.getPicklistValues();
            for(Schema.PicklistEntry p : R00716List){
                subPaymentDetailStatusList.put(p.getValue(), p.getLabel());
            }
            
            Schema.DescribeFieldResult R00710 = Field_Utility__c.R00710__c.getDescribe();
            List<Schema.PicklistEntry> R00710List = R00710.getPicklistValues();
            for(Schema.PicklistEntry p : R00710List){
                subPaymentDetailLevelCareList.put(p.getValue(), p.getLabel());
            }
            
            Schema.DescribeFieldResult R00715 = Field_Utility__c.R00715__c.getDescribe();
            List<Schema.PicklistEntry> R00715List = R00715.getPicklistValues();
            for(Schema.PicklistEntry p : R00715List){
                subPaymentDetailTimeTrndlList.put(p.getValue(), p.getLabel());
            }
            
            Schema.DescribeFieldResult R00714 = Field_Utility__c.R00714__c.getDescribe();
            List<Schema.PicklistEntry> R00714List = R00714.getPicklistValues();
            for(Schema.PicklistEntry p : R00714List){
                subPaymentDetailTypeInfoList.put(p.getValue(), p.getLabel());
            }
            
            Schema.DescribeFieldResult R00751 = Field_Utility__c.R00751__c.getDescribe();
            List<Schema.PicklistEntry> R00751List = R00751.getPicklistValues();
            for(Schema.PicklistEntry p : R00751List){
                subPaymentDetailUnitCareList.put(p.getValue(), p.getLabel());
            }
            
            Schema.DescribeFieldResult R00728 = Field_Utility__c.R00728__c.getDescribe();
            List<Schema.PicklistEntry> R00728List = R00728.getPicklistValues();
            for(Schema.PicklistEntry p : R00728List){
                subPaymentDetailPrgFundingList.put(p.getValue(), p.getLabel());
            }
            
            for(batchsit_t_sub_pmt_detail__x subPaymentDetailData : subPaymentDetailInfo){
                if(!String.isBlank(subPaymentDetailData.cde_status_detail_pmt_sub__c)
                   && !subPaymentDetailStatusList.isEmpty()){
                       subPaymentDetailData.cde_status_detail_pmt_sub__c = subPaymentDetailStatusList.get(subPaymentDetailData.cde_status_detail_pmt_sub__c);
                   }
                if(!String.isBlank(subPaymentDetailData.cde_level_care__c)
                   && !subPaymentDetailLevelCareList.isEmpty()){
                       subPaymentDetailData.cde_level_care__c = subPaymentDetailLevelCareList.get(subPaymentDetailData.cde_level_care__c);
                   }
                if(!String.isBlank(subPaymentDetailData.cde_time_trdnl__c)
                   && !subPaymentDetailTimeTrndlList.isEmpty()){
                       subPaymentDetailData.cde_time_trdnl__c = subPaymentDetailTimeTrndlList.get(subPaymentDetailData.cde_time_trdnl__c);
                   }
                if(!String.isBlank(subPaymentDetailData.cde_type_info_addntl__c)
                   && !subPaymentDetailTypeInfoList.isEmpty()){
                       subPaymentDetailData.cde_type_info_addntl__c = subPaymentDetailTypeInfoList.get(subPaymentDetailData.cde_type_info_addntl__c);
                   }
                if(!String.isBlank(subPaymentDetailData.cde_type_unit_care__c)
                   && !subPaymentDetailUnitCareList.isEmpty()){
                       subPaymentDetailData.cde_type_unit_care__c = subPaymentDetailUnitCareList.get(subPaymentDetailData.cde_type_unit_care__c);
                   }
                if(!String.isBlank(subPaymentDetailData.idn_prog_fndg__c)
                   && !subPaymentDetailPrgFundingList.isEmpty()){
                       subPaymentDetailData.idn_prog_fndg__c = subPaymentDetailPrgFundingList.get(subPaymentDetailData.idn_prog_fndg__c);
                   }
                subPaymentDetailData.ind_claim__c = claimExists ? 'Y' : 'N';
                subPaymentDetailData.ind_recovery__c = recoveryExists ? 'Y' : 'N';                
            }
            objectData.put('subPaymentDetailInfo', subPaymentDetailInfo);
            isSuccessful = true;
        }
        catch(Exception exp){
            isSuccessful = false;
            message = exp.getLineNumber()+':'+exp.getMessage();
            ExceptionLoggingServices.captureExceptionLog(exp, new Map<String,Object>{'Class__c'=>'subPaymentSearch','Method__c'=>'subPaymentDetailsPicklistMap'});
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
}