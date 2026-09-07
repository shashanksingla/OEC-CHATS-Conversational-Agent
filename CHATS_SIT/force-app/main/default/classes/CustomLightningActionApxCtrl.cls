public class CustomLightningActionApxCtrl {
    public static Boolean isSuccessful;
    public static String message;
    
    @auraEnabled
    public static LightningServerResponse newPaymentPlan(String recordId){
        return ProviderAPXServicesCtrl.newPaymentPlan(recordId);
    }
    
    
    @auraEnabled
    public static LightningServerResponse newFiscalAgreement(String recordId){
        return ProviderAPXServicesCtrl.newFiscalAgreement(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse finalizeFiscalAgreement(String recordId){
        return ProviderAPXServicesCtrl.finalizeFiscalAgreementUpdate(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse finalizeSlotContractAddendum(String recordId){
        return SlotContractAddendumServices.finalizeSlotContractAddendumUpdate(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse confirmPopupForProcessApplication(String recordId){
        return APXPeakApplicationToCaseController.checkCountyMatch(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse closeFiscalAgreement(String recordId){
        return ProviderAPXServicesCtrl.closeFiscalAgreementUpdate(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse deleteCaseParentFee(String recordId){
        return new LightningServerResponse(true, null, null);
    }
    
    @auraEnabled
    public static LightningServerResponse submitForApprovalCountyPlan(String recordId){
        return CountyPlanServices.submitForApproval(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse submitForApprovalCountyRatePlan(String recordId){
        return CountyRatePlanServices.submitForApproval(recordId);
    }
    @auraEnabled
    public static LightningServerResponse deleteRateSchedule(String recordId){
        return RateScheduleServices.deleteRateSchedule(recordId);
    }
    
    @AuraEnabled
    public static LightningServerResponse deleteAuthorization(String recordId){  
        return AuthorizationFlowApxCtrl.deleteAuthorizationRecord(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse deleteFA(String recordId){
        return FiscalAgreementServices.deleteFARecord(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse deleteSlotContractAddendum(String recordId){
        return SlotContractAddendumServices.deleteSlotContractAddendumRecord(recordId);
    }
    
    @auraEnabled
    public static LightningServerResponse markTaskAsCompleted(String recordId){
        return TaskServicesAPXCtrl.markTaskAsCompleted(recordId);
    }
    @AuraEnabled
    public static LightningServerResponse deleteAdjustment(String recordId){  
        return AdjustmentFlowApxCtrl.doDeleteAdjustRecords(recordId);
    }
    @AuraEnabled
    public static LightningServerResponse getAdjustmentPayments(String recordId){  
        return adjustmentCancellationApxCtrl.getAdjustmentPayments(recordId);
    }
    @AuraEnabled
    public static LightningServerResponse checkCountyPlanNewChanges(String recordId){  
        return CountyPlanServices.checkIfNewChanges(recordId,true);
    }
    @AuraEnabled
    public static LightningServerResponse checktoShowOldCompareforCP(String recordId){  
        return CountyPlanServices.checkIfNewChanges(recordId,false);
    }
    @AuraEnabled
    public static LightningServerResponse checkCountyRatePlanNewChanges(String recordId){  
        return CountyRatePlanServices.checkIfNewChanges(recordId,true);
    }
    @AuraEnabled
    public static LightningServerResponse checktoShowOldCompareforCRP(String recordId){  
        return CountyRatePlanServices.checkIfNewChanges(recordId,false);
    }
}