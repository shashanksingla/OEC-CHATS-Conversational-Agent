public with sharing class CBMSInboxWrapper {
    @auraEnabled
    public String county;
    @auraEnabled        
    public String status;
    @auraEnabled 
    public String ssn;
    @auraEnabled 
    public String trackingNumber;
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
    public String referralType;
     @auraEnabled        
    public String referralReason;
    
    
    public CBMSInboxWrapper(String county, String status, String referralReason, String referralType,String firstName,String lastName,Date fromDate, Date toDate){
        this.county = county;
        this.status = status;
        //this.ssn = ssn;
        this.referralReason = referralReason;
        this.referralType = referralType;
        this.firstName = firstName;
        this.lastName = lastName;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
}