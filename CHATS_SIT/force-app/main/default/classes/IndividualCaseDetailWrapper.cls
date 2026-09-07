public class IndividualCaseDetailWrapper {
    @auraEnabled
    public Id caseRecId;
    @auraEnabled
    public String caseId;
    @auraEnabled
    public String caseStatus;
    @auraEnabled
    public String address;
    @auraEnabled
    public String countyName;
    
    public IndividualCaseDetailWrapper(ID caseRecId, String caseId, String caseStatus, String address, String countyName){
        this.caseRecId = caseRecId;
        this.caseId = caseId;
        this.caseStatus = caseStatus;
        this.address = address;
        this.countyName = countyName;
    }

}