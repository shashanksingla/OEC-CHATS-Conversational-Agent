// Changes
// 11/03/2020		Balamurugan Chinnaiah	CCCAP-2340: 6MB Heap Size Exceeds
public with sharing class AdjustmentFlowApxCtrl implements IRequest {
    public String jsonParam;
    private static Map<String, Object> requestObj;
    
    private static String getMapValue(String fieldName) {
        return (String)requestObj.get(fieldName);
    }
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }
        if (methodName == 'getCurrentUtilizationRecord') {
            response = getCurrentUtilizationRecord(getMapValue('adjustmentId'));
        } else if (methodName == 'doDeleteAdjustRecords') {
            response = doDeleteAdjustRecords(getMapValue('adjustmentId'));
        } else if (methodName == 'doDeleteRecords') {
            response = doDeleteRecords(getMapValue('adjustmentId'), (Boolean)requestObj.get('isNonAdjustment'));
        } else if (methodName == 'getAuthObj') {
            response = getAuthObj(getMapValue('authId'));
        } else if (methodName == 'subPaymentCallOut') {
            List<Object> rawList = (List<Object>)requestObj.get('adjustmentDtlList');
            String sObjJson = JSON.serialize(rawList);
            List<T_ADJMT_DETAIL__c> adjustmentDtlList = (List<T_ADJMT_DETAIL__c>)JSON.deserialize(sObjJson, List<T_ADJMT_DETAIL__c>.class);
            response = subPaymentCallOut(adjustmentDtlList);
        } else if (methodName == 'getRateTypeMap') {
            batchsit_t_sub_pmt_detail__x subPaymentDetail = (batchsit_t_sub_pmt_detail__x)JSON.deserialize(JSON.serialize(requestObj.get('subPaymentDetail')), batchsit_t_sub_pmt_detail__x.class);
            T_ADJMT_DETAIL__c adjustmentDetail = (T_ADJMT_DETAIL__c)JSON.deserialize(JSON.serialize(requestObj.get('adjustmentDetail')), T_ADJMT_DETAIL__c.class);
            response = getRateTypeMap(subPaymentDetail, adjustmentDetail);
        } else if (methodName == 'getSelectedIPVRecord') {
            response = getSelectedIPVRecord((Id)requestObj.get('IPVRecordId'));
        } else if (methodName == 'doGetAddress') {
            response = doGetAddress(getMapValue('adjustmentId'));
        } else if (methodName == 'doGetInitData') {
            response = doGetInitData(getMapValue('adjustmentId'));
        } else if (methodName == 'upsertResponsiblePartiesAddress') {
            List<Object> rawList = (List<Object>)requestObj.get('responsiblePartiesAddressList');
            String sObjJson = JSON.serialize(rawList);
            List<T_ADJMT_ADDR__c> responsiblePartiesAddressList = (List<T_ADJMT_ADDR__c>)JSON.deserialize(sObjJson, List<T_ADJMT_ADDR__c>.class);
            response = upsertResponsiblePartiesAddress((Id)requestObj.get('adjustmentId'), responsiblePartiesAddressList);
        } else if (methodName == 'getAdjustmentDetailsMap') {
            response = getAdjustmentDetailsMap(getMapValue('adjustmentId'));
        } else if (methodName == 'adjustmentDetails') {
            response = adjustmentDetails(getMapValue('adjustmentId'));
        } else if (methodName == 'getAdjustmentDetails') {
            response = getAdjustmentDetails(getMapValue('adjustmentId'));
        } else if (methodName == 'upsertResponsibleParties') {
            List<Object> rawList = (List<Object>)requestObj.get('responsiblePartyList');
            String sObjJson = JSON.serialize(rawList);
            List<T_ADJMT_RESPBL_PARTY__c> responsiblePartyList = (List<T_ADJMT_RESPBL_PARTY__c>)JSON.deserialize(sObjJson, List<T_ADJMT_RESPBL_PARTY__c>.class);
            response = upsertResponsibleParties((Id)requestObj.get('adjustmentId'), responsiblePartyList);
        } else if (methodName == 'getIndivInfoFromAuth') {
            Date adStartDate = requestObj.get('adStartDate') != null ? Date.valueOf(getMapValue('adStartDate')) : null;
            Date adEndDate = requestObj.get('adEndDate') != null ? Date.valueOf(getMapValue('adEndDate')) : null;
            response = getIndivInfoFromAuth(getMapValue('authorizationId'), adStartDate, adEndDate);
        } else if (methodName == 'getRecordTypeId') {
            Double adjustmentAmount = requestObj.get('adjustmentAmount') != null ? Double.valueOf(requestObj.get('adjustmentAmount')) : null;
            response = getRecordTypeId(getMapValue('recordTypeName'), getMapValue('parentObjectName'), getMapValue('recordId'), adjustmentAmount);
        } else if (methodName == 'getPicklistOptions') {
            response = getPicklistOptions();
        } else if (methodName == 'doSearchSubPaymentDetails') {
            Decimal subPaymentId = requestObj.get('subPaymentId') != null ? Decimal.valueOf(String.valueOf(requestObj.get('subPaymentId'))) : null;
            T_ADJMT__c adjustmentInfo = (T_ADJMT__c)JSON.deserialize(JSON.serialize(requestObj.get('adjustmentInfo')), T_ADJMT__c.class);
            response = doSearchSubPaymentDetails(subPaymentId, getMapValue('selectedSubPayment'), adjustmentInfo);
        } else if (methodName == 'calculateAdjustDetail') {
            T_ADJMT__c adjustment = (T_ADJMT__c)JSON.deserialize(JSON.serialize(requestObj.get('adjustment')), T_ADJMT__c.class);
            List<Object> rawSubPaymentDetails = (List<Object>)requestObj.get('subPaymentDetails');
            List<batchsit_t_sub_pmt_detail__x> subPaymentDetails = (List<batchsit_t_sub_pmt_detail__x>)JSON.deserialize(JSON.serialize(rawSubPaymentDetails), List<batchsit_t_sub_pmt_detail__x>.class);
            List<Object> rawAdjustmentDetail = (List<Object>)requestObj.get('adjustmentDetail');
            List<T_ADJMT_DETAIL__c> adjustmentDetail = (List<T_ADJMT_DETAIL__c>)JSON.deserialize(JSON.serialize(rawAdjustmentDetail), List<T_ADJMT_DETAIL__c>.class);
            response = calculateAdjustDetail(getMapValue('selectedSubPayment'), adjustment, subPaymentDetails, adjustmentDetail, getMapValue('adjustmentWrap'));
        } else if (methodName == 'doSearchSubPayment') {
            T_ADJMT__c adjustmentInfo = (T_ADJMT__c)JSON.deserialize(JSON.serialize(requestObj.get('adjustmentInfo')), T_ADJMT__c.class);
            Boolean slotCntcheckbox = requestObj.get('slotCntcheckbox') != null ? (Boolean)requestObj.get('slotCntcheckbox') : false;
            response = doSearchSubPayment(getMapValue('paymentObjId'), getMapValue('subPaymentObjId'), getMapValue('subPaymentObjNAMFIRST'),
                                         getMapValue('servicePeriodObjDTEBEGINEFFV'), getMapValue('subPaymentObjNAMLAST'),
                                         getMapValue('servicePeriodObjDTEENDEFFV'), adjustmentInfo, getMapValue('selectedAuthId'),
                                         getMapValue('selectedCaseId'), getMapValue('selectedSlotCntId'), slotCntcheckbox);
        } else if (methodName == 'searchRelatedAuthRecord') {
            T_ADJMT__c adjustmentInfo = (T_ADJMT__c)JSON.deserialize(JSON.serialize(requestObj.get('adjustmentInfo')), T_ADJMT__c.class);
            response = searchRelatedAuthRecord(getMapValue('nonSubPaymentObjNAMFIRST'), getMapValue('nonSubPaymentObjNAMLAST'), adjustmentInfo, getMapValue('selectedCaseId'));
        } else if (methodName == 'doVerifyAdjustmentNote') {
            response = doVerifyAdjustmentNote(getMapValue('adjId'));
        } else if (methodName == 'getAdjustmentPaidAmount') {
            response = getAdjustmentPaidAmount(getMapValue('adjustmentId'));
        }
        return response;
    }
    
    @AuraEnabled 
    public static LightningServerResponse getCurrentUtilizationRecord(String adjustmentId){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_ADJMT__c> adjustments = [SELECT id,AMT_ADJMT__c,CDE_COUNTY__c,
                                        //fetching Adjustment information
                                        toLabel(CDE_TYPE_ADJMT__c), toLabel(CDE_AGNST_ADJMT__c), toLabel(CDE_STATUS_ADJMT__c),IND_REIMBSL_PMT__c,  IDN_CASE__c, IDN_CASE__r.Name,
                                        DTE_END_ADJMT__c, RecordType.DeveloperName, Name, RecordTypeId, DTE_START_ADJMT__c,
                                        //fields for first page
                                        toLabel(IND_ORD_COURT_ADJMT__c), toLabel(CDE_REASON__c), toLabel(CDE_TYPE_CLSFN__c),toLabel(Recovery_Initiative__c),
                                        //fetching provider information
                                        IDN_PROVR__r.NAM_FACILITY__c, IDN_PROVR__c, IDN_PROVR__r.Name, IDN_PROVR__r.ADR_LINE1__c, IDN_PROVR__r.ADR_CITY__c, IDN_PROVR__r.ADR_STATE__c, IDN_PROVR__r.ADR_ZIP__c,
                                        IDN_PROVR__r.ADR_LINE1_MLNG__c, IDN_PROVR__r.ADR_CITY_MLNG__c, IDN_PROVR__r.ADR_STATE_MLNG__c, IDN_PROVR__r.ADR_ZIP_MLNG__c,
                                        //fetching existing address
                                        (SELECT Id, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, toLabel(ADR_STATE__c), ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r),
                                        //fetching existing responsible parties
                                        (SELECT Id, IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c FROM Adjustent5__r)
                                        FROM T_ADJMT__c 
                                        WHERE id=:adjustmentId];
        Map<String,List<T_ADJMT_DETAIL__c>> adjustDetailMap = getAdjustmentDetailsMap(adjustmentId);
        Map<String, List<batchsit_t_indiv_rat_fees__x>> currentUtilizationMap = new Map<String, List<batchsit_t_indiv_rat_fees__x>>();
        Set<String> childIds = new Set<String>();
        for(String subPay : adjustDetailMap.keySet()){
            for(T_ADJMT_DETAIL__c  adj :adjustDetailMap.get(subPay)){
                childIds.add(adj.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c);
            }
        }
        if(!childIds.isEmpty()){
            for(batchsit_t_indiv_rat_fees__x rateFee : [SELECT id,ExternalId,idn_indiv_rat_fee__c,idn_client__c,amt_act_paid__c,dte_care__c,createddate__c,dte_paid__c,amt_reg_paid__c,amt_reg_remaining__c,dte_begin_effev__c,dte_end_effev__c,
                                                        amt_act_remaining__c,amt_trans_paid__c,amt_trans_remaining__c,idn_provr__c from batchsit_t_indiv_rat_fees__x where idn_client__c IN:childIds and dte_begin_effev__c <=:adjustments[0].DTE_START_ADJMT__c and dte_end_effev__c >=:adjustments[0].DTE_END_ADJMT__c  order by ExternalId DESC]){
                                                            String dateStr = String.valueOf(rateFee.dte_care__c).split(' ')[0];
                                                            String keyStr = rateFee.idn_client__c;// +'-'+ dateStr +'-'+ rateFee.idn_provr__c;
                                                            if(!currentUtilizationMap.containsKey(keyStr)){
                                                                currentUtilizationMap.put(keyStr,new List<batchsit_t_indiv_rat_fees__x>{rateFee});
                                                            }
                                                        } 
        }
        if(!currentUtilizationMap.isEmpty()){
            objectData.put('currentUtilizationMap', currentUtilizationMap);
        }
        return new LightningServerResponse(true,'Done',objectData);
    }
    
    @AuraEnabled 
    public static LightningServerResponse doDeleteAdjustRecords(String adjustmentId){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_NON_ADJMT_DETAIL__c> nonAdjmtDetl =new List<T_NON_ADJMT_DETAIL__c>();
        List<T_ADJMT_DETAIL__c> AdjmtDetl =new List<T_ADJMT_DETAIL__c>();
        List<T_ADJMT__c> AdjmtLst =new List<T_ADJMT__c>();
        List<T_ADJMT_ADDR__c> adjmtAddrLst =new List<T_ADJMT_ADDR__c>();
        List<T_ADJMT_CMT__c> adjmtCmtLst =new List<T_ADJMT_CMT__c>();
        String message;
        Boolean isSuccessFull;
        if(!String.isBlank(adjustmentId)){
            
            nonAdjmtDetl =[Select id from T_NON_ADJMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId];
            if(nonAdjmtDetl.size() >0){
                //  delete nonAdjmtDetl;
                GenericDMLHandler.deleteRecords(nonAdjmtDetl,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'doDeleteRecords'});
            }
            
            AdjmtDetl =[Select id,Adjustment_Initiated__c from T_ADJMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId]; 
            if(AdjmtDetl.size() >0){
                GenericDMLHandler.deleteRecords(AdjmtDetl,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'doDeleteRecords'});
                
            }
            String loggedInUserId = UserInfo.getUserId();
            AdjmtLst =[Select id,createdById from T_ADJMT__c where id =:adjustmentId];
            
            if(AdjmtLst.size() >0){
                system.debug('createdById--'+AdjmtLst[0].createdById);
                if(loggedInUserId == AdjmtLst[0].createdById){
                    isSuccessFull =true;
                    message='Adjustment deleted Successfully.';
                    GenericDMLHandler.deleteRecords(AdjmtLst,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'doDeleteRecords'});
                    objectData.put('redirect',true);
                    objectData.put('eventParams','{"scope": "T_ADJMT__c"}');
                }else{
                    isSuccessFull=false;
                    message='The adjustment that you are trying to delete is created by another user. You do not have sufficient privileges to delete it.';
                    objectData.put('redirect',false);
                }
                
            }  
        }
        return new LightningServerResponse(isSuccessFull,message,objectData);
    }
    @AuraEnabled 
    public static LightningServerResponse doDeleteRecords(String adjustmentId, Boolean isNonAdjustment){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_NON_ADJMT_DETAIL__c> nonAdjmtDetl =new List<T_NON_ADJMT_DETAIL__c>();
        List<T_ADJMT_DETAIL__c> AdjmtDetl =new List<T_ADJMT_DETAIL__c>();
        if(!String.isBlank(adjustmentId)){
            
            nonAdjmtDetl =[Select id from T_NON_ADJMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId];
            if(nonAdjmtDetl.size() >0){
                //  delete nonAdjmtDetl;
                GenericDMLHandler.deleteRecords(nonAdjmtDetl,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'doDeleteRecords'});
            }
            
            AdjmtDetl =[Select id,Adjustment_Initiated__c from T_ADJMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId]; 
            if(AdjmtDetl.size() >0){
                GenericDMLHandler.deleteRecords(AdjmtDetl,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'doDeleteRecords'});
                // delete AdjmtDetl;
                
            }  
        }
        return new LightningServerResponse(true,'Done',objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getAuthObj(String authId){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_AUTH__c> authList = new  List<T_AUTH__c>();
        if(!String.isBlank(authId)){
            authList =[SELECT Id,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c from T_AUTH__c where id=:authId];  
        }
        if(!authList.isEmpty() && authList.size()>0){
            objectData.put('authObj',authList[0]);
        }
        return new LightningServerResponse(true,'Done',objectData);
    } 
    
    @AuraEnabled
    public static LightningServerResponse subPaymentCallOut(List<T_ADJMT_DETAIL__c> adjustmentDtlList){
        
        Map<String, Object> objectData = new map<String, Object>();
        //Removed unused variable on 5/13/2018 BG         
        Set<String> subpaymentIds= new Set<String>();
        for(T_ADJMT_DETAIL__c adj : adjustmentDtlList){
            subpaymentIds.add(adj.IDN_DETAIL_PMT_SUB__c);
        }

        String adjstmentType;
        if(!adjustmentDtlList.isEmpty()){
            for(T_ADJMT_DETAIL__c adjD : [SELECT Id, toLabel(IDN_ADJMT__r.CDE_TYPE_ADJMT__c) FROM T_ADJMT_DETAIL__c
                                          WHERE Id = :adjustmentDtlList[0].Id]){
                                              adjstmentType = adjD.IDN_ADJMT__r.CDE_TYPE_ADJMT__c;
                                          }
        }

        System.debug('Before subPaymentService::Limits.getHeapSize,Limits.getLimitHeapSize:'+'('+Limits.getHeapSize()+','+Limits.getLimitHeapSize()+')'); // Heap Size
        if(!subpaymentIds.isEmpty() && subpaymentIds.size()>0){
            if(!test.isRunningTest()){
                try{
                    HerokuService.subPaymentService(subpaymentIds,adjstmentType);
                }catch(Exception e){
                    system.debug('Error while calling sub payment detail Web service :'+e.getMessage());
                }
                
            }
        }
        System.debug('Before subPaymentService::Limits.getHeapSize,Limits.getLimitHeapSize:'+'('+Limits.getHeapSize()+','+Limits.getLimitHeapSize()+')'); // Heap Size
        objectData.put('adjustmentDtlList',adjustmentDtlList);
        return new LightningServerResponse(true,'Done',objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getRateTypeMap(batchsit_t_sub_pmt_detail__x subPaymentDetail, T_ADJMT_DETAIL__c adjustmentDetail){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        //Removed unused variable on 5/13/2018 BG    
        List<T_FISCAL_SCH__c> fiscalSchList = new List<T_FISCAL_SCH__c>();
        Map<String,List<PicklistOption>> rateTypeOptionsCareDateMap = new Map<String,List<PicklistOption>>();
        Date nullDate;
        Set<String> RateTypeSet = new Set<String>();
        String[] selFiscalSchRateOptionsCareDt;
        Map<String,String> rateTypeOptionsMap = new Map<String,String>();
        // Rate type from FieldUtility Object
        Schema.DescribeFieldResult fieldResult1 =
            Field_Utility__c.R00751__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple1){
            rateTypeOptionsMap.put(f.getValue(), f.getLabel());
            // rateTypeOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        }
        if(subPaymentDetail != null){
            Decimal subPmtId = Decimal.valueOf(subPaymentDetail.idn_pmt_sub__c);
            String countyId;
            String providerId;
            if(subPmtId != null){
                for(batchsit_t_sub_pmt__x sub :[Select id,idn_pmt_sub__c,ExternalId,idn_pmt__c,idn_pmt__r.IDN_PROVR__c,idn_pmt__r.CDE_COUNTY__c,idn_auth__r.CDE_COUNTY__c,idn_slot_contract__r.CDE_COUNTY__c
                                                from batchsit_t_sub_pmt__x where idn_pmt_sub__c =:subPmtId]){
                                                    providerId = sub.idn_pmt__r.IDN_PROVR__c;
                                                    countyId = sub.idn_auth__r.CDE_COUNTY__c != null ? sub.idn_auth__r.CDE_COUNTY__c : sub.idn_slot_contract__r.CDE_COUNTY__c;                                                    
                                                }   
            }
            
            if(!String.isBlank(countyId) && !String.isBlank(providerId)){
                fiscalSchList = [Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,
                                 IDN_AGRMT_FISCAL__r.ID_SERVICE__c,DTE_BEGIN_EFFV__c,
                                 CDE_RATE_TYPE__c from T_FISCAL_SCH__c 
                                 where IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:providerId 
                                 //BG CHATS-5357 and IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c ='OPN' 
                                 and IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: countyId];
            }            
            else if(Test.isRunningTest()){
                fiscalSchList = [Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,
                                 IDN_AGRMT_FISCAL__r.ID_SERVICE__c,DTE_BEGIN_EFFV__c,
                                 CDE_RATE_TYPE__c from T_FISCAL_SCH__c Limit 10];
            }
            
            for(T_FISCAL_SCH__c fiscalSch :fiscalSchList){
                if(((fiscalSch.DTE_BEGIN_EFFV__c <= subPaymentDetail.dte_care__c) || (fiscalSch.DTE_BEGIN_EFFV__c == nullDate)) &&
                   ((fiscalSch.DTE_END_EFFV__c >= subPaymentDetail.dte_care__c) || (fiscalSch.DTE_END_EFFV__c == nullDate))){
                       if(rateTypeOptionsCareDateMap.containsKey(subPaymentDetail.ExternalId)){
                           List<PicklistOption> rateTypeOpt = rateTypeOptionsCareDateMap.get(subPaymentDetail.ExternalId);
                           if(fiscalSch.CDE_RATE_TYPE__c != null){
                               selFiscalSchRateOptionsCareDt = fiscalSch.CDE_RATE_TYPE__c.split(';');
                               for(String selFiscalSchRateOption :selFiscalSchRateOptionsCareDt){
                                   if(rateTypeOptionsMap.containsKey(selFiscalSchRateOption) && !RateTypeSet.contains(rateTypeOptionsMap.get(selFiscalSchRateOption))){
                                       rateTypeOpt.add(new PicklistOption(
                                           rateTypeOptionsMap.get(selFiscalSchRateOption),
                                           selFiscalSchRateOption
                                       ));  
                                   }
                               }
                           }
                           rateTypeOptionsCareDateMap.put(subPaymentDetail.ExternalId,rateTypeOpt);
                       }
                       else{
                           List<PicklistOption> rateTypeOpt1 = new List<PicklistOption>();
                           if(fiscalSch.CDE_RATE_TYPE__c != null){
                               selFiscalSchRateOptionsCareDt = fiscalSch.CDE_RATE_TYPE__c.split(';');
                               for(String selFiscalSchRateOption :selFiscalSchRateOptionsCareDt){
                                   if(rateTypeOptionsMap.containsKey(selFiscalSchRateOption)){
                                       RateTypeSet.add(rateTypeOptionsMap.get(selFiscalSchRateOption));
                                       rateTypeOpt1.add(new PicklistOption(
                                           rateTypeOptionsMap.get(selFiscalSchRateOption),
                                           selFiscalSchRateOption
                                       ));
                                   }
                               }
                           }
                           rateTypeOptionsCareDateMap.put(subPaymentDetail.ExternalId,rateTypeOpt1); 
                       }
                   }
            }
        }
        
        objectData.put('rateTypeOptionsCareDateMap', rateTypeOptionsCareDateMap);
        
        return new LightningServerResponse(isSuccessful,'Success',objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getSelectedIPVRecord( Id IPVRecordId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        if(String.isNotBlank(IPVRecordId)){
            List<IPV_Information__c> IPVRecList = [Select id,Name,Individual_ID__c,CreatedById from IPV_Information__c where id=:IPVRecordId ];
            if(IPVRecList!=null && IPVRecList.size()>0){
                objectData.put('IPVRecord', IPVRecList[0]);
            }
        }
        system.debug('objectData--'+objectData);
        return new LightningServerResponse(isSuccessful,'Success',objectData);
    }
    @AuraEnabled
    public static LightningServerResponse doGetAddress(String adjustmentId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<T_ADJMT_RESPBL_PARTY__c> respPartyList = new List<T_ADJMT_RESPBL_PARTY__c>();
        List<T_ADJMT_ADDR__c> addressList = new List<T_ADJMT_ADDR__c>();
        List<T_ADJMT_ADDR__c> responsiblePartiesAddressList = new List<T_ADJMT_ADDR__c>();
        List<T_ADJMT__c> adjustments = [SELECT id,AMT_ADJMT__c,CDE_COUNTY__c,
                                        //fetching existing address
                                        (SELECT Id, ADR_LINE_1__c,Adjustment_Responsible_Party__c, Responsible_Party_Client_Id__c,Responsible_Party_Name__c,ADR_LINE_2__c, ADR_CITY__c, toLabel(ADR_STATE__c), ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r),
                                        //fetching existing responsible parties
                                        (SELECT Id, IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c,IPV_Info__c,IPV_Info__r.Name,Selected__c,Responsible_Party_Name__c,IDN_CLIENT__r.NAM_LAST__c FROM Adjustent5__r)
                                        FROM T_ADJMT__c 
                                        WHERE id=:adjustmentId];
        if(!adjustments.isEmpty()){
            for(T_ADJMT_RESPBL_PARTY__c resp :adjustments[0].Adjustent5__r){
                //  respPartyList.add(resp);
            }
            for(T_ADJMT_ADDR__c resp :adjustments[0].Adjustment__r){
                responsiblePartiesAddressList.add(resp);
                addressList.add(resp);
                
            }
            isSuccessful = true;
        }
        //  objectData.put('responsiblePartyList',respPartyList);
        objectData.put('addressList',addressList);
        objectData.put('responsiblePartiesAddressList',responsiblePartiesAddressList);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse doGetInitData(String adjustmentId){
        Map<Id,T_ADJMT_RESPBL_PARTY__c> respPartyMap = new Map<Id,T_ADJMT_RESPBL_PARTY__c>();
        List<T_ADJMT_RESPBL_PARTY__c> respPartyList = new List<T_ADJMT_RESPBL_PARTY__c>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        // New
        Map<Id,T_ADJMT_ADDR__c> addressMap = new Map<Id,T_ADJMT_ADDR__c>();
        List<T_ADJMT_ADDR__c> addressList = new List<T_ADJMT_ADDR__c>(); 
        List<T_ADJMT_ADDR__c> responsiblePartiesAddressList = new List<T_ADJMT_ADDR__c>();
        Boolean isEditableAddress = true;
        List<T_SBSD_CASE__c> caseRec = new List<T_SBSD_CASE__c>(); 
        // end
        List<T_ADJMT__c> adjustments = [SELECT id,AMT_ADJMT__c,CDE_COUNTY__c,Recordtype.Name,
                                        //fetching Adjustment information
                                        toLabel(CDE_TYPE_ADJMT__c), toLabel(CDE_AGNST_ADJMT__c), toLabel(CDE_STATUS_ADJMT__c),IND_REIMBSL_PMT__c,  IDN_CASE__c, IDN_CASE__r.Name,
                                        DTE_END_ADJMT__c, RecordType.DeveloperName, Name, RecordTypeId, DTE_START_ADJMT__c,
                                        DTE_DISCV_ADJMT_ORIG__c, toLabel(CDE_EDIT_REASON__c), Outstanding_Recovery_Balance__c, DTE_EFFV_RECOVERY__c,
                                        //fields for first page
                                        toLabel(IND_ORD_COURT_ADJMT__c), toLabel(CDE_REASON__c), toLabel(CDE_TYPE_CLSFN__c),toLabel(Recovery_Initiative__c),
                                        //fetching provider information
                                        IDN_PROVR__r.NAM_FACILITY__c, IDN_PROVR__c, IDN_PROVR__r.Name, IDN_PROVR__r.ADR_LINE1__c, IDN_PROVR__r.ADR_CITY__c, IDN_PROVR__r.ADR_STATE__c, IDN_PROVR__r.ADR_ZIP__c,
                                        IDN_PROVR__r.ADR_LINE1_MLNG__c, IDN_PROVR__r.ADR_CITY_MLNG__c, IDN_PROVR__r.ADR_STATE_MLNG__c, IDN_PROVR__r.ADR_ZIP_MLNG__c,
                                        //fetching existing address
                                        (SELECT Id, ADR_LINE_1__c,Adjustment_Responsible_Party__c, Responsible_Party_Client_Id__c,Responsible_Party_Name__c,ADR_LINE_2__c, ADR_CITY__c, toLabel(ADR_STATE__c), ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r),
                                        //fetching existing responsible parties
                                        (SELECT Id, IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c,IPV_Info__c,IPV_Info__r.Name,Selected__c,Responsible_Party_Name__c,IDN_CLIENT__r.NAM_LAST__c FROM Adjustent5__r)
                                        FROM T_ADJMT__c 
                                        WHERE id=:adjustmentId];
        if(!adjustments.isEmpty()){
            //changes added for view mode Editable Address scenario -> CCCAP-10780
            if(adjustments[0].Recordtype.Name == 'Finalized'){
	            isEditableAddress = adjustments[0].CDE_STATUS_ADJMT__c == 'Calculation Complete';    
            }else{
                if(adjustments[0].CDE_STATUS_ADJMT__c =='Satisfied' || adjustments[0].CDE_STATUS_ADJMT__c =='Paid'){
                    isEditableAddress = false;
                }                
            }
            if(adjustments[0].IDN_PROVR__c != null ){
                isEditableAddress = false;
            }
            objectData.put('isEditableAddress',isEditableAddress);
            for(T_ADJMT_RESPBL_PARTY__c resp :adjustments[0].Adjustent5__r){
                respPartyList.add(resp);
                respPartyMap.put(resp.IDN_CLIENT__c,resp);                
            }
            for(T_ADJMT_ADDR__c resp :adjustments[0].Adjustment__r){
                addressList.add(resp);
                responsiblePartiesAddressList.add(resp);
                if(resp.Responsible_Party_Client_Id__c != null){
                    addressMap.put(resp.Responsible_Party_Client_Id__c,resp);
                }
            }
            isSuccessful = true;
            objectData.put('adjustment',adjustments.get(0));
            List<T_NON_ADJMT_DETAIL__c> nonAdjustmentDetail = [SELECT Id,IDN_AUTH__c,AMT_DETAIL_ADJMT__c,IDN_PROG_FNDG__c, IDN_AUTH__r.Name,
                                                               IDN_AUTH__r.IDN_CLIENT__r.NAM_FIRST__c, IDN_AUTH__r.IDN_CLIENT__r.NAM_LAST__c
                                                               FROM T_NON_ADJMT_DETAIL__c
                                                               WHERE IDN_ADJMT__c=: adjustmentId];
            if(nonAdjustmentDetail.size()>0) {
                objectData.put('nonAdjustmentDetail',nonAdjustmentDetail);
            }
            List<adjustmentWrapper> adjustmentDtlWarp = getAdjustmentDetails(adjustmentId);
            if(adjustmentDtlWarp != null  && adjustmentDtlWarp.size()>0) {
                objectData.put('adjustmentDtlWarp',adjustmentDtlWarp);
            }
            Map<String, List<T_ADJMT_DETAIL__c>> adjustDetailMap = getAdjustmentDetailsMap(adjustmentId);
            Map<String, List<batchsit_t_indiv_rat_fees__x> > currentUtilizationMap = new Map<String, List<batchsit_t_indiv_rat_fees__x>  >();
            Set<String> childIds = new Set<String>();
            for(String subPay : adjustDetailMap.keySet()){
                for(T_ADJMT_DETAIL__c  adj :adjustDetailMap.get(subPay)){
                    childIds.add(adj.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c);                    
                }
            }
            if(!childIds.isEmpty()){
                for(batchsit_t_indiv_rat_fees__x rateFee : [SELECT id,ExternalId,idn_indiv_rat_fee__c,idn_client__c,amt_act_paid__c,dte_care__c,createddate__c,dte_paid__c,amt_reg_paid__c,amt_reg_remaining__c,dte_begin_effev__c,dte_end_effev__c,
                                                            amt_act_remaining__c,amt_trans_paid__c,amt_trans_remaining__c,idn_provr__c from batchsit_t_indiv_rat_fees__x where idn_client__c IN:childIds and dte_begin_effev__c <=:adjustments[0].DTE_START_ADJMT__c and dte_end_effev__c >=:adjustments[0].DTE_END_ADJMT__c  order by ExternalId DESC]){
                                                                String dateStr = String.valueOf(rateFee.dte_care__c).split(' ')[0];
                                                                String keyStr = rateFee.idn_client__c;// +'-'+ dateStr +'-'+ rateFee.idn_provr__c;
                                                                if(keyStr != null && !currentUtilizationMap.containsKey(keyStr)){
                                                                    currentUtilizationMap.put(keyStr,new List<batchsit_t_indiv_rat_fees__x>{rateFee});
                                                                }
                                                            } 
            }
            if(!currentUtilizationMap.isEmpty()){
                objectData.put('currentUtilizationMap', currentUtilizationMap);
            }
            if(adjustDetailMap!= null  && adjustDetailMap.size()>0) {
                objectData.put('adjustDetailMap',adjustDetailMap);
            }
            List<PicklistOption> rateTypeOptions = new List<PicklistOption>();
            Schema.DescribeFieldResult fieldResult = T_ADJMT_DETAIL__c.CDE_TYPE_RATE_ADJD__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();         
            for(Schema.PicklistEntry f : ple){
                rateTypeOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
            }  
            if(!rateTypeOptions.isEmpty()){
                objectData.put('rateTypeOptions', rateTypeOptions);
                message = null;
            }
            // Care Unit from FieldUtility Object - Bug fix 2929
            Map<String, String> careUnitTypeOptionsMap = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult2 = Field_Utility__c.R00715__c.getDescribe();
            List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();            
            for(Schema.PicklistEntry f : ple2){
                careUnitTypeOptionsMap.put(f.getValue(), f.getLabel());
            } 
            objectData.put('careUnitTypeOptionsMap', careUnitTypeOptionsMap);
            if(adjustments.get(0).IDN_CASE__c != null) {
                caseRec = [SELECT Id, (SELECT Id, ADR_LINE_1__c, ADR_LINE_2__c,ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c  FROM T_SBSD_CASE3__r WHERE CDE_TYPE_ADR__c = 'MAL' AND ((DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null) AND (DTE_BEGIN_EFFV__c <= TODAY)) LIMIT 1) FROM T_SBSD_CASE__c WHERE Id=:adjustments.get(0).IDN_CASE__c LIMIT 1];
                if(caseRec.size()>0) {
                    objectData.put('caseRec', caseRec[0]);       
                }
                List<T_SBSD_CASE_INDIV__c> caseIndiv = [SELECT Id, IDN_CLIENT__c
                                                        FROM T_SBSD_CASE_INDIV__c
                                                        WHERE IDN_CASE__c=:adjustments.get(0).IDN_CASE__c AND IND_CRTKR__c =: true AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)];
                if(caseIndiv.size()>0 && caseIndiv.get(0).IDN_CLIENT__c != null) {
                    List<T_SBSD_INDIV__c> individualObj = [SELECT Id, NAM_FIRST__c, NAM_LAST__c FROM T_SBSD_INDIV__c WHERE Id=:caseIndiv.get(0).IDN_CLIENT__c];
                    if(individualObj.size()>0) {
                        objectData.put('individualObj',individualObj.get(0));
                    }
                }
            } 
            
            //logic to fetch responsible parties based on age, primary caretaker & relationship conditions
            if(adjustments.get(0).CDE_TYPE_ADJMT__c == 'Recovery' && String.isNotEmpty(adjustments.get(0).IDN_CASE__c)){
                List<Map<String,String>> responsibleParties = new List<Map<String,String>>();
                for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT Id, IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, IDN_CLIENT__r.DTE_DOB__c, IDN_CLIENT__r.Is_Primary_Parent_Caretaker__c, IDN_CLIENT__r.Has_Allowed_Relationship__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :adjustments.get(0).IDN_CASE__c AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY )]){
                    Boolean validIndividual = false;
                    T_ADJMT_RESPBL_PARTY__c resObj = new T_ADJMT_RESPBL_PARTY__c();
                    T_ADJMT_ADDR__c addrObj = new T_ADJMT_ADDR__c();
                    Integer age = (adjustments.get(0).DTE_END_ADJMT__c.year() - caseIndiv.IDN_CLIENT__r.DTE_DOB__c.year()) - 
                        (adjustments.get(0).DTE_END_ADJMT__c.month()<caseIndiv.IDN_CLIENT__r.DTE_DOB__c.month() || (adjustments.get(0).DTE_END_ADJMT__c.month()==caseIndiv.IDN_CLIENT__r.DTE_DOB__c.month() 
                                                                                                                    && adjustments.get(0).DTE_END_ADJMT__c.day()<caseIndiv.IDN_CLIENT__r.DTE_DOB__c.day())?1:0);
                    if(age>18 || caseIndiv.IDN_CLIENT__r.Is_Primary_Parent_Caretaker__c || (age<=18 && caseIndiv.IDN_CLIENT__r.Has_Allowed_Relationship__c)){
                        validIndividual = true;
                    }
                    if(validIndividual){
                        if(!respPartyMap.containsKey(caseIndiv.IDN_CLIENT__c)){
                            resObj.IDN_CLIENT__c=caseIndiv.IDN_CLIENT__c;
                            resObj.IDN_ADJMT__c=adjustmentId;
                            resObj.IDN_CASE__c =adjustments.get(0).IDN_CASE__c;
                            resObj.Selected__c =false;
                            resObj.Responsible_Party_Name__c =caseIndiv.IDN_CLIENT__r.NAM_LAST__c+', '+caseIndiv.IDN_CLIENT__r.NAM_FIRST__c;
                            respPartyList.add(resObj);
                            system.debug('resObj---'+resObj);
                        }
                        if(!addressMap.containsKey(caseIndiv.IDN_CLIENT__c)){
                            addrObj.IDN_ADJMT__c=adjustmentId;
                            addrObj.Responsible_Party_Client_Id__c=caseIndiv.IDN_CLIENT__c;
                            addrObj.Responsible_Party_Name__c=caseIndiv.IDN_CLIENT__r.NAM_LAST__c+', '+caseIndiv.IDN_CLIENT__r.NAM_FIRST__c;
                            // Prepopulating the address
                            if(!caseRec[0].T_SBSD_CASE3__r.isEmpty()){
                                addrObj.ADR_LINE_1__c = caseRec[0].T_SBSD_CASE3__r[0].ADR_LINE_1__c;
                                addrObj.ADR_LINE_2__c = caseRec[0].T_SBSD_CASE3__r[0].ADR_LINE_2__c;
                                addrObj.ADR_CITY__c = caseRec[0].T_SBSD_CASE3__r[0].ADR_CITY__c;
                                addrObj.ADR_STATE__c = caseRec[0].T_SBSD_CASE3__r[0].ADR_STATE__c;
                                if(String.isNotBlank(caseRec[0].T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c)){
                                    addrObj.ADR_ZIP_MAIN__c = String.valueOf(caseRec[0].T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c);
                                }
                                if(String.isNotBlank(caseRec[0].T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c)){
                                    addrObj.ADR_ZIP_EXTN__c = String.valueOf(caseRec[0].T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c);
                                }  
                                // end
                                addressList.add(addrObj);                                
                            }
                        }
                        responsibleParties.add(new Map<String,String>{'label'=>caseIndiv.IDN_CLIENT__r.NAM_LAST__c+', '+caseIndiv.IDN_CLIENT__r.NAM_FIRST__c, 'value'=>caseIndiv.IDN_CLIENT__c});
                    }
                    
                }
                objectData.put('responsibleParties',responsibleParties);
                objectData.put('responsiblePartyList',respPartyList);
                objectData.put('addressList',addressList);
                objectData.put('responsiblePartiesAddressList',responsiblePartiesAddressList);
            }
        } else {
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse upsertResponsiblePartiesAddress(Id adjustmentId,List<T_ADJMT_ADDR__c> responsiblePartiesAddressList) {
        Boolean isSuccessful = false;
        savepoint sp = database.setsavepoint();
        try{
            List<SObject> lstRecordsToBeInserted = new List<SObject>();
            List<SObject> lstRecordsToBeUpdated = new List<SObject>();
            List<SObject> responsiblePartiesAddrToBeDeleted = new List<SObject>();
            Set<Id> individualIds = new Set<Id>();
            Set<Id> existingIndividualsAsResponsibleParties = new Set<Id>();
            Map<String,T_ADJMT_ADDR__c> repAddrMap = new  Map<String,T_ADJMT_ADDR__c>();
            Map<String,T_ADJMT_ADDR__c> existingIndivIPVMap = new  Map<String,T_ADJMT_ADDR__c>();
            List<T_ADJMT__c> adjustmentWithResponsiblePartiesAddr = [SELECT Id, IDN_CASE__c, DTE_END_ADJMT__c,DTE_START_ADJMT__c,IDN_PROVR__c,CDE_COUNTY__c, 
                                                                     (SELECT Id, ADR_LINE_1__c, ADR_LINE_2__c,Responsible_Party_Client_Id__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r) 
                                                                     FROM T_ADJMT__c WHERE id=:adjustmentId LIMIT 1];
            if(responsiblePartiesAddressList!= null && responsiblePartiesAddressList.size()>0){
                for(T_ADJMT_ADDR__c res :responsiblePartiesAddressList){
                    individualIds.add(res.Responsible_Party_Client_Id__c);
                    repAddrMap.put(res.Responsible_Party_Client_Id__c, res);
                    /*if(res.Adjustment_Responsible_Party__r.Selected__c){
individualIds.add(res.Responsible_Party_Client_Id__c);
}*/
                    
                }
            }
            if(!adjustmentWithResponsiblePartiesAddr.isEmpty()){
                for(T_ADJMT_ADDR__c responsibleParty:adjustmentWithResponsiblePartiesAddr.get(0).Adjustment__r){
                    existingIndividualsAsResponsibleParties.add(responsibleParty.Responsible_Party_Client_Id__c);
                    if(!individualIds.contains(responsibleParty.Responsible_Party_Client_Id__c)){
                        responsiblePartiesAddrToBeDeleted.add(responsibleParty);
                    } else{
                        existingIndivIPVMap.put(responsibleParty.Responsible_Party_Client_Id__c, responsibleParty);
                    }      
                }
            }
            if(!responsiblePartiesAddrToBeDeleted.isEmpty()){
                
                GenericDMLHandler.deleteRecords(responsiblePartiesAddrToBeDeleted,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
                
            }
            if(responsiblePartiesAddressList!=null && !responsiblePartiesAddressList.isEmpty()){
                
                
                for(T_ADJMT_ADDR__c addr :responsiblePartiesAddressList){
                    if(existingIndividualsAsResponsibleParties.contains(addr.Responsible_Party_Client_Id__c)){
                        lstRecordsToBeUpdated.add(addr);
                    }else{
                        lstRecordsToBeInserted.add(addr);
                    }
                }
            }
            system.debug('lstRecordsToBeUpdated--'+lstRecordsToBeUpdated);
            system.debug('lstRecordsToBeInserted--'+lstRecordsToBeInserted);
            if(!lstRecordsToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(lstRecordsToBeInserted,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
            } 
            if(!lstRecordsToBeUpdated.isEmpty()){
                GenericDMLHandler.updateRecords(lstRecordsToBeUpdated,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
            } 
            isSuccessful = true;
            return new LightningServerResponse(isSuccessful,null,null);
        }catch(DMLException ex){
            database.rollback(sp);
            return new LightningServerResponse(isSuccessful,ex.getDMLMessage(0),null);
        }catch (Exception e) {
            database.rollback(sp);
            return new LightningServerResponse(isSuccessful,e.getMessage(),null);
        }
    }
    @AuraEnabled
    public static Map<String,List<T_ADJMT_DETAIL__c>> getAdjustmentDetailsMap(String adjustmentId){
        Map<String,List<T_ADJMT_DETAIL__c>> adjustDetailMap = new Map<String,List<T_ADJMT_DETAIL__c>>();
        //Fetching adjustment details
        for(T_ADJMT_DETAIL__c adjustDetail : [SELECT Id,AMT_DETAIL_ADJMT__c,toLabel(IDN_PROG_FNDG__c),IDN_ADJMT__c,NBR_HOURS_ATTND_ADJD__c,Activity_Fee_Paid__c,Registration_Fee_Paid__c,Transportation_Fee_Paid__c,
                                              IDN_DETAIL_PMT_SUB__c,NBR_HOURS_AUTH_ADJD__c,AMT_PAID_RATE_ADJD__c,toLabel(CDE_TYPE_RATE_ADJD__c),IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,
                                              AMT_PAID_RATE_ORIG__c,NBR_HOURS_ATNDT_ORIG__c,NBR_HOURS_AUTH_ORIG__c,DTE_CARE__c, IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_slot_contract__c,
                                              IND_OVERRIDE__c,CDE_STATUS_DETAIL_ADJMT__c,Adjustment_Initiated__c, IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__c, CDE_TYPE_UNIT_ADJD__c, CDE_CARE_LEVEL_ADJD__c
                                              //fetching sub payment IDN_DETAIL_PMT_SUB__r.amt_total_pmt_sub__c
                                              // IDN_DETAIL_PMT_SUB__r.amt_rate_pmt_sub__c,IDN_DETAIL_PMT_SUB__r.amt_copay_pmt_sub__c,IDN_DETAIL_PMT_SUB__r.idn_auth__c, 
                                              //    IDN_DETAIL_PMT_SUB__r.idn_auth__r.NAM_LAST__c,IDN_DETAIL_PMT_SUB__r.idn_auth__r.NAM_FIRST__c,
                                              FROM T_ADJMT_DETAIL__c WHERE IDN_ADJMT__c = :adjustmentId])
        {
            if(adjustDetail.IDN_DETAIL_PMT_SUB__c != null){
                if(adjustDetailMap.containsKey(adjustDetail.IDN_DETAIL_PMT_SUB__c)){
                    List<T_ADJMT_DETAIL__c> rec1 = adjustDetailMap.get(adjustDetail.IDN_DETAIL_PMT_SUB__c);
                    rec1.add(adjustDetail);
                    adjustDetailMap.put(adjustDetail.IDN_DETAIL_PMT_SUB__c, rec1);
                }else{
                    List<T_ADJMT_DETAIL__c> rec = new List<T_ADJMT_DETAIL__c>();
                    rec.add(adjustDetail);
                    adjustDetailMap.put(adjustDetail.IDN_DETAIL_PMT_SUB__c, rec);
                }
            }
        }
        return adjustDetailMap;
    }
    
    @AuraEnabled
    public static LightningServerResponse adjustmentDetails(String adjustmentId){
        Map<String,List<T_ADJMT_DETAIL__c>> adjustDetailMap = new Map<String,List<T_ADJMT_DETAIL__c>>();
        Boolean isSuccessful =true;
        String message;
        Map<String, Object> objectData = new map<String, Object>();
        try{
            List<adjustmentWrapper>  adjustmentDtlWarp = getAdjustmentDetails(adjustmentId);
            adjustDetailMap = getAdjustmentDetailsMap(adjustmentId);
            if(adjustmentId != null){
                if(adjustmentDtlWarp!= null  && adjustmentDtlWarp.size()>0) {
                    objectData.put('adjustmentDtlWarp',adjustmentDtlWarp);
                    isSuccessful = true;
                }  
                if(adjustDetailMap!= null  && adjustDetailMap.size()>0) {
                    objectData.put('adjustDetailMap',adjustDetailMap);
                    isSuccessful = true;
                }
            }
        }
        catch(Exception e){
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'AdjsutmentFlowApxCtrl','Method__c'=>'adjustmentDetails'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static List<adjustmentWrapper> getAdjustmentDetails(String adjustmentId){
        Map<String,List<T_ADJMT_DETAIL__c>> adjustDetailMap = new Map<String,List<T_ADJMT_DETAIL__c>>();
        //Removed unused variable on 5/13/2018 BG         
        Map<String,String> rateTypeOptionsMap = new Map<String,String>();
        Map<String,String> careUnitTypeOptionsMap = new Map<String,String>();
        Map<String,String> careLevelOptionsMap = new Map<String,String>();
        //Removed unused variable on 5/13/2018 BG   
        // Rate types and care units
        Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00751__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple1){
            rateTypeOptionsMap.put(f.getValue(), f.getLabel());
            // rateTypeOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        }   
        // Care Unit from FieldUtility Object
        Schema.DescribeFieldResult fieldResult2 = Field_Utility__c.R00715__c.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for(Schema.PicklistEntry f : ple2){
            careUnitTypeOptionsMap.put(f.getValue(), f.getLabel());
        }
        // Care Level from Slot Contract Object
        Schema.DescribeFieldResult fieldResult3 = T_SLOT_CONTRACT__c.CDE_CARE_LEVEL__c.getDescribe();
        List<Schema.PicklistEntry> ple3 = fieldResult3.getPicklistValues();
        for(Schema.PicklistEntry f : ple3){
            careLevelOptionsMap.put(f.getValue(), f.getLabel());
        }
        
        //Fetching adjustment details
        for(T_ADJMT_DETAIL__c adjustDetail : [SELECT Id,AMT_DETAIL_ADJMT__c,toLabel(IDN_PROG_FNDG__c),IDN_ADJMT__c,NBR_HOURS_ATTND_ADJD__c,Activity_Fee_Paid__c,Registration_Fee_Paid__c,Transportation_Fee_Paid__c,
                                              IDN_DETAIL_PMT_SUB__c,NBR_HOURS_AUTH_ADJD__c,AMT_PAID_RATE_ADJD__c,toLabel(CDE_TYPE_RATE_ADJD__c),IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,
                                              AMT_PAID_RATE_ORIG__c,NBR_HOURS_ATNDT_ORIG__c,NBR_HOURS_AUTH_ORIG__c,DTE_CARE__c, IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_slot_contract__c, 
                                              IND_OVERRIDE__c,CDE_STATUS_DETAIL_ADJMT__c,Adjustment_Initiated__c, IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__c, CDE_TYPE_UNIT_ADJD__c, CDE_CARE_LEVEL_ADJD__c
                                              //fetching sub payment IDN_DETAIL_PMT_SUB__r.amt_total_pmt_sub__c
                                              // IDN_DETAIL_PMT_SUB__r.amt_rate_pmt_sub__c,IDN_DETAIL_PMT_SUB__r.amt_copay_pmt_sub__c,IDN_DETAIL_PMT_SUB__r.idn_auth__c, 
                                              //    IDN_DETAIL_PMT_SUB__r.idn_auth__r.NAM_LAST__c,IDN_DETAIL_PMT_SUB__r.idn_auth__r.NAM_FIRST__c,
                                              FROM T_ADJMT_DETAIL__c WHERE IDN_ADJMT__c=: adjustmentId]){
                                                  if(adjustDetail.IDN_DETAIL_PMT_SUB__c != null){
                                                      if(adjustDetailMap.containsKey(adjustDetail.IDN_DETAIL_PMT_SUB__c)){
                                                          List<T_ADJMT_DETAIL__c> rec1 = adjustDetailMap.get(adjustDetail.IDN_DETAIL_PMT_SUB__c);
                                                          rec1.add(adjustDetail);
                                                          adjustDetailMap.put(adjustDetail.IDN_DETAIL_PMT_SUB__c, rec1);
                                                      }else{
                                                          List<T_ADJMT_DETAIL__c> rec = new List<T_ADJMT_DETAIL__c>();
                                                          rec.add(adjustDetail);
                                                          adjustDetailMap.put(adjustDetail.IDN_DETAIL_PMT_SUB__c, rec);
                                                      }
                                                  }
                                              }
        // Vai - Commenting this code as it does a full table search and is crashing in SITFull - Bug fix 3552
        /*for(batchsit_t_sub_pmt__x sub :[select ExternalId,idn_pmt_sub__c,idn_auth__c,idn_auth__r.NAM_FIRST__c,
idn_auth__r.NAM_LAST__c from batchsit_t_sub_pmt__x ]){
if(subPayMap.containsKey(sub.idn_pmt_sub__c)){
List<batchsit_t_sub_pmt__x>  set1 = subPayMap.get(sub.idn_pmt_sub__c);
set1.add(sub);
subPayMap.put(sub.idn_pmt_sub__c, set1);
}else{
List<batchsit_t_sub_pmt__x> set2 = new List<batchsit_t_sub_pmt__x>();
set2.add(sub);
subPayMap.put(sub.idn_pmt_sub__c, set2);
}
subPaySet.add(sub.idn_pmt_sub__c);
} */
        List<adjustmentWrapper> adjustmentDtlWarp = new List<adjustmentWrapper>();
        
        Set<String> alreadyExistingSubPaymentExternalIds = new Set<String>();
        List<batchsit_t_sub_pmt_detail__x> subPmtDtlList = new List<batchsit_t_sub_pmt_detail__x>();
        List<batchsit_t_sub_pmt_detail__x> subPmtDtlListClone = new List<batchsit_t_sub_pmt_detail__x>();
        List<String> allSubPaymentExternalIds = new List<String>();
        Integer subPmtDtlStartIndex =0;
        Integer subPmtDtlEndIndex =100;
        Integer subPmtCountTemp =1;
        allSubPaymentExternalIds.addAll(adjustDetailMap.keySet());
        system.debug('allSubPaymentExternalIds--'+allSubPaymentExternalIds.size());
        Integer subPmtCount =Math.mod(allSubPaymentExternalIds.size(), 100);
        Integer subPmtLastCount =(allSubPaymentExternalIds.size())/100;
        system.debug('subPmtLastCount--'+subPmtLastCount);
        system.debug('subPmtLastCount--'+subPmtLastCount);
        system.debug('subPmtCount--'+subPmtCount);
        //String subPmtQuery ='Select Id, ExternalId,amt_copay__c,amt_rate__c,idn_pmt_sub__c,idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name, idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name,idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c, idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c,idn_pmt_sub__r.idn_auth__r.NAM_LAST__c,idn_prog_fndg__c,amt_total__c,cde_level_care__c,cde_time_trdnl__c,cde_type_unit_care__c,dte_care__c,cde_unit_care_exptd__c,cde_unit_care_actual__c from batchsit_t_sub_pmt_detail__x';
        if(allSubPaymentExternalIds.size()<=100){
            String subPmtQuery ='Select Id, ExternalId,amt_copay__c,amt_rate__c,idn_pmt_sub__c,idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name, idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name,idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c, idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c,idn_pmt_sub__r.idn_auth__r.NAM_LAST__c,idn_prog_fndg__c,amt_total__c,cde_level_care__c,cde_time_trdnl__c,cde_type_unit_care__c,dte_care__c,cde_unit_care_exptd__c,cde_unit_care_actual__c,amt_act_paid__c,amt_reg_paid__c,amt_trans_paid__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.External_ID__c, idn_pmt_sub__r.idn_slot_contract__r.Name, amt_slot_paid__c,ind_0_36_months_enroll_pmt__c from batchsit_t_sub_pmt_detail__x';
            subPmtQuery = subPmtQuery+' where ExternalId IN: allSubPaymentExternalIds' ;
            subPmtDtlList = DataBase.query(subPmtQuery);
        }else{
            while(subPmtCountTemp<=subPmtLastCount && Limits.getQueries()<90){
                system.debug('subPmtCountTemp--'+subPmtCountTemp);
                system.debug('subPmtDtlStartIndex--'+subPmtDtlStartIndex);
                system.debug('subPmtDtlEndIndex--'+subPmtDtlEndIndex);
                for(Integer i=subPmtDtlStartIndex ;i< subPmtDtlEndIndex;i++){
                    alreadyExistingSubPaymentExternalIds.add(allSubPaymentExternalIds[i]);
                }
                if(alreadyExistingSubPaymentExternalIds.size()>0){
                    String subPmtQuery ='Select Id, ExternalId,amt_copay__c,amt_rate__c,idn_pmt_sub__c,idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name, idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name,idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c, idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c,idn_pmt_sub__r.idn_auth__r.NAM_LAST__c,idn_prog_fndg__c,amt_total__c,cde_level_care__c,cde_time_trdnl__c,cde_type_unit_care__c,dte_care__c,cde_unit_care_exptd__c,cde_unit_care_actual__c,amt_act_paid__c,amt_reg_paid__c,amt_trans_paid__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.External_ID__c, idn_pmt_sub__r.idn_slot_contract__r.Name, amt_slot_paid__c,ind_0_36_months_enroll_pmt__c from batchsit_t_sub_pmt_detail__x';
                    subPmtQuery = subPmtQuery+' where ExternalId IN: alreadyExistingSubPaymentExternalIds';
                    subPmtDtlListClone = DataBase.query(subPmtQuery);
                    subPmtDtlList.addAll(subPmtDtlListClone);
                    alreadyExistingSubPaymentExternalIds.clear();
                    subPmtDtlListClone.clear();
                    subPmtDtlStartIndex=subPmtDtlEndIndex;
                    subPmtCountTemp++;
                    subPmtDtlEndIndex = subPmtCountTemp*100;
                }
            }
            if(subPmtCount>0 && Limits.getQueries()<90){
                for(Integer i=subPmtDtlStartIndex ;i< allSubPaymentExternalIds.size();i++){
                    alreadyExistingSubPaymentExternalIds.add(allSubPaymentExternalIds[i]);
                }
                if(alreadyExistingSubPaymentExternalIds.size()>0){
                    String subPmtQuery ='Select Id, ExternalId,amt_copay__c,amt_rate__c,idn_pmt_sub__c,idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name, idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name,idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c, idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c,idn_pmt_sub__r.idn_auth__r.NAM_LAST__c,idn_prog_fndg__c,amt_total__c,cde_level_care__c,cde_time_trdnl__c,cde_type_unit_care__c,dte_care__c,cde_unit_care_exptd__c,cde_unit_care_actual__c,amt_act_paid__c,amt_reg_paid__c,amt_trans_paid__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.External_ID__c, idn_pmt_sub__r.idn_slot_contract__r.Name, amt_slot_paid__c, ind_0_36_months_enroll_pmt__c from batchsit_t_sub_pmt_detail__x';
                    subPmtQuery = subPmtQuery+' where ExternalId IN:alreadyExistingSubPaymentExternalIds';
                    subPmtDtlListClone = DataBase.query(subPmtQuery);
                    subPmtDtlList.addAll(subPmtDtlListClone);
                }
            }
        }
        system.debug('subPmtDtlList--'+subPmtDtlList);
        for(batchsit_t_sub_pmt_detail__x sub :subPmtDtlList){
            if(adjustDetailMap.containsKey(sub.ExternalId)){
                sub.cde_type_unit_care__c = rateTypeOptionsMap.get(sub.cde_type_unit_care__c);
                sub.cde_time_trdnl__c = careUnitTypeOptionsMap.get(sub.cde_time_trdnl__c);
                sub.cde_level_care__c = careLevelOptionsMap.get(sub.cde_level_care__c);
                for(T_ADJMT_DETAIL__c lst : adjustDetailMap.get(sub.ExternalId)){
                    String childName='';
                    // Vai - Commenting this code for bug fix 3552
                    /*Decimal strToDec = decimal.valueOf(sub.idn_pmt_sub__c);
//
if(subPayMap.containsKey(strToDec)){
List<batchsit_t_sub_pmt__x> subPayLst = subPayMap.get(strToDec);
if(subPayLst != null){
childName = subPayLst[0].idn_auth__r.NAM_FIRST__c +' '+subPayLst[0].idn_auth__r.NAM_LAST__c;
//
}
}*/
                childName = sub.idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c +' '+sub.idn_pmt_sub__r.idn_auth__r.NAM_LAST__c; 
                    adjustmentWrapper wrap = new adjustmentWrapper();
                    wrap.subPaymentDetails = sub;
                    
                    wrap.ajustmentDetails = lst; 
                    
                    wrap.childName =childName;
                    adjustmentDtlWarp.add(wrap);
                } 
            }
        }
        
        return adjustmentDtlWarp;
    }
    
    @AuraEnabled
    public static LightningServerResponse upsertResponsibleParties( Id adjustmentId,List<T_ADJMT_RESPBL_PARTY__c> responsiblePartyList) {
        Boolean isSuccessful = false;
        List<SObject> responsiblePartiesToBeDeleted = new List<SObject>();
        List<SObject> responsiblePartiesToBeInserted = new List<SObject>();
        List<SObject> responsiblePartiesToBeUpdated = new List<SObject>();
        List<T_ADJMT__c> adjustmentWithResponsibleParties = [SELECT Id, IDN_CASE__c, DTE_END_ADJMT__c,DTE_START_ADJMT__c,IDN_PROVR__c,CDE_COUNTY__c, 
                                                             (SELECT IDN_CLIENT__c,IPV_Info__c,IPV_Info__r.Name,Selected__c,Responsible_Party_Name__c FROM Adjustent5__r) 
                                                             FROM T_ADJMT__c WHERE id=:adjustmentId LIMIT 1];
        Set<Id> existingIndividualsAsResponsibleParties = new Set<Id>();
        Map<Id,T_ADJMT_RESPBL_PARTY__c> indivIPVMap = new Map<Id,T_ADJMT_RESPBL_PARTY__c>();
        Map<Id,T_ADJMT_RESPBL_PARTY__c> existingIndivIPVMap = new Map<Id,T_ADJMT_RESPBL_PARTY__c>();
        List<Id> individualIds = new List<Id>();
        if(responsiblePartyList!= null && responsiblePartyList.size()>0){
            for(T_ADJMT_RESPBL_PARTY__c res :responsiblePartyList){
                indivIPVMap.put(res.IDN_CLIENT__c, res);
                if(res.Selected__c){
                    individualIds.add(res.IDN_CLIENT__c);
                }
                
            }
        }
        if(!adjustmentWithResponsibleParties.isEmpty()){
            for(T_ADJMT_RESPBL_PARTY__c responsibleParty:adjustmentWithResponsibleParties.get(0).Adjustent5__r){
                existingIndividualsAsResponsibleParties.add(responsibleParty.IDN_CLIENT__c);
                if(!individualIds.contains(responsibleParty.IDN_CLIENT__c)){
                    responsiblePartiesToBeDeleted.add(responsibleParty);
                }  else{
                    existingIndivIPVMap.put(responsibleParty.IDN_CLIENT__c, responsibleParty);
                }      
            }
            if(!responsiblePartiesToBeDeleted.isEmpty()){
                
                GenericDMLHandler.deleteRecords(responsiblePartiesToBeDeleted,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
                
            }
            for(Id individualId:individualIds){
                if(!existingIndividualsAsResponsibleParties.contains(individualId)){
                    responsiblePartiesToBeInserted.add(new T_ADJMT_RESPBL_PARTY__c(IDN_ADJMT__c = adjustmentId,
                                                                                   IDN_CASE__c = adjustmentWithResponsibleParties.get(0).IDN_CASE__c,
                                                                                   IDN_CLIENT__c = individualId,
                                                                                   IPV_Info__c=indivIPVMap.get(individualId).IPV_Info__c,
                                                                                   Selected__c=indivIPVMap.get(individualId).Selected__c,
                                                                                   Responsible_Party_Name__c=indivIPVMap.get(individualId).Responsible_Party_Name__c
                                                                                  ));
                }else{
                    T_ADJMT_RESPBL_PARTY__c existingResp = existingIndivIPVMap.get(individualId);
                    existingResp.IPV_Info__c = indivIPVMap.get(individualId).IPV_Info__c;
                    responsiblePartiesToBeUpdated.add(existingResp);
                    
                }
            }
            if(!responsiblePartiesToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(responsiblePartiesToBeInserted,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
            }    
            if(!responsiblePartiesToBeUpdated.isEmpty()){
                GenericDMLHandler.updateRecords(responsiblePartiesToBeUpdated,new Map<String,Object>{'Method__c'=>'upsertResponsibleParties','Class__c'=>'AdjustmentFlowApxCtrl'});
            }        
            isSuccessful = true;
        }
        
        return new LightningServerResponse(isSuccessful,null,null);
    }
    
    @AuraEnabled
    public static LightningServerResponse getIndivInfoFromAuth(String authorizationId, Date adStartDate, Date adEndDate) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        List<T_AUTH__c> authorization = [SELECT Id, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, IDN_CASE__r.IDN_EXTNL__c,
                                         		IDN_CASE__c, DTE_END_EFFV_AUTH__c, DTE_BEGIN_EFFV_AUTH__c, IDN_CLIENT__r.DTE_DOB__c, 
                                         		Protective_Services_Indicator__c, IDN_PROVR__r.CDE_TYPE_PROVR__c
                                         FROM T_AUTH__c
                                         WHERE Id=:authorizationId];
        
        if(authorization.size()>0) {
            T_AUTH__c authRec = authorization[0];
            Boolean checkPmtByEnroll = true;
            List<T_SBSD_CASE__c> caseRec = [SELECT Id, Program_Type__c FROM T_SBSD_CASE__c WHERE Id =:authRec.IDN_CASE__c LIMIT 1];
            if(!caseRec.isEmpty()){
            String prgType = caseRec.get(0).Program_Type__c != null ? caseRec.get(0).Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(authRec.IDN_CASE__c);
            
            String EXEMPT = System.Label.Exempt_Provider_Type;
            if(EXEMPT.contains(authRec.IDN_PROVR__r.CDE_TYPE_PROVR__c) || (prgType == 'CW' && !authRec.Protective_Services_Indicator__c)){
                checkPmtByEnroll = false;
            }
            }
            String cdeProg, tanfReceiving;
            isSuccessful = true;
            objectData.put('authorization', authRec); 

            //CCCAP-13818
            List<batchsit_t_eligty_run__x> eligRunRecs = [SELECT Id,ExternalId, idn_run_eligty__c, dte_run_eligty__c FROM batchsit_t_eligty_run__x
                                                         WHERE idn_case__c = :authRec.IDN_CASE__r.IDN_EXTNL__c AND cde_eligty_cfmd__c = 'CFM' AND dte_run_eligty__c < :adEndDate
                                                         ORDER BY dte_run_eligty__c DESC LIMIT 500];
            Set<String> eligRunsInCareDateRange = new Set<String>();
            String activeEligRunExtId;
            for(batchsit_t_eligty_run__x eligRun : eligRunRecs){
                if(eligRun.dte_run_eligty__c >= adStartDate){
                    eligRunsInCareDateRange.add(String.valueOf(eligRun.idn_run_eligty__c));
                } else{
                    activeEligRunExtId = String.valueOf(eligRun.idn_run_eligty__c); //elig run active as of care start date
                    break;
                }
            }
            if(!String.isEmpty(activeEligRunExtId)){ 
                List<batchsit_t_fcompsn_eligty_detail__x> householdEligRecs = [SELECT idn_eligty_fcompsn__c,dte_begin_effv__c,dte_end_effv__c, 
                    idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c, idn_eligty_fcompsn__r.idn_run_eligty__c,  idn_eligty_fcompsn__r.cde_prog__c
                    FROM batchsit_t_fcompsn_eligty_detail__x WHERE idn_eligty_fcompsn__r.idn_run_eligty__c = :activeEligRunExtId AND cde_status_eligty_family__c!='INE' AND
                    dte_begin_effv__c <= :adStartDate AND (dte_end_effv__c >= :adStartDate OR dte_end_effv__c = null) 
                    ORDER BY dte_begin_effv__c DESC LIMIT 100];
                if(!householdEligRecs.isEmpty()){
                    for(batchsit_t_fcompsn_eligty_detail__x fcomp: householdEligRecs){
                        if(fcomp.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c != 'NCT' || fcomp.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c == null){
                            cdeProg = fcomp.idn_eligty_fcompsn__r.cde_prog__c; //program as of care start date
                            break;
                        }
                    }
                }
            }
            Boolean isProgramChangedInCareDateRange = false;
            if(!String.isEmpty(cdeProg) && !eligRunsInCareDateRange.isEmpty()){
                Set<String> programTypesInCareRange = new Set<String>();
                List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = [SELECT idn_eligty_fcompsn__c,dte_begin_effv__c,dte_end_effv__c, 
                    idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c, idn_eligty_fcompsn__r.idn_run_eligty__c,  idn_eligty_fcompsn__r.cde_prog__c
                    FROM batchsit_t_fcompsn_eligty_detail__x WHERE idn_eligty_fcompsn__r.idn_run_eligty__c in: eligRunsInCareDateRange AND cde_status_eligty_family__c!='INE'
                    AND ((dte_begin_effv__c < :adStartDate AND (dte_end_effv__c >= :adStartDate OR dte_end_effv__c = null)) 
                    OR (dte_begin_effv__c >= :adStartDate AND dte_begin_effv__c <= :adEndDate))
                    ORDER BY dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC LIMIT 1000];
                for(batchsit_t_fcompsn_eligty_detail__x eligtyDetail : caseEligibilityDetails){
                    if(eligtyDetail.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c != 'NCT' || eligtyDetail.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c == null){
                        programTypesInCareRange.add(eligtyDetail.idn_eligty_fcompsn__r.cde_prog__c); //programs in care date range
                    }
                }
                if(!programTypesInCareRange.isEmpty()){
                    for(String progType : programTypesInCareRange){
                        if(progType != cdeProg){ //program changed in care date range
                            isProgramChangedInCareDateRange = true;
                            break;
                        }
                    }                    
                }
            }
            
            List<T_CW_ADDNL_INFO__c> cwAddInfo = [SELECT Id, TANF_RCVNG__c 
                                                  FROM T_CW_ADDNL_INFO__c
                                                  WHERE IDN_CASE_CHATS__c = :authRec.IDN_CASE__c 
                                                  AND IDN_CLIENT__c = :authRec.IDN_CLIENT__c];
            if(cwAddInfo.size()>0) {
                tanfReceiving = cwAddInfo.get(0).TANF_RCVNG__c;
            }
            //if(String.isNotEmpty(tanfReceiving) &&  String.isNotEmpty(cdeProg)) {
            objectData.put('cdeProg', cdeProg); 
            objectData.put('isProgramChangedInCareDateRange', isProgramChangedInCareDateRange);  
            objectData.put('tanfReceiving', tanfReceiving);  
            objectData.put('fundingProg', getFundingProgram(tanfReceiving, cdeProg));  
            objectData.put('checkPmtByEnrollment', checkPmtByEnroll);
            //}
        }
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    public static List<T_SBSD_INDIV__c> getIndividualFromId(Id indivId) {
        return [SELECT NAM_FIRST__c, NAM_LAST__c
                FROM T_SBSD_INDIV__c
                WHERE Id=:indivId];
    }
    
    @AuraEnabled
    public static LightningServerResponse getRecordTypeId(String recordTypeName, String parentObjectName, String recordId, Double adjustmentAmount) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<RecordType> recType;
        if(!(String.isEmpty(recordTypeName)) && !(String.isEmpty(parentObjectName))) {
            recType = [Select Id from RecordType where Name =: recordTypeName and SobjectType =: parentObjectName];
            if(recType.size()>0) {
                objectData.put('recordtypeId',recType.get(0).Id);     
            }
        }
        // Start: Added below 'Outstanding Recovery Balance' calculation logic by Rishav for CCCAP-6051
        if(!String.isBlank(recordId)){
            Decimal outstandingRecoveryBalance = 0; // changed double to decimal for CCCAP-9338
            outstandingRecoveryBalance = adjustmentAmount - getAdjustmentPaidAmount(recordId);
            //added for CCCAP-9338
            if(outstandingRecoveryBalance>0){
                outstandingRecoveryBalance = outstandingRecoveryBalance.setScale(2);
            }
            objectData.put('outstandingRecoveryBalance', outstandingRecoveryBalance);
        }
        // End: CCCAP-6051
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    public static List<batchsit_t_sub_pmt_detail__x> querySubpaymentDetail(String subPaymentIdStr,T_ADJMT__c adjustmentInfo) {
        List<batchsit_t_sub_pmt_detail__x> listSubpaymentDetails;
        if(Test.isRunningTest()){
            listSubpaymentDetails=new List<batchsit_t_sub_pmt_detail__x>{new batchsit_t_sub_pmt_detail__x(idn_pmt_sub__c='1',ExternalId='1',dte_care__c=System.today().addDays(20))};
                }
        else{
            listSubpaymentDetails=[select id,ExternalId,cde_type_unit_care__c,cde_level_care__c,idn_pmt_sub__c,
                                   idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name, idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name,
                                   idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c, idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__c,
                                   idn_pmt_sub__r.idn_auth__r.NAM_LAST__c,idn_prog_fndg__c,idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c,
                                   cde_time_trdnl__c,amt_copay__c, cde_unit_care_actual__c,amt_act_paid__c,amt_reg_paid__c,amt_trans_paid__c,
                                   amt_total__c,amt_rate__c, cde_unit_care_exptd__c, ind_adjmt__c, dte_care__c, amt_slot_paid__c,
                                   idn_pmt_sub__r.idn_slot_contract__r.Name, ind_0_36_months_enroll_pmt__c
                                   from batchsit_t_sub_pmt_detail__x 
                                   where idn_pmt_sub__c =:subPaymentIdStr and dte_care__c <=: adjustmentInfo.DTE_END_ADJMT__c and dte_care__c >=: adjustmentInfo.DTE_START_ADJMT__c
                                  ];    
            
        }
        return listSubpaymentDetails;
    }
    public static Map<String, String> getFundingProgram( String tanfReceiving, String cdeProg) {
        String fundingProg='';
        String fundingProgVal='';
        Map<String, String> fundingProgram = new Map<String, String>();
        if(cdeProg== 'LI' ) {
            fundingProg='8';
            fundingProgVal='Low Income';
        }
        else if(cdeProg== 'TF' ) {
            fundingProg='5';
            fundingProgVal='TANF';
        }
        else if(cdeProg== 'FT' ) {
            fundingProg='6';
            fundingProgVal='Post-TANF';
        }
        else if(cdeProg== 'CW' ) {
            if(tanfReceiving=='Y') {
                fundingProg='3';
                fundingProgVal='Child Welfare Child Care - Non-TANF';
            } else {
                fundingProg='1';
                fundingProgVal='Child Welfare Child Care - TANF';
            }
        }
        fundingProgram.put('val',fundingProg);
        fundingProgram.put('label',fundingProgVal);
        return fundingProgram;
    }
    
    @AuraEnabled
    public static LightningServerResponse getPicklistOptions() {
        Map<String, Object> objectData = new map<String, Object>();
        List<PicklistOption> rateTypeOptions = new List<PicklistOption>();
        Map<String,String> rateTypeOptionsMap = new Map<String, String>();
        List<PicklistOption> careUnitTypeOptions = new List<PicklistOption>();
        Map<String,String> careUnitTypeOptionsMap = new Map<String, String>();
        List<PicklistOption> careLevelOptions = new List<PicklistOption>();
        Map<String, String> careLevelOptionsMap = new Map<String, String>();
        
        Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00751__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();        
        for(Schema.PicklistEntry f : ple1){
            rateTypeOptionsMap.put(f.getValue(), f.getLabel());
        }
        
        // Care Unit from FieldUtility Object
        Schema.DescribeFieldResult fieldResult2 = Field_Utility__c.R00715__c.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for(Schema.PicklistEntry f : ple2){
            careUnitTypeOptionsMap.put(f.getValue(), f.getLabel());
            careUnitTypeOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        } 
        
        // Care Level from Slot Contract Object
        Schema.DescribeFieldResult fieldResult3 = T_SLOT_CONTRACT__c.CDE_CARE_LEVEL__c.getDescribe();
        List<Schema.PicklistEntry> ple3 = fieldResult3.getPicklistValues();
        for(Schema.PicklistEntry f : ple3){
            careLevelOptionsMap.put(f.getValue(), f.getLabel());
            careLevelOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        }
        
        objectData.put('rateTypeOptionsMap', rateTypeOptionsMap);
        objectData.put('careUnitTypeOptions', careUnitTypeOptions);
        objectData.put('careUnitTypeOptionsMap', careUnitTypeOptionsMap);
        objectData.put('careLevelOptions', careLevelOptions);
        objectData.put('careLevelOptionsMap', careLevelOptionsMap);
        return new LightningServerResponse(true, null, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse doSearchSubPaymentDetails(Decimal subPaymentId, String selectedSubPayment,T_ADJMT__c adjustmentInfo) {
        Map<String, Object> objectData = new map<String, Object>();
        List<PicklistOption> rateTypeOptions = new List<PicklistOption>();
        Map<String,String> rateTypeOptionsMap = new Map<String, String>();
        List<PicklistOption> careUnitTypeOptions = new List<PicklistOption>();
        Map<String,String> careUnitTypeOptionsMap = new Map<String, String>();
        List<PicklistOption> careLevelOptions = new List<PicklistOption>();
        Map<String, String> careLevelOptionsMap = new Map<String, String>();
        
        String adjType = adjustmentInfo.CDE_TYPE_ADJMT__c;
        SubPaymentSearchApxCtrl.subpaymentWrapper selectedSubPymt = (SubPaymentSearchApxCtrl.subpaymentWrapper)JSON.deserialize(selectedSubPayment, SubPaymentSearchApxCtrl.subpaymentWrapper.class);
        String message = 'No Sub Payment Detail Record Found';
        String subPaymentIdStr = String.valueOf(subPaymentId);
        String[] selFiscalSchRateOptions;
        Map<String, List<batchsit_t_indiv_rat_fees__x> > currentUtilizationMap = new Map<String, List<batchsit_t_indiv_rat_fees__x>  >();
        Set<String> childIds = new Set<String>();
        // Rate type from FieldUtility Object
        Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00751__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();        
        for(Schema.PicklistEntry f : ple1){
            rateTypeOptionsMap.put(f.getValue(), f.getLabel());
        } 
        try{
            // Added cde_unit_care_actual__c in the query as part of bug fix 2933
            // Added all the sub payment information as part of bug fix 2929
            List<batchsit_t_sub_pmt_detail__x> subPaymentDetails = querySubpaymentDetail(subPaymentIdStr,adjustmentInfo);
            Date todayDay = System.today();
            
            List<String> subPmtDetailIdSet = new List<String>();
            for(batchsit_t_sub_pmt_detail__x subPmtDtl : subPaymentDetails){
                subPmtDetailIdSet.add(subPmtDtl.ExternalId);
            }
            
            Map<String, set<String>> existingAdjDetailMap = new Map<String, set<String>>();
			Map<String, T_ADJMT_DETAIL__c> existingAdjMap = new Map<String, T_ADJMT_DETAIL__c>();
			
            list<String> adjStatus = new List<String>{'2', '3', '4','5'};
            for(T_ADJMT_DETAIL__c adjd : [SELECT Id, CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c, toLabel(IDN_ADJMT__r.CDE_TYPE_ADJMT__c), IDN_DETAIL_PMT_SUB__c,
                                            NBR_HOURS_AUTH_ADJD__c, toLabel(CDE_TYPE_RATE_ADJD__c), NBR_HOURS_ATTND_ADJD__c, AMT_PAID_RATE_ADJD__c, AMT_DETAIL_ADJMT__c,
											Activity_Fee_Paid__c,Registration_Fee_Paid__c,Transportation_Fee_Paid__c,IND_OVERRIDE__c,
											toLabel(CDE_CARE_LEVEL_ADJD__c) ,toLabel(CDE_TYPE_UNIT_ADJD__c)
											FROM T_ADJMT_DETAIL__c WHERE IDN_DETAIL_PMT_SUB__c IN :subPmtDetailIdSet
                                             AND CDE_STATUS_DETAIL_ADJMT__c IN : adjStatus]){
                                                 if(!existingAdjDetailMap.containsKey(adjd.IDN_DETAIL_PMT_SUB__c)){							
                                                 	existingAdjDetailMap.put(adjd.IDN_DETAIL_PMT_SUB__c, new set<string>());
													existingAdjMap.put(adjd.IDN_DETAIL_PMT_SUB__c, adjd);
                                                 }
                                                 existingAdjDetailMap.get(adjd.IDN_DETAIL_PMT_SUB__c).add(adjd.IDN_ADJMT__r.CDE_TYPE_ADJMT__c);
            }
            
            // Added fiscal rate schedule start date, end date and county condition
            // as part of FM bug fixes 
            List<T_FISCAL_SCH__c> fiscalSchList = new List<T_FISCAL_SCH__c>();
            Map<String,List<PicklistOption>> rateTypeOptionsCareDateMap = new Map<String,List<PicklistOption>>();
            Date nullDate;
            Set<String> RateTypeSet = new Set<String>();
            String[] selFiscalSchRateOptionsCareDt;
            String filteredProviderId;
            String filteredCountyId;
            Boolean isProviderNull = String.isEmpty(selectedSubPymt.authProvSFID);
            String providerId = selectedSubPymt.paymentProviderSFID;
            if(Test.isRunningTest()){
                isProviderNull = true;
                List<T_CHATS_PROVR_STATUS__c> providerList = [SELECT Id FROM T_CHATS_PROVR_STATUS__c Limit 50000];
                filteredProviderId=providerList.get(0).Id;
                List<T_COUNTY__C> countyList=[SELECT id FROM T_COUNTY__C limit 1000];
                filteredCountyId=countyList.get(0).Id;
            }
            else{
                filteredProviderId=selectedSubPymt.paymentProviderSFID;
                if(filteredProviderId != null){
                    isProviderNull=true;
                }else{
                    isProviderNull=false;
                }
                filteredCountyId=selectedSubPymt.authCountySFID != null ? selectedSubPymt.authCountySFID : selectedSubPymt.slotCountySFID;
            }
            if(isProviderNull){
                fiscalSchList = [Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,
                                 IDN_AGRMT_FISCAL__r.ID_SERVICE__c,DTE_BEGIN_EFFV__c,
                                 CDE_RATE_TYPE__c from T_FISCAL_SCH__c 
                                 where IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:filteredProviderId 
                                 //BG CHATS-5357 and IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c ='OPN' 
                                 and IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: filteredCountyId];
                
                for(batchsit_t_sub_pmt_detail__x subPmtDtl : subPaymentDetails){
                    childIds.add(subPmtDtl.idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c);
                    for(T_FISCAL_SCH__c fiscalSch :fiscalSchList){
                        
                        if(((fiscalSch.DTE_BEGIN_EFFV__c <= subPmtDtl.dte_care__c) || (fiscalSch.DTE_BEGIN_EFFV__c == nullDate)) &&
                           ((fiscalSch.DTE_END_EFFV__c >= subPmtDtl.dte_care__c) || (fiscalSch.DTE_END_EFFV__c == nullDate))){
                               
                               if(rateTypeOptionsCareDateMap.containsKey(subPmtDtl.ExternalId)){
                                   List<PicklistOption> rateTypeOpt = rateTypeOptionsCareDateMap.get(subPmtDtl.ExternalId);
                                   if(fiscalSch.CDE_RATE_TYPE__c != null){
                                       selFiscalSchRateOptionsCareDt = fiscalSch.CDE_RATE_TYPE__c.split(';');
                                       for(String selFiscalSchRateOption :selFiscalSchRateOptionsCareDt){
                                           if(rateTypeOptionsMap.containsKey(selFiscalSchRateOption) && !RateTypeSet.contains(rateTypeOptionsMap.get(selFiscalSchRateOption))){
                                               rateTypeOpt.add(new PicklistOption(
                                                   rateTypeOptionsMap.get(selFiscalSchRateOption),
                                                   selFiscalSchRateOption
                                               ));  
                                           }
                                       }
                                   }
                                   rateTypeOptionsCareDateMap.put(subPmtDtl.ExternalId,rateTypeOpt);
                               }
                               else{
                                   
                                   List<PicklistOption> rateTypeOpt1 = new List<PicklistOption>();
                                   if(fiscalSch.CDE_RATE_TYPE__c != null){
                                       selFiscalSchRateOptionsCareDt = fiscalSch.CDE_RATE_TYPE__c.split(';');
                                       for(String selFiscalSchRateOption :selFiscalSchRateOptionsCareDt){
                                           if(rateTypeOptionsMap.containsKey(selFiscalSchRateOption)){
                                               RateTypeSet.add(rateTypeOptionsMap.get(selFiscalSchRateOption));
                                               rateTypeOpt1.add(new PicklistOption(
                                                   rateTypeOptionsMap.get(selFiscalSchRateOption),
                                                   selFiscalSchRateOption
                                               ));
                                           }
                                       }
                                   }
                                   rateTypeOptionsCareDateMap.put(subPmtDtl.ExternalId,rateTypeOpt1); 
                               }
                           }
                    }
                    if(existingAdjDetailMap.containsKey(subPmtDtl.ExternalId) && existingAdjDetailMap.get(subPmtDtl.ExternalId).contains(adjType)){
                        subPmtDtl.ind_adjmt__c = 'Y';
                    } else {
                        subPmtDtl.ind_adjmt__c = 'N';
                    }
                }
                if(Test.isRunningTest()){
                    List<T_CHATS_PROVR_STATUS__c> providerList = [SELECT Id FROM T_CHATS_PROVR_STATUS__c];
                    filteredProviderId=providerList.get(0).Id;
                    List<T_COUNTY__C> countyList=[SELECT id FROM T_COUNTY__C];
                    filteredCountyId=countyList.get(0).Id;
                }
                else{
                    filteredProviderId=selectedSubPymt.paymentProviderSFID;
                    filteredCountyId=selectedSubPymt.authCountySFID != null ? selectedSubPymt.authCountySFID : selectedSubPymt.slotCountySFID;
                }
                for(T_FISCAL_SCH__c fiscalSch : [Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,
                                                 IDN_AGRMT_FISCAL__r.ID_SERVICE__c,
                                                 CDE_RATE_TYPE__c from T_FISCAL_SCH__c 
                                                 where IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:filteredProviderId 
                                                 //BG CHATS-5357 and IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c ='OPN' 
                                                 and IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: filteredCountyId
                                                 and (DTE_BEGIN_EFFV__c <= :todayDay OR DTE_BEGIN_EFFV__c = null)
                                                 and (DTE_END_EFFV__c >=: todayDay OR DTE_END_EFFV__c = null)]){
                                                     
                                                     
                                                     if(fiscalSch.CDE_RATE_TYPE__c != null){
                                                         selFiscalSchRateOptions = fiscalSch.CDE_RATE_TYPE__c.split(';');
                                                         for(String selFiscalSchRateOption :selFiscalSchRateOptions){
                                                             rateTypeOptions.add(new PicklistOption(
                                                                 rateTypeOptionsMap.get(selFiscalSchRateOption),
                                                                 selFiscalSchRateOption
                                                             ));
                                                         }
                                                     }
                                                 }
                
            }
            
            // Care Unit from FieldUtility Object
            Schema.DescribeFieldResult fieldResult2 = Field_Utility__c.R00715__c.getDescribe();
            List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
            for(Schema.PicklistEntry f : ple2){
                careUnitTypeOptionsMap.put(f.getValue(), f.getLabel());
                careUnitTypeOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
            } 
            
            // Care Level from Slot Contract Object
            Schema.DescribeFieldResult fieldResult3 = T_SLOT_CONTRACT__c.CDE_CARE_LEVEL__c.getDescribe();
            List<Schema.PicklistEntry> ple3 = fieldResult3.getPicklistValues();
            for(Schema.PicklistEntry f : ple3){
                careLevelOptionsMap.put(f.getValue(), f.getLabel());
                careLevelOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
            }
            
            objectData.put('rateTypeOptionsMap', rateTypeOptionsMap);
            objectData.put('careUnitTypeOptions', careUnitTypeOptions);
            objectData.put('careUnitTypeOptionsMap', careUnitTypeOptionsMap);
            objectData.put('careLevelOptions', careLevelOptions);
            objectData.put('careLevelOptionsMap', careLevelOptionsMap);
            objectData.put('rateTypeOptionsCareDateMap', rateTypeOptionsCareDateMap);
            
            if(!rateTypeOptions.isEmpty()){
                objectData.put('rateTypeOptions', rateTypeOptions);
                message = null;
            }
            if(!subPaymentDetails.isEmpty()){
                if(!childIds.isEmpty()){
                    for(batchsit_t_indiv_rat_fees__x rateFee : [SELECT id,idn_indiv_rat_fee__c,idn_client__c,amt_act_paid__c,dte_care__c,createddate__c,dte_paid__c,amt_reg_paid__c,amt_reg_remaining__c,
                                                                amt_act_remaining__c,amt_trans_paid__c,amt_trans_remaining__c,idn_provr__c from batchsit_t_indiv_rat_fees__x where idn_client__c IN:childIds and dte_begin_effev__c <=:adjustmentInfo.DTE_START_ADJMT__c and dte_end_effev__c >=:adjustmentInfo.DTE_END_ADJMT__c  order by ExternalId DESC]){
                                                                    String dateStr = String.valueOf(rateFee.dte_care__c).split(' ')[0];
                                                                    String keyStr = rateFee.idn_client__c;// +'-'+ dateStr +'-'+ rateFee.idn_provr__c;
                                                                    if(!currentUtilizationMap.containsKey(keyStr)){
                                                                        currentUtilizationMap.put(keyStr,new List<batchsit_t_indiv_rat_fees__x>{rateFee});
                                                                    }
                                                                } 
                }
                if(!currentUtilizationMap.isEmpty()){
                    objectData.put('currentUtilizationMap', currentUtilizationMap);
                }
                objectData.put('subPaymentDetails', subPaymentDetails);
				objectData.put('existAdjWrap',existingAdjMap);
                message = null;
            }
            // Start: Added by Rishav for CCCAP-2873
            if(subPaymentDetails.Size() > 0){
                Date careStartDate = Date.valueOf(subPaymentDetails[0].dte_care__c);
                Date careEndDate = Date.valueOf(subPaymentDetails[subPaymentDetails.Size() - 1].dte_care__c);
                List<T_FISCAL_RAT_FEES__c> artFees = [SELECT Id, TXT_ACT_MONTH__c, TXT_REG_MONTH__c, TXT_TRANS_MONTH__c, IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c, IDN_FISCAL_SCH__r.DTE_END_EFFV__c FROM T_FISCAL_RAT_FEES__c
                                                      WHERE IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.ID_SERVICE__c =: filteredProviderId AND IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: filteredCountyId
                                                      AND (
                                                          ((IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c >=: careStartDate AND IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c <=: careEndDate) AND (IDN_FISCAL_SCH__r.DTE_END_EFFV__c <=: careEndDate OR IDN_FISCAL_SCH__r.DTE_END_EFFV__c =: nullDate))
                                                          OR 
                                                          (IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c <=: careStartDate AND ((IDN_FISCAL_SCH__r.DTE_END_EFFV__c <=: careEndDate AND IDN_FISCAL_SCH__r.DTE_END_EFFV__c >=: careStartDate) OR IDN_FISCAL_SCH__r.DTE_END_EFFV__c =: nullDate))
                                                          OR
                                                          ((IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c >=: careStartDate AND IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c <=: careEndDate) AND (IDN_FISCAL_SCH__r.DTE_END_EFFV__c >=: careEndDate OR IDN_FISCAL_SCH__r.DTE_END_EFFV__c =: nullDate))
                                                          OR
                                                          (IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c <=: careStartDate AND (IDN_FISCAL_SCH__r.DTE_END_EFFV__c >=: careEndDate OR IDN_FISCAL_SCH__r.DTE_END_EFFV__c =: nullDate))
                                                      )
                                                      LIMIT 1000];
                if(artFees.Size() > 0){
                    objectData.put('activeARTFeeRecords', artFees);
                }
            }
            // End: CCCAP-2873
        }catch(Exception ex){
            objectData.put('error',ex.getMessage());  
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AdjsutmentFlowApxCtrl','Method__c'=>'doSearchSubPaymentDetails'});             
        }
        return new LightningServerResponse(true, message, objectData);
    }
    
    @AuraEnabled 
    public static LightningServerResponse calculateAdjustDetail(string selectedSubPayment,T_ADJMT__c adjustment, List<batchsit_t_sub_pmt_detail__x> subPaymentDetails,List<T_ADJMT_DETAIL__c> adjustmentDetail, String adjustmentWrap){
        System.debug('calculateAdjustDetail-start::Limits.getHeapSize:'+Limits.getHeapSize());       
        List<T_ADJMT_DETAIL__c> adjustmentDetailUpdated = new List<T_ADJMT_DETAIL__c>();
        List<adjustmentWrapper> listToUpdated = new List<adjustmentWrapper>();
        Map<String, Object> objectData = new map<String, Object>();
        Map<String, List<batchsit_t_fiscal_rate__x>> fiscalRateMap = new map<String, List<batchsit_t_fiscal_rate__x>>();
        String message = '';
        batchsit_t_sub_pmt__x SubPayment;
       SubPaymentSearchApxCtrl.subpaymentWrapper selectedSubPymt;
        if(selectedSubPayment != null && String.isNotBlank(selectedSubPayment) && selectedSubPayment !='""'){
            system.debug('selectedSubPayment inside--'+selectedSubPayment);
                   selectedSubPymt = (SubPaymentSearchApxCtrl.subpaymentWrapper)JSON.deserialize(selectedSubPayment, SubPaymentSearchApxCtrl.subpaymentWrapper.class);
 
        }
	 // Added for bug fix 2933
        //Removed unused variable on 5/13/2018 BG         
        // Added for bug fix 2929
        if(selectedSubPymt == null){
            SubPayment = [SELECT amt_copay_pmt_sub__c,amt_rate_pmt_sub__c,amt_total_pmt_sub__c,
                          cde_status_pmt_sub__c,createdbyid__c,createddate__c,DisplayUrl,ExternalId,Id,
                          idn_auth__c,idn_period_serv__c,idn_pmt_sub__c,idn_pmt__c,
                          idn_pmt__r.IDN_PROVR__c, idn_pmt__r.CDE_COUNTY__c,idn_auth__r.CDE_COUNTY__c,
                          idn_slot_contract__r.CDE_COUNTY__c, idn_slot_contract__c
                          FROM batchsit_t_sub_pmt__x where ExternalId = :subPaymentDetails.get(0).idn_pmt_sub__c];
            
        }
        String filteredProviderId;
        String filteredCountyId;
        Boolean isOccupiedSlotPmt = false;
        // Vai - Design change - 3273 - added columns and removed criteria on the fiscal schedule dates
        try{
            if(Test.isRunningTest()){
                List<T_CHATS_PROVR_STATUS__c> providerList = [SELECT Id FROM T_CHATS_PROVR_STATUS__c limit 50000];
                filteredProviderId=providerList.get(0).Id;
                List<T_COUNTY__C> countyList=[SELECT id FROM T_COUNTY__C limit 50000];
                filteredCountyId=countyList.get(0).Id;
            }
            else{
                if(SubPayment!=null){
                    filteredProviderId = SubPayment?.idn_pmt__r?.IDN_PROVR__c;
                    filteredCountyId = SubPayment?.idn_auth__r?.CDE_COUNTY__c != null ? SubPayment?.idn_auth__r?.CDE_COUNTY__c : SubPayment?.idn_slot_contract__r?.CDE_COUNTY__c;
                    isOccupiedSlotPmt = SubPayment?.idn_slot_contract__c != null && SubPayment?.idn_auth__c != null;
                }else{
                    filteredProviderId = selectedSubPymt.paymentProviderSFID;
                    filteredCountyId = selectedSubPymt.authCountySFID != null ? selectedSubPymt.authCountySFID : selectedSubPymt.slotCountySFID;
                    isOccupiedSlotPmt = selectedSubPymt.slotSFID != null && selectedSubPymt.authSFID != null;
                }
            }
            
            List<String> fiscalSchIdList =  new List<String>();
            //added filteration based on Adjustment start/date with begin/end date of Rate schedules FOR CCCAP-12645
            for(T_FISCAL_SCH__c fisSch :[SELECT Id,DTE_BEGIN_EFFV__c,IDN_EXTNL__c,IDN_AGRMT_FISCAL__c,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__r.CDE_COUNTY__c,
                                         IDN_AGRMT_FISCAL__r.ID_SERVICE__c from T_FISCAL_SCH__c where IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:filteredProviderId and
                                         IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =:filteredCountyId 
                                         and ((DTE_BEGIN_EFFV__c<=: adjustment.DTE_START_ADJMT__c AND (DTE_END_EFFV__c >=: adjustment.DTE_START_ADJMT__c  OR DTE_END_EFFV__c = NULL))
                                              OR
                                              (DTE_BEGIN_EFFV__c<=: adjustment.DTE_END_ADJMT__c  AND (DTE_END_EFFV__c >=: adjustment.DTE_END_ADJMT__c OR DTE_END_EFFV__c = NULL))
                                              OR
                                              (DTE_BEGIN_EFFV__c>=: adjustment.DTE_START_ADJMT__c AND (DTE_END_EFFV__c<=: adjustment.DTE_END_ADJMT__c OR DTE_END_EFFV__c = NULL)))
                                        ]){
                                            if(fisSch.IDN_EXTNL__c != null){
                                                fiscalSchIdList.add(fisSch.IDN_EXTNL__c);
                                            }
                                        }
            System.debug('fiscalSchIdList:'+fiscalSchIdList);
            List<adjustmentWrapper> listToUpdate = (List<adjustmentWrapper>)System.JSON.deserialize(adjustmentWrap, List<adjustmentWrapper>.class);
            
            adjustmentWrap = null;		// CCCAP-2340: Free Memory
            filteredProviderId = null;	// CCCAP-2340: Free Memory
            filteredCountyId = null;	// CCCAP-2340: Free Memory
            selectedSubPayment = null;	// CCCAP-2340: Free Memory
            
            system.debug('listToUpdate---'+listToUpdate);
            
            List<FiscalRateWrapper> FiscalRateWrapperList = new List<FiscalRateWrapper>();
            System.debug('fiscalRatefetch-before::Limits.getHeapSize:'+Limits.getHeapSize());
            if(fiscalSchIdList.size()>0){
                FiscalRateWrapperList = HerokuService.fiscalRatefetch(fiscalSchIdList);
            }
            fiscalSchIdList = null; 	// CCCAP-2340: Free Memory
            System.debug('fiscalRatefetch-after::Limits.getHeapSize:'+Limits.getHeapSize());
            // New changes for fiscal rate external object
            Map<String, List<FiscalRateWrapper>> fiscalRateMapExternalFA = new map<String, List<FiscalRateWrapper>>(); 
            for(FiscalRateWrapper fisRt : FiscalRateWrapperList){
                system.debug(fisRt);
                String fiscalKey = fisRt.rateType;
                system.debug('fiscalKey---'+fiscalKey);
                if(fiscalRateMapExternalFA.containsKey(fiscalKey)){
                    List<FiscalRateWrapper> temp1 = fiscalRateMapExternalFA.get(fiscalKey);
                    temp1.add(fisRt);
                    fiscalRateMapExternalFA.put(fiscalKey, temp1);
                }else{
                    List<FiscalRateWrapper> temp2 = new List<FiscalRateWrapper>();
                    temp2.add(fisRt);
                    fiscalRateMapExternalFA.put(fiscalKey, temp2);
                }
            }
            FiscalRateWrapperList.clear();  // CCCAP-2340: Free Memory
            
            System.debug('FiscalRateWrapperList::Limits.getHeapSize:'+Limits.getHeapSize());
            
            // Care Level from Slot Contract Object
            Map<String, String> careLevelOptionsMap = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult3 = T_SLOT_CONTRACT__c.CDE_CARE_LEVEL__c.getDescribe();
            List<Schema.PicklistEntry> ple3 = fieldResult3.getPicklistValues();
            for(Schema.PicklistEntry f : ple3){
                careLevelOptionsMap.put(f.getLabel(), f.getValue());
            }
            
            for(adjustmentWrapper wrap: listToUpdate){
                adjustmentWrapper wraper = new adjustmentWrapper();
                batchsit_t_sub_pmt_detail__x subDlt = wrap.subPaymentDetails;
                T_ADJMT_DETAIL__c adj = wrap.ajustmentDetails;
                system.debug('adj----'+adj);
                system.debug('subDlt----'+subDlt);
                String adjKey = (String)adj.CDE_TYPE_RATE_ADJD__c;
                system.debug('adjKey---'+adjKey);
                String careUnit = '';
                system.debug('fiscal rate map' + fiscalRateMapExternalFA);
                if(fiscalRateMapExternalFA.containsKey(adjKey)){
                    Decimal careUnitKey = 0;
                    if(adj.NBR_HOURS_AUTH_ADJD__c == null){
                        adj.NBR_HOURS_AUTH_ADJD__c = 0;
                    }
                    if(adj.NBR_HOURS_ATTND_ADJD__c == null){
                        adj.NBR_HOURS_ATTND_ADJD__c = 0;
                    }
                    if(isOccupiedSlotPmt || subDlt.ind_0_36_months_enroll_pmt__c == 'Y'){
                        careUnitKey = adj.NBR_HOURS_AUTH_ADJD__c;
                    } else if(adj.NBR_HOURS_AUTH_ADJD__c != null && adj.NBR_HOURS_ATTND_ADJD__c != null){
                        //commented out the below line and added as per updated ui spec as part of bug fix - 2933
                        //careUnitKey=Math.min(adj.NBR_HOURS_AUTH_ADJD__c, adj.NBR_HOURS_ATTND_ADJD__c);
                        careUnitKey = Math.min(adj.NBR_HOURS_AUTH_ADJD__c, adj.NBR_HOURS_ATTND_ADJD__c);
                    }   
                    system.debug('careUnitKey---'+careUnitKey);
                    if(adj.CDE_TYPE_UNIT_ADJD__c != null && adj.CDE_TYPE_UNIT_ADJD__c != ''){
                        careUnit = adj.CDE_TYPE_UNIT_ADJD__c;
                    }
                    else if(careUnitKey == 0){
                        careUnit = '1'; //'NP';
                    }else if(careUnitKey>0 && careUnitKey<=5){
                        careUnit = '2' ;//'PT';
                    }
                    else if(careUnitKey>5 && careUnitKey<=12){
                        careUnit = '3' ;//'FT';
                    }
                    else if(careUnitKey>12 && careUnitKey<=17){
                        careUnit = '4' ;//'FTPT';
                    }
                    else if(careUnitKey>17){
                        careUnit ='5';// 'FTFT';
                    }
                    
                    String careLevel = subDlt.cde_level_care__c;
                    if(adj.CDE_CARE_LEVEL_ADJD__c != null && adj.CDE_CARE_LEVEL_ADJD__c != ''){
                        careLevel = adj.CDE_CARE_LEVEL_ADJD__c;
                    } else if(adjKey == '13' || adjKey == '19' || adjKey == '25'){
                        careLevel = '8';
                    }
                    String careLevelStr = careLevel;
                    if(careLevelOptionsMap.containsKey(careLevel))
                        careLevelStr = careLevelOptionsMap.get(careLevel);
                    
                    system.debug('careUnit---'+careUnit);
                    system.debug('careLevel---'+careLevel+' **** careLevelStr---'+careLevelStr);
                    if(careUnit == '1'){
                        adj.AMT_PAID_RATE_ADJD__c = 0; 
                    }else{
                        system.debug('careUnit else---'+careUnit);
                        for(FiscalRateWrapper f : fiscalRateMapExternalFA.get(adjKey)){
                            system.debug('f.careUnit---'+f.careUnit);
                            system.debug('f.ageGroup---'+f);
                            system.debug('f.dte_care__c---'+subDlt.dte_care__c);
                            // Care unit check + age group check + fiscal agreement and fiscal schedule date range check - design change bug 3273
                            if(f.careUnit == careUnit && (f.ageGroup == careLevel || f.ageGroup == careLevelStr)
                               && (subDlt.dte_care__c >= f.fiscalAgreeBeginDate) 
                               && (subDlt.dte_care__c <= f.fiscalAgreeEndDate || f.fiscalAgreeEndDate  == null)
                               && (subDlt.dte_care__c >= f.rateSchBeginDate) 
                               && (subDlt.dte_care__c <= f.rateSchEndDate || f.rateSchEndDate  == null)){
                                   system.debug('f.fiscalRateAmount---'+f.fiscalRateAmount);
                                   adj.AMT_PAID_RATE_ADJD__c =f.fiscalRateAmount; 
                               }
                        }
                    }
                }
                wraper.ajustmentDetails = adj;
                wraper.subPaymentDetails = subDlt;
                system.debug('insert--adj--'+adj);
                adjustmentDetailUpdated.add(adj);
                listToUpdated.add(wraper);
                system.debug('adjustmentDetailUpdated---'+adjustmentDetailUpdated.size());
                System.debug('adjustmentWrapper::Limits.getHeapSize:'+Limits.getHeapSize());
            }
            // end
           /* for(T_FISCAL_RATE__c fisRt : [Select id,AMT_FA__c,CDE_CARE_UNIT__c,CDE_RATE_TYPE__c,CDE_AGE_GROUP__c,
                                          IDN_FISCAL_SCH__c,IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.ID_SERVICE__c,
                                          IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.CDE_COUNTY__c, IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c,
                                          IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c, IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c,
                                          IDN_FISCAL_SCH__r.DTE_END_EFFV__c
                                          from T_FISCAL_RATE__c  
                                          where
                                          IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:filteredProviderId
                                          and IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: filteredCountyId
                                         ]){
                                             system.debug(fisRt);
                                             String fiscalKey = fisRt.CDE_RATE_TYPE__c;
                                             system.debug('fiscalKey---'+fiscalKey);
                                             if(fiscalRateMap.containsKey(fiscalKey)){
                                                 List<T_FISCAL_RATE__c> temp1 =fiscalRateMap.get(fiscalKey);
                                                 temp1.add(fisRt);
                                                 fiscalRateMap.put(fiscalKey, temp1);
                                             }else{
                                                 List<T_FISCAL_RATE__c> temp2 = new List<T_FISCAL_RATE__c>();
                                                 temp2.add(fisRt);
                                                 fiscalRateMap.put(fiscalKey, temp2);
                                             }
                                         }
            
            for(adjustmentWrapper wrap: listToUpdate){
                adjustmentWrapper wraper = new adjustmentWrapper();
                batchsit_t_sub_pmt_detail__x subDlt = wrap.subPaymentDetails;
                T_ADJMT_DETAIL__c adj = wrap.ajustmentDetails;
                system.debug('adj----'+adj);
                system.debug('subDlt----'+subDlt);
                String adjKey = (String)adj.CDE_TYPE_RATE_ADJD__c;
                system.debug('adjKey---'+adjKey);
                String careUnit='';
                system.debug('fiscal rate map' + fiscalRateMap);
                if(fiscalRateMap.containsKey(adjKey)){
                    Decimal careUnitKey =0;
                    if(adj.NBR_HOURS_AUTH_ADJD__c == null){
                        adj.NBR_HOURS_AUTH_ADJD__c  =0;
                    }
                    if(adj.NBR_HOURS_ATTND_ADJD__c == null){
                        adj.NBR_HOURS_ATTND_ADJD__c =0;
                    }
                    if(adj.NBR_HOURS_AUTH_ADJD__c != null && adj.NBR_HOURS_ATTND_ADJD__c !=null){
                        // commented out the below line and added as per updated ui spec as part of bug fix - 2933
                        //careUnitKey=Math.min(adj.NBR_HOURS_AUTH_ADJD__c, adj.NBR_HOURS_ATTND_ADJD__c);
                        careUnitKey=Math.min(adj.NBR_HOURS_AUTH_ADJD__c, adj.NBR_HOURS_ATTND_ADJD__c);
                    }   
                    system.debug('careUnitKey---'+careUnitKey);
                    if(careUnitKey ==0){
                        careUnit = '1'; //'NP';
                    }else if(careUnitKey>0 && careUnitKey<=5){
                        careUnit = '2' ;//'PT';
                    }
                    else if(careUnitKey>5 && careUnitKey<=12){
                        careUnit = '3' ;//'FT';
                    }
                    else if(careUnitKey>12 && careUnitKey<=17){
                        careUnit = '4' ;//'FTPT';
                    }
                    else if(careUnitKey>17){
                        careUnit ='5';// 'FTFT';
                    }
                    system.debug('careUnit---'+careUnit);
                    if(careUnit == '1'){
                        adj.AMT_PAID_RATE_ADJD__c =0; 
                    }else{
                        system.debug('careUnit else---'+careUnit);
                        for(T_FISCAL_RATE__c f : fiscalRateMap.get(adjKey)){
                            system.debug('f.CDE_CARE_UNIT__c---'+f.CDE_CARE_UNIT__c);
                            // Care unit check + age group check + fiscal agreement and fiscal schedule date range check - design change bug 3273
                            if(f.CDE_CARE_UNIT__c == careUnit && subDlt.cde_level_care__c == f.CDE_AGE_GROUP__c
                               && (subDlt.dte_care__c >= f.IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c) 
                               && (subDlt.dte_care__c <= f.IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c || f.IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c  == null)
                               && (subDlt.dte_care__c >= f.IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c) 
                               && (subDlt.dte_care__c <= f.IDN_FISCAL_SCH__r.DTE_END_EFFV__c || f.IDN_FISCAL_SCH__r.DTE_END_EFFV__c  == null)){
                                   adj.AMT_PAID_RATE_ADJD__c =f.AMT_FA__c; 
                               }
                        }
                    }
                }
                wraper.ajustmentDetails = adj;
                wraper.subPaymentDetails = subDlt;
                system.debug('insert--adj--'+adj);
                adjustmentDetailUpdated.add(adj);
                listToUpdated.add(wraper);
                system.debug('adjustmentDetailUpdated---'+adjustmentDetailUpdated.size());
            }*/
            // Start: Added by Rishav for CCCAP-6051
            if(!String.isBlank(adjustment.Id)){
                objectData.put('totalPaidAmount', getAdjustmentPaidAmount(adjustment.Id));
            }
            // End: CCCAP-6051
            if(adjustmentDetailUpdated.size()>0){
                objectData.put('adjustmentDetailUpdated', adjustmentDetailUpdated);
                objectData.put('listToUpdated', listToUpdated);
                message = null;
            }
        }
        catch(Exception ex){
            message = 'No Authorization Detail record created Detail Record Found';
            objectData.put('error',ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AdjsutmentFlowApxCtrl','Method__c'=>'calculateAdjustDetail'});             
        }
        System.debug('calculateAdjustDetail-end:Limits.getHeapSize:'+Limits.getHeapSize());
        return new LightningServerResponse(true, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse doSearchSubPayment(String paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST,
                                                            String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, 
                                                             String servicePeriodObjDTEENDEFFV, T_ADJMT__c adjustmentInfo, String selectedAuthId, 
                                                             String selectedCaseId, String selectedSlotCntId, Boolean slotCntcheckbox)  
    {
        string message;
        Map<String, object> objectData = new Map<String, object>();
        try {
            SubPaymentSearchApxCtrl.throwException = true;
            LightningServerResponse resp = SubPaymentSearchApxCtrl.doSearchSubPaymentForAdjustmentEntry(paymentObjId, subPaymentObjId, subPaymentObjNAMFIRST, 
                                                                                servicePeriodObjDTEBEGINEFFV, subPaymentObjNAMLAST, 
                                                                                servicePeriodObjDTEENDEFFV, adjustmentInfo,
                                                                                selectedAuthId, selectedCaseId, selectedSlotCntId, slotCntcheckbox);
            if(resp.objectData!=null && resp.objectData.get('SubpaymentSearchResults')!=null && ((List<SubPaymentSearchApxCtrl.subpaymentWrapper>)resp.objectData.get('SubpaymentSearchResults')).size()>0){
                return resp;
            }else{
                resp =  new LightningServerResponse(false,'No search results to display. Modify your search criteria and search again',objectData);
                resp.messageType = 'alert';
                return resp;
            }
        }catch(System.CalloutException e) {
            message = 'The search has timed out. Please add additional search criteria to further reduce the search results and try again.';
            objectData.put('error',e.getLineNumber()+e.getMessage());
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'AdjsutmentFlowApxCtrl','Method__c'=>'doSearchSubPayment'});   
            return new LightningServerResponse(false,message,objectData);
        } catch(Exception ex) {
            message = 'The search has timed out. Please add additional search criteria to further reduce the search results and try again.';
            objectData.put('error',ex.getLineNumber()+ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AdjsutmentFlowApxCtrl','Method__c'=>'doSearchSubPayment'});   
            return new LightningServerResponse(false,message,objectData);
        }
    }
    
    @AuraEnabLed
    public static LightningServerResponse searchRelatedAuthRecord(String nonSubPaymentObjNAMFIRST, String nonSubPaymentObjNAMLAST, T_ADJMT__c adjustmentInfo, String selectedCaseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        String message = ''; 
        Boolean doQueryAuth = false;
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        String query = 'SELECT Name, IDN_EXTNL__c, IDN_PROVR__c, IDN_PROVR__r.Name, NAM_FIRST__c, NAM_LAST__c, IDN_CASE__r.Name, IDN_CASE__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_PROVR__r.NAM_FACILITY__c FROM T_AUTH__c WHERE';
        String providerId = adjustmentInfo.IDN_PROVR__c;
        Date careStartDate = Date.valueOf(adjustmentInfo.DTE_START_ADJMT__c);
        Date careEndDate = Date.valueOf(adjustmentInfo.DTE_END_ADJMT__c);
        if(String.isNotEmpty(nonSubPaymentObjNAMFIRST)) {
            if(query.length()!=query.indexOf('WHERE')+5) {
                query += ' AND';
            }
            query = query + ' NAM_FIRST__c =\'' + String.escapeSingleQuotes(nonSubPaymentObjNAMFIRST) + '\'';
            doQueryAuth = true;
        }
        if(String.isNotEmpty(nonSubPaymentObjNAMLAST)) {
            if(query.length()!=query.indexOf('WHERE')+5) {
                query += ' AND';
            }
            query = query + ' NAM_LAST__c =\'' + String.escapeSingleQuotes(nonSubPaymentObjNAMLAST) + '\'';
            doQueryAuth = true;
        }
        if(String.isNotEmpty(selectedCaseId)) {
            if(query.length()!=query.indexOf('WHERE')+5) {
                query += ' AND';
            }
            query = query + ' IDN_CASE__c =\'' + String.escapeSingleQuotes(selectedCaseId) + '\'';
            doQueryAuth = true;
        }
        if(String.isNotEmpty(providerId)) {
            if(query.length()!=query.indexOf('WHERE')+5) {
                query += ' AND';
            }
            query = query + ' IDN_PROVR__c =\''+ String.escapeSingleQuotes(providerId) + '\'';
            query = query + ' AND CDE_COUNTY__c =\''+ String.escapeSingleQuotes(adjustmentInfo.CDE_COUNTY__c) + '\''; // Added by Rishav for CCCAP-6885
            doQueryAuth = true;
        }
        if(careStartDate!=null){
            if(query.length()!=query.indexOf('WHERE')+5) {
                query += ' AND';
            }
            query = query + ' DTE_END_EFFV_AUTH__c>='+String.valueOf(careStartDate) + ' AND DTE_BEGIN_EFFV_AUTH__c<='+String.valueOf(careEndDate);
            doQueryAuth = true;
        }
        if(doQueryAuth){
            authList = Database.query(query);
            objectData.put('authList',authList);
            isSuccessful = true;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
     }
    
    @AuraEnabled
    public static LightningServerResponse doVerifyAdjustmentNote(String adjId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        String message = ''; 
        List<T_ADJMT_CMT__c> lstAdjNote = [SELECT Id FROM T_ADJMT_CMT__c WHERE IDN_ADJMT__c =: String.escapeSingleQuotes(adjId)] ;
        if(lstAdjNote.size()>0){
            objectData.put('noteFound', true);
        }else{
            objectData.put('noteFound', false);
        }
        isSuccessful = true; 
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    // Added by Rishav for CCCAP-6051
    @AuraEnabled
    public static Double getAdjustmentPaidAmount(String adjustmentId) {
        Double totalPaidAmount = 0;
        if(!String.isBlank(adjustmentId)){
            for(T_ADJMT_PMT_DETAIL__c adjPmtDet: [SELECT Id, AMT_PMT_DETAIL_ADJMT__c, IDN_ADJMT__r.AMT_ADJMT__c FROM T_ADJMT_PMT_DETAIL__c WHERE IDN_ADJMT__c =: adjustmentId AND CDE_STATUS_DETAIL_PMT_ADJMT__c = '4']){
                if(adjPmtDet.AMT_PMT_DETAIL_ADJMT__c != null){
                    totalPaidAmount = totalPaidAmount + adjPmtDet.AMT_PMT_DETAIL_ADJMT__c;
                }
            }
        }
        return totalPaidAmount;
    }
}