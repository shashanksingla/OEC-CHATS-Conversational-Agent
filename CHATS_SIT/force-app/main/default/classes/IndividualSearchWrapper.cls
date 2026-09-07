public class IndividualSearchWrapper{
    @auraEnabled   
    public T_SBSD_INDIV__c indivRec = new T_SBSD_INDIV__c();
    @auraEnabled
    public String caseId;
    @auraEnabled        
    public String state;
    @auraEnabled 
    public String city;
    @auraEnabled 
    public String county;
    @auraEnabled 
    public String zip;
    @auraEnabled 
    public String phone;
    @auraEnabled 
    public String searchType;
    @auraEnabled 
    public String emailId; // Added by Rishav for CCCAP-3239
    
    public IndividualSearchWrapper(T_SBSD_INDIV__c indivRec, String caseId, String state, String city, String county, String zip, String phone, String searchType, String emailId){
        this.indivRec = indivRec;
        this.caseId = caseId;
        this.state = state;
        this.city = city;
        this.county = county;
        this.zip = zip;
        this.phone = phone;
        this.searchType = searchType;
        this.emailId = emailId;
    }
}