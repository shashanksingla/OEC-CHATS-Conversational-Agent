public class EligibilityHistoryWrapper {
    public String eligRunId{get;set;}
    public Decimal totalIncomeDeductions{get;set;}
    public Decimal annualExpenses{get;set;}
    public Decimal totalAnnualAdjustedIncome{get;set;}
    public Decimal totalOtherIncome{get;set;}
    
    
    public EligibilityHistoryWrapper(){
        
    }
    public EligibilityHistoryWrapper(String eligRunId,Decimal totalIncomeDeductions,Decimal annualExpenses,Decimal totalAnnualAdjustedIncome ,Decimal totalOtherIncome){
                                 this.eligRunId = eligRunId;
                                 this.totalIncomeDeductions = totalIncomeDeductions;
                                 this.annualExpenses = annualExpenses;
                                 this.totalAnnualAdjustedIncome = totalAnnualAdjustedIncome;
                                 this.totalOtherIncome = totalOtherIncome;
                             }
}