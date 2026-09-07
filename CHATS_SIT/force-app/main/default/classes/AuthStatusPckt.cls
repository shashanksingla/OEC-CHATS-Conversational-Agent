public class AuthStatusPckt {
    @auraEnabled
    public string authId;
    @auraEnabled
    public Date dteBeginEffv;
    @auraEnabled
    public String cdeReasonChangeAuth;
    @auraEnabled
    public String cdeStatusAuth;
    @auraEnabled
    public String idnAuthExtn;
    
    public AuthStatusPckt(string authId,Date dteBeginEffv,String cdeStatusAuth,String idnAuthExtn){
        this.authId=authId;
        this.idnAuthExtn = idnAuthExtn;
        this.dteBeginEffv = dteBeginEffv;
        this.cdeStatusAuth = cdeStatusAuth;
    }
}