/*Parent Fee Flow*/
public class ParentFeeAllocationWrapper {
	@AuraEnabled public Boolean isEditable{get;set;}
	@AuraEnabled public String childName{get;set;}
	@AuraEnabled public String authExternalId{get;set;}
    @AuraEnabled public String authName{get;set;}
	@AuraEnabled public Date childDOB{get;set;}
	@AuraEnabled public String providerExternalId{get;set;}
	@AuraEnabled public String providerName{get;set;}
	@AuraEnabled public Date authBeginDate{get;set;}
    @AuraEnabled public Date authCopayEffecBeginDate{get;set;}
    @AuraEnabled public String authCopayExternalId{get;set;}
	@AuraEnabled public Date authEndDate{get;set;}
    @AuraEnabled public Integer allocatedAuthAmount{get;set;}
    @AuraEnabled public Decimal allocatedAuthAmountDecimal{get;set;}
    @AuraEnabled public Date authCopayEndDate{get;set;}
	@AuraEnabled public String authRecId{get;set;}
    @AuraEnabled public Integer authorizedDays{get;set;}
    @AuraEnabled public String childExternalId{get;set;}
    @AuraEnabled public String majorityCareUnit{get;set;}
    public ParentFeeAllocationWrapper(){
        
    }
    
    public ParentFeeAllocationWrapper(String childName,String authName,Date childDOB,String providerExternalId,String providerName,Date authBeginDate,Date authEndDate, Integer allocatedAuthAmount, String authExternalId,Date authCopayEffecBeginDate,String authCopayExternalId,Boolean isEditable , Date authCopayEndDate ,Integer authorizedDays,String childExternalId,String majorityCareUnit ){
        this.childName = childName;
        this.authExternalId = authExternalId;
        this.childDOB = childDOB;
        this.providerExternalId = providerExternalId;
        this.providerName = providerName;
        this.authBeginDate = authBeginDate;
        this.authEndDate = authEndDate;
        this.allocatedAuthAmount = allocatedAuthAmount;
        this.authName = authName;
        this.authCopayEffecBeginDate = authCopayEffecBeginDate;
        this.authCopayExternalId = authCopayExternalId;
        this.isEditable = isEditable;
        this.authCopayEndDate = authCopayEndDate;
        this.authorizedDays = authorizedDays;
        this.childExternalId = childExternalId;
        this.majorityCareUnit = majorityCareUnit;
    }
}