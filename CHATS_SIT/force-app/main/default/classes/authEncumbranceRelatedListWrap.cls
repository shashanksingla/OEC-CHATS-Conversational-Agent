public class authEncumbranceRelatedListWrap {
    
    @AuraEnabled
    public String ExternalId{get;set;}
    @AuraEnabled
    public String encumbId{get;set;}
    @AuraEnabled
    public String status{get;set;}
    @AuraEnabled
    public String rateType{get;set;}
    @AuraEnabled
    public Date dateOfCare{get;set;}
    @AuraEnabled
    public  Decimal actualAttendedHours{get;set;}
    @AuraEnabled
    public  Boolean attendedFlag{get;set;}
    @AuraEnabled
    public  Boolean ind0to36months{get;set;} 
    @AuraEnabled
    public  Decimal authorizedHours{get;set;}
    
    public authEncumbranceRelatedListWrap(){
        
    }
    public authEncumbranceRelatedListWrap(String ExternalId,String encumbId,String status,String rateType ,Date dateOfCare, Decimal actualAttendedHours, Boolean attendedFlag,Decimal authorizedHours){
        this.ExternalId = ExternalId;
        this.encumbId = encumbId;
        this.status = status;
        this.rateType = rateType;
        this.dateOfCare = dateOfCare;
        this.actualAttendedHours = actualAttendedHours;
        this.attendedFlag = attendedFlag;
        this.authorizedHours =authorizedHours;
    }
}