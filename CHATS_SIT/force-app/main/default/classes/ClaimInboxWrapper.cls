public class ClaimInboxWrapper {
    @auraEnabled
    public String county;
    @auraEnabled        
    public String status;
    @auraEnabled 
    public String careYear{get;set;}
    @auraEnabled 
    public String careMonth{get;set;}
    @auraEnabled 
    public String searchType;
    @auraEnabled 
    public String firstName;
    @auraEnabled 
    public String lastName;
    @auraEnabled 
    public Date fromDate;
    @auraEnabled 
    public Date toDate;
    @auraEnabled 
    public Date receivedDate;
    @auraEnabled 
    public String providerId;
    @auraEnabled 
    public String providerName;
    
    public ClaimInboxWrapper(String county,String firstName,String lastName){
        this.county = county;
        this.firstName = firstName;
        this.lastName = lastName;
    }
    public ClaimInboxWrapper(String county, String status, String careYear, String careMonth, String searchType,String firstName,String lastName,Date fromDate, Date toDate){
        this.county = county;
        this.status = status;
        this.careMonth = careMonth;
        this.careYear = careYear;
        this.searchType = searchType;
        this.firstName = firstName;
        this.lastName = lastName;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
}