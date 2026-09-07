public class PeakInboxWrapper {
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
    
    public PeakInboxWrapper(String county, String status, String ssn, String trackingNumber, String searchType,String firstName,String lastName,Date fromDate, Date toDate){
        this.county = county;
        this.status = status;
        this.ssn = ssn;
        this.trackingNumber = trackingNumber;
        this.searchType = searchType;
        this.firstName = firstName;
        this.lastName = lastName;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
}