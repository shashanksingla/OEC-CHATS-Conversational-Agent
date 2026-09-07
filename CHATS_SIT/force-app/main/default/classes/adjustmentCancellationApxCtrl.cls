//Created by Raina Yeole 10/19/2022
// Created for CCCAP-7013

public with sharing class adjustmentCancellationApxCtrl implements IRequest{
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
        if (methodName == 'getAdjustmentDetails') {
            response = getAdjustmentDetails(getMapValue('adjustmentId'));
        } else if (methodName == 'getAdjustmentPayments') {
            response = getAdjustmentPayments(getMapValue('adjustmentId'));
        }
        return response;
    }
    
    @AuraEnabled 
    public static LightningServerResponse getAdjustmentDetails(String adjustmentId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        List<User> user = [select Id,Profile.Name from User where id =: Userinfo.getUserId() limit 1];
        objectData.put('userProfile',user[0].Profile.Name);
        List<T_ADJMT_CANCEL__c> adjCanRecList = [Select Id, Name, IDN_ADJMT__c, DTE_DISC_CANCELLATION__c, CDE_STATUS__c,
                                                 CDE_RSN_CANCELLATION__c, RSN_CANCEL_BODY__c, RSN_CANCEL_SUBJECT__c 
                                                 from T_ADJMT_CANCEL__c where (IDN_ADJMT__c =: adjustmentId
                                                 and CDE_STATUS__c in ('1','2','5')) OR Id =:adjustmentId order by Createddate DESC Limit 1];
        
        if(!adjCanRecList.isEmpty() && adjCanRecList.size()>0){
            objectData.put('adjCanRecList',adjCanRecList[0]);
        }
        
        List<T_ADJMT_PMT_DETAIL__c> adjPaymentList = [Select Id from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId limit 1];
        
        if(!adjPaymentList.isEmpty() && adjPaymentList.size()>0){
            objectData.put('adjPaymentList',adjPaymentList[0]);
        }
        
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,'Done',objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getAdjustmentPayments(String adjustmentId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        List<T_ADJMT_PMT_DETAIL__c> adjPaymentList = [Select Id from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c =:adjustmentId limit 1];
        
        if(!adjPaymentList.isEmpty() && adjPaymentList.size()>0){
            isSuccessful= false;
            message='This Adjustment Recovery has payments and cannot be cancelled.';
            objectData.put('redirect',false);
        }else{
            isSuccessful= true;
            objectData.put('redirect',true);
        }
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    } 
}