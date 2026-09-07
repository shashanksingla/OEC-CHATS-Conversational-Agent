public class adjustmentWrapper{
    @AuraEnabled public batchsit_t_sub_pmt_detail__x subPaymentDetails{get;set;}
    @AuraEnabled public T_ADJMT_DETAIL__c ajustmentDetails{get;set;}
    @AuraEnabled public String childName{get;set;}
    
   public adjustmentWrapper( batchsit_t_sub_pmt_detail__x subPaymentDetails, T_ADJMT_DETAIL__c ajustmentDetails, String childName){
        this.subPaymentDetails = subPaymentDetails;
        this.ajustmentDetails = ajustmentDetails;
        this.childName = childName;
    }
    public adjustmentWrapper(){
    /** 
   	* Creates instance of {@adjustmentWrapper}. Used for calling the default constructor explicitly
   	*/ 
    }
}