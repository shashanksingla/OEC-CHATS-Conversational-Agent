/*************************************************************
Class Name	    - TaxInterceptSearchWrapper
Test Class	    - TaxInterceptApexController_Test
Description     - Wrapper to send search parameters from Aura to Apex
Author          - Rishav Maji
Requiremnt		- Project 282 : CCCAP-4372
**************************************************************/
public class TaxInterceptSearchWrapper {
    
    @AuraEnabled
    public Tax_Intercept__c taxRecord = new Tax_Intercept__c();
    @AuraEnabled
    public List<String> selectedCounty;
    @AuraEnabled
    public List<String> recoveryReason;
    
    public TaxInterceptSearchWrapper (Tax_Intercept__c taxRecord, List<String> selectedCounty, List<String> recoveryReason){
        this.taxRecord = taxRecord;
        this.selectedCounty = selectedCounty;
        this.recoveryReason = recoveryReason;
    }
}