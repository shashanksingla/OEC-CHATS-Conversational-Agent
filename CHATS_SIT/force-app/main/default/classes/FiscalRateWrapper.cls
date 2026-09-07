public class FiscalRateWrapper {
    @AuraEnabled public String rateSchedule{get;set;}
    @AuraEnabled public String idnFiscalSchedule{get;set;}
    @AuraEnabled public String lastModifiedByUserId{get;set;}
    @AuraEnabled public String createdByUserId{get;set;}
    @AuraEnabled public Integer idnFiscalRate{get;set;}
    @AuraEnabled public String rateType{get;set;}
    @AuraEnabled public String name{get;set;}
    @AuraEnabled public String careUnit{get;set;}
    @AuraEnabled public DateTime createdDate{get;set;}
    @AuraEnabled public DateTime lastModifiedDate{get;set;}
    @AuraEnabled public String ageGroup{get;set;}
    @AuraEnabled public Decimal countyCeilingAmount{get;set;}
    @AuraEnabled public Decimal fiscalRateAmount{get;set;}
    @AuraEnabled public Decimal providerRateAmount{get;set;}
    @AuraEnabled public Date fiscalAgreeBeginDate{get;set;}
    @AuraEnabled public Date fiscalAgreeEndDate{get;set;}
    @AuraEnabled public Date rateSchBeginDate{get;set;}
    @AuraEnabled public Date rateSchEndDate{get;set;}
    public FiscalRateWrapper(){
        
    }
    public FiscalRateWrapper(String rateSchedule,String idnFiscalSchedule,String lastModifiedByUserId,String createdByUserId,Integer idnFiscalRate,String rateType, String name, String careUnit,DateTime createdDate,
                             DateTime lastModifiedDate,String ageGroup ,Decimal countyCeilingAmount ,Decimal fiscalRateAmount,Decimal providerRateAmount,Date fiscalAgreeBeginDate,Date fiscalAgreeEndDate,
                             Date rateSchBeginDate,Date rateSchEndDate){
                                 this.rateSchedule = rateSchedule;
                                 this.idnFiscalSchedule = idnFiscalSchedule;
                                 this.lastModifiedByUserId = lastModifiedByUserId;
                                 this.createdByUserId = createdByUserId;
                                 this.idnFiscalRate = idnFiscalRate;
                                 this.rateType = rateType;
                                 this.name = name;
                                 this.careUnit = careUnit;
                                 this.createdDate = createdDate;
                                 this.lastModifiedDate = lastModifiedDate;
                                 this.ageGroup=ageGroup;
                                 this.countyCeilingAmount =countyCeilingAmount; 
                                 this.providerRateAmount =providerRateAmount;
                                 this.fiscalRateAmount=fiscalRateAmount;
                                 this.fiscalAgreeBeginDate =fiscalAgreeBeginDate;
                                 this.fiscalAgreeEndDate =fiscalAgreeEndDate;
                                 this.rateSchBeginDate =rateSchBeginDate;
                                 this.rateSchEndDate =rateSchEndDate;
                                 
                             }
    
}