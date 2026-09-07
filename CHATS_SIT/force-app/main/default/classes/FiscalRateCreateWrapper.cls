public class FiscalRateCreateWrapper {
	public String cde_Age_Group{get;set;}
    public String cde_Care_Unit{get;set;}
    public String cde_Rate_Type{get;set;}
    public String idn_Fiscal_Sch{get;set;}
    public Decimal amt_Fa{get;set;}
    public Decimal amt_Provr{get;set;}
    public String lastmodifiedbyid{get;set;}
    public String createdbyid{get;set;}
    public DateTime lastmodifieddate{get;set;}
    public DateTime createddate{get;set;}
    
    
    public FiscalRateCreateWrapper(){
        
    }
    public FiscalRateCreateWrapper(String cde_Age_Group,String cde_Care_Unit,String cde_Rate_Type,String idn_Fiscal_Sch,Decimal amt_Fa ,Decimal amt_Provr){
                                 this.cde_Age_Group = cde_Age_Group;
                                 this.cde_Care_Unit = cde_Care_Unit;
                                 this.cde_Rate_Type = cde_Rate_Type;
                                 this.idn_Fiscal_Sch = idn_Fiscal_Sch;
                                 this.amt_Fa = amt_Fa;
                                 this.amt_Provr = amt_Provr;
                                 this.lastmodifieddate = System.now();
                                 this.lastmodifiedbyid = UserInfo.getUserId();
                                 this.createdbyid = UserInfo.getUserId();
        						 this.createddate= System.now();	
                             }
}