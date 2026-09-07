public class ClaimResultWrapper {
    @auraEnabled
    public String queuecounty;
    @auraEnabled
    public String recordId;
    @auraEnabled        
    public String queueId;
    @auraEnabled 
    public String queuestatus;
    @auraEnabled 
    public String queueProviderId;
    @auraEnabled 
    public String queueProviderName;
    @auraEnabled 
    public String queueProviderSfId;
    @auraEnabled 
    public String queueCareMonth;
    @auraEnabled 
    public decimal queueCareYear;
    @auraEnabled 
    public DateTime queueSubmittedDate;
    @auraEnabled 
    public Date queueStatusUpdatedDate;
    @auraEnabled 
    public Decimal queueClaimAmount;
    
    public ClaimResultWrapper(){
    }
}