public class ParentFeeAssessmentWrapper {
    @auraEnabled
    public String childName;
    @auraEnabled
    public String IDN_AUTH;
    @auraEnabled
    public Date AUTH_Effective_BGN_Date;
    @auraEnabled
    public String CDE_STATUS_AUTH;
    @auraEnabled
    public String IDN_PROVR;
    @auraEnabled
    public String ProviderName;
    @auraEnabled
    public String DTE_DOB;
    @auraEnabled
    public Integer AMT_COPAY_AUTH;
    @auraEnabled
    public String errMsg;
    @auraEnabled
    public String authCopayId;    
    @auraEnabled
    public String authName;
    
    public ParentFeeAssessmentWrapper() {
   /** 
   * Creates instance of {@ParentFeeAssessmentWrapper}. Used for calling the default constructor explicitly
   */ 
    }
    
    public ParentFeeAssessmentWrapper(String childName,String IDN_AUTH, Date AUTH_Effective_BGN_Date, String CDE_STATUS_AUTH, String IDN_PROVR, String ProviderName, String DTE_DOB, Integer AMT_COPAY_AUTH ){
        this.childName = childName;
        this.IDN_AUTH = IDN_AUTH;
        this.CDE_STATUS_AUTH = CDE_STATUS_AUTH;
        this.IDN_PROVR = IDN_PROVR;
        this.ProviderName = ProviderName;
        this.DTE_DOB = DTE_DOB;
        this.AMT_COPAY_AUTH = AMT_COPAY_AUTH;
        this.AUTH_Effective_BGN_Date = AUTH_Effective_BGN_Date;
        this.errMsg = '';
        this.authCopayId = '';
    }  

}