/******************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           13/12/2017
*  @description    Invoked by CustomLightningActionApxCtrl class
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 13-Dec-2017
*  * Author: Bharadwaj Gaddam
*  * Description: Initial version
******************************************************************/
public with sharing class ProviderAPXServicesCtrl {
    
    public static final String OPEN = 'OPN';
    public static final String FINALIZED = 'FIN';
    public static final String CLOSED = 'CLS';
    
    /*
        @description open/finalize fiscal agreement based on begin date.
        @author Bharadwaj Gaddam
        @date 13/12/2017
        @param fisacalAgrRecordId FA Record Id
        @return LightningServerResponse
		@story CHAT-931
    */
    public static LightningServerResponse newFiscalAgreement(String providerId){
        List<T_CHATS_PROVR_STATUS__c> providerRecords = [SELECT Id, CDE_TYPE_LICENSE__c, CDE_STATUS_PROVR__c, DTE_END_EFFV__c, CDE_COUNTY_OWNER__c FROM T_CHATS_PROVR_STATUS__c WHERE Id = :providerId AND (CDE_STATUS_PROVR__c = 'OPEN' OR CDE_STATUS_PROVR__c = 'Pending') WITH SECURITY_ENFORCED];
        List<T_CHATS_PROVR_STATUS__History> history = [SELECT oldvalue, newvalue FROM T_CHATS_PROVR_STATUS__History WHERE parentId=:providerId AND field = 'CDE_STATUS_PROVR__c' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
        Boolean canCreateNewAgreement = false;
        if(!providerRecords.isEmpty()){
            /*
            List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreements = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c = :providerId AND CDE_COUNTY__c=:providerRecords.get(0).CDE_COUNTY_OWNER__c AND CDE_TYPE_STATUS__c IN ('DFT','FIN')];    
            System.debug('fiscalAgreements:'+fiscalAgreements);
            if(fiscalAgreements.isEmpty()){
                canCreateNewAgreement = true;
            }
            */
            for(T_CHATS_PROVR_STATUS__c provider:providerRecords){
                if(provider.CDE_STATUS_PROVR__c == 'OPEN'){
                    canCreateNewAgreement = true;
                }
                if(provider.CDE_STATUS_PROVR__c == 'Pending' && history != null) {
                    if(history.size() > 0) {
                        if(provider.CDE_TYPE_LICENSE__c == 'Provisional' &&  history.get(0).OldValue == 'Open') {
                            canCreateNewAgreement = true;
                        } else if(provider.CDE_TYPE_LICENSE__c == 'Probationary' &&  history.get(0).OldValue == 'Open') {
                            canCreateNewAgreement = true;
                        }
                    }
                }
            }
        }
        if(canCreateNewAgreement){
            Map<String, Object> objectData = new Map<String, Object>();
            objectData.put('eventParams','{"entityApiName": "T_PROVR_FISCAL_AGREMENT__c","defaultFieldValues": {"ID_SERVICE__c" : "' + providerId + '"}}'); 
            objectData.put('redirect', true);
            return new LightningServerResponse(true, null, objectData);
        } else {
        	return new LightningServerResponse(false, Label.NEW_PROVR_FISCAL_AGREEMENT_ERROR, null);
        }
    }    
    
    public static LightningServerResponse newPaymentPlan(String providerId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessFull = false;
        String message = '';
        Boolean isCountyMatch = PaymentPlanServices.paymentPlanCountyCheck(providerId);
        isCountyMatch = true; // Skipping county validation by Rishav for CCCAP-5785
        if(!isCountyMatch) {
            isSuccessFull = false;
            message = System.Label.PaymentPlanCountyCheck;
            objectData.put('redirect', false);
        } else {
            isSuccessFull = true;
            message = 'Success';
            objectData.put('eventParams','{"entityApiName": "T_PMT_PLAN__c","defaultFieldValues": {"IDN_PROVR__c" : "' + providerId + '"}}');
            objectData.put('redirect', true);
        }
        return new LightningServerResponse(isSuccessFull, message, objectData);
    }
    
    public static LightningServerResponse finalizeFiscalAgreementUpdate(String fisacalAgrRecordId) {
        try {
            Date systDate = System.Today();
            Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
            Id finalizedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
            List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrRecList = [SELECT Id, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__r.DTE_FA_ReimEff__c, ID_SERVICE__r.CDE_TYPE_PROVR__c, CDE_COUNTY__c, CDE_COUNTY__r.Name, OwnerId FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =: fisacalAgrRecordId WITH SECURITY_ENFORCED LIMIT 1];
            List<T_PROVR_FISCAL_AGREMENT__c> existingfiscalAgrRecList = new List<T_PROVR_FISCAL_AGREMENT__c>();
            if(fiscalAgrRecList.size() > 0){
                LightningServerResponse accessResp = DynamicFormGenerationController.checkCountyWithOwnerCounty(fiscalAgrRecList[0]?.CDE_COUNTY__c, fiscalAgrRecList[0]?.OwnerId);
                if(accessResp.objectData.get('ownerCountyMatched') == true && accessResp.objectData.get('countyMatched') == true){
                    for(T_PROVR_FISCAL_AGREMENT__c fiscalAgrRec : fiscalAgrRecList){
                        if(!(fiscalAgrRec.DTE_RCV_AGRMT_FISCAL__c == null)){
                            if(fiscalAgrRec.DTE_BEGIN_AGRMT__c <= systDate
                            && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.CDE_TYPE_STATUS__c.isUpdateable()
                            && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.RecordTypeId.isUpdateable()){
                                fiscalAgrRec.CDE_TYPE_STATUS__c = OPEN;
                                fiscalAgrRec.RecordTypeId = openRecordTypeId;
                                // Added below 'if' by Rishav for CCCAP-4768 -- Commented for CCCAP-5987 -- Modified & Re-added for CCCAP-6032
                                if(fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c != null && fiscalAgrRec.ID_SERVICE__r.CDE_TYPE_PROVR__c == 'EFACH'
                                    && fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c > fiscalAgrRec.DTE_BEGIN_AGRMT__c
                                    && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.DTE_BEGIN_AGRMT__c.isUpdateable()){
                                        fiscalAgrRec.DTE_BEGIN_AGRMT__c = fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c;
                                    }
                            } else if(fiscalAgrRec.DTE_BEGIN_AGRMT__c > systDate
                                        && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.CDE_TYPE_STATUS__c.isUpdateable()
                                        && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.RecordTypeId.isUpdateable()){
                                            fiscalAgrRec.CDE_TYPE_STATUS__c = FINALIZED;
                                            fiscalAgrRec.RecordTypeId = finalizedRecordTypeId;
                                            // Added below 'if' by Rishav for CCCAP-4768 -- Commented for CCCAP-5987 -- Modified & Re-added for CCCAP-6032
                                            if(fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c != null && fiscalAgrRec.ID_SERVICE__r.CDE_TYPE_PROVR__c == 'EFACH'
                                                && fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c > fiscalAgrRec.DTE_BEGIN_AGRMT__c
                                                && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.DTE_BEGIN_AGRMT__c.isUpdateable()){
                                                    fiscalAgrRec.DTE_BEGIN_AGRMT__c = fiscalAgrRec.ID_SERVICE__r.DTE_FA_ReimEff__c;
                                                }
                                        }
                        } else {
                            return new LightningServerResponse(false, Label.FA_Date_Received_Required, null);
                            // fiscalAgrRec.DTE_RCV_AGRMT_FISCAL__c.addError(Label.FA_Date_Received_Required);
                        }
                    }
                    try {
                        update fiscalAgrRecList;
                    } catch(DMLException e) {
                        ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ProviderAPXServicesCtrl', 'Method__c'=>'finalizeFiscalAgreementUpdate'});
                        return new LightningServerResponse(false, e.getDmlMessage(0), null);  
                    }
                    return new LightningServerResponse(true, Label.Record_updated_successfully, null);
                } else{
                    String message = 'The fiscal agreement that you are trying to finalize is with '+fiscalAgrRecList[0]?.CDE_COUNTY__r.Name+'  county. This does not match your assigned county(ies).';
                    return new LightningServerResponse(false, message, null);
                }
            } else {
                return new LightningServerResponse(false, Label.Not_finalized, null);
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ProviderAPXServicesCtrl', 'Method__c'=>'finalizeFiscalAgreementUpdate'});
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
    
    /*
        @description close fiscal agreement
        @author Bharadwaj Gaddam
        @date 14/12/2017   
        @param fisacalAgrRecordId FA Record Id
        @return LightningServerResponse 
        @story CHAT-936
	*/
    public static LightningServerResponse closeFiscalAgreementUpdate(String fisacalAgrRecordId){
        try {
            Id closedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
            Set<Id> serviceIds = new Set<Id>();
            Set<Id> countyIds = new Set<Id>();
            List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrRecList = [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =: fisacalAgrRecordId AND ID_SERVICE__c != null AND CDE_COUNTY__c != null AND CDE_REASON_END_AGRMT__c != null WITH SECURITY_ENFORCED LIMIT 1];
            if(fiscalAgrRecList.size() > 0) {
                for(T_PROVR_FISCAL_AGREMENT__c FAEach : fiscalAgrRecList) {
                    serviceIds.add(FAEach.ID_SERVICE__c);
                    countyIds.add(FAEach.CDE_COUNTY__c);
                }
                List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrRecListExisting = [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id !=: fisacalAgrRecordId AND ID_SERVICE__c IN: serviceIds AND CDE_COUNTY__c IN: countyIds AND DTE_BEGIN_AGRMT__c > TODAY WITH SECURITY_ENFORCED LIMIT 1];
                if(fiscalAgrRecListExisting.isEmpty()) {
                    for(T_PROVR_FISCAL_AGREMENT__c fiscalAgmnt : fiscalAgrRecList) {
                        if(Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.CDE_TYPE_STATUS__c.isUpdateable()
                           && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.RecordTypeId.isUpdateable()
                           && Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.DTE_END_AGRMT__c.isUpdateable()){
                               fiscalAgmnt.CDE_TYPE_STATUS__c = CLOSED;
                               fiscalAgmnt.RecordTypeId = closedRecordTypeId;
                               fiscalAgmnt.DTE_END_AGRMT__c = system.today();
                           }
                    }
                    update fiscalAgrRecList;
                    return new LightningServerResponse(true, Label.Record_updated_successfully, null);
                } else {
                    return new LightningServerResponse(false, Label.FA_is_not_Closed, null);
                }
            } else {
                return new LightningServerResponse(false, Label.FA_cannot_be_closed_without_reason, null);
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ProviderAPXServicesCtrl','Method__c'=>'CloseFiscalAgreementUpdate'});
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
}