/**********************************************************************************
Class Name      - AdjustmentPaymentServices
Author          - Sahil Garg
Description     - Controller class for Individual Employeement Summary Component
Date            - May 6, 2020 
Branch          - CHATS_1_23_0

Modification Log:
Rishav : CCCAP-7647 - Updated test coverage to 96% (IndividualEmploymentTest)
**********************************************************************************/
public with sharing class IndividualEmployment {
    
    @AuraEnabled
    public static LightningServerResponse getEmploymentDetails(String recordId){
        Set<Id> indivIds = new Set<Id>();
        List<IndivEmploymeentWrapper> data = new List<IndivEmploymeentWrapper>();
        List<T_SBSD_CASE_INDIV__C> caseIndivs = [SELECT IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__C 
                                                 WHERE IDN_CASE__c = :recordId AND (DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null) WITH SECURITY_ENFORCED];
        if(!caseIndivs.isEmpty()){
            for(T_SBSD_CASE_INDIV__C indiv : caseIndivs){
                indivIds.add(indiv.IDN_CLIENT__c);
            }
        }
        List<T_SBSD_INDIV_EMPLMT__c> employmentDetails = [SELECT Id, Name, ADR_CITY__c, ADR_LINE_1__c, ADR_LINE_2__c, ADR_STATE__c, ADR_ZIP_EXTN__c, ADR_ZIP_MAIN__c,
                                                          DTE_BEGIN_EFFV__c, IDN_CLIENT__c,IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, IDN_CLIENT__r.NAME,
                                                          Total_Yearly_Expense__c, Record_Type_Name__c, NAM_BUSNS__c, NBR_PHONE__c, NBR_PHONE_EXTN__c, DTE_END_EFFV__c,
                                                          (SELECT Id, Calculated_Annual_Estimated_Income__c, Gross_Monthly_Income__c, CDE_STATUS__c FROM T_SBSD_INDIV_EMPLMT1__r)
                                                          FROM T_SBSD_INDIV_EMPLMT__c                                                        
                                                          WHERE (DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null) AND IDN_CLIENT__c in :indivIds AND IDN_CASE__c = :recordId WITH SECURITY_ENFORCED
                                                          ORDER BY IDN_CLIENT__r.NAM_FIRST__c, DTE_BEGIN_EFFV__c  DESC];
        
        if(!employmentDetails.isEmpty()){
            for(T_SBSD_INDIV_EMPLMT__c obj : employmentDetails){
                IndivEmploymeentWrapper wrapperObj = new IndivEmploymeentWrapper();
                wrapperObj.indivName = obj.IDN_CLIENT__r.NAM_FIRST__c;
                if(null != obj.IDN_CLIENT__r.NAM_LAST__c){
                    wrapperObj.indivName += ' ' + obj.IDN_CLIENT__r.NAM_LAST__c;
                }
                wrapperObj.clientId = obj.IDN_CLIENT__r.NAME;     
                wrapperObj.effectiveBeginDate = String.valueOf(obj.DTE_BEGIN_EFFV__c);     
                wrapperObj.recordTypeName = obj.Record_Type_Name__c;     
                wrapperObj.employer = obj.NAM_BUSNS__c ;  
                wrapperObj.address = '';
                if(null != obj.ADR_LINE_1__c && '' != obj.ADR_LINE_1__c && !String.isEmpty(obj.ADR_LINE_1__c)){
                    wrapperObj.address = obj.ADR_LINE_1__c + ',';
                }
                if(null != obj.ADR_LINE_2__c && !String.isEmpty(obj.ADR_LINE_2__c)){
                    wrapperObj.address += obj.ADR_LINE_2__c + ',';
                }
                if(null != obj.ADR_CITY__c){
                    wrapperObj.address += obj.ADR_CITY__c;
                }
                if(null != obj.ADR_STATE__c){
                    wrapperObj.address += ',' + obj.ADR_STATE__c;
                }
                if(null != obj.ADR_ZIP_MAIN__c && !String.isEmpty(obj.ADR_ZIP_MAIN__c)){
                    wrapperObj.address += ',' + obj.ADR_ZIP_MAIN__c;
                }
                if(null != obj.ADR_ZIP_EXTN__c && !String.isEmpty(obj.ADR_ZIP_EXTN__c)){
                    if(null != obj.ADR_ZIP_MAIN__c && !String.isEmpty(obj.ADR_ZIP_MAIN__c))
                        wrapperObj.address += '-' + obj.ADR_ZIP_EXTN__c;
                    else
                        wrapperObj.address += ',' + obj.ADR_ZIP_EXTN__c;
                }
                wrapperObj.employerPhone = obj.NBR_PHONE__c;
                if(obj.T_SBSD_INDIV_EMPLMT1__r != null){
                    Decimal estimatedIncomeTotal = 0;
                    Decimal grossMonthlyIncomeTotal = 0;
                    for(T_EMPLMT_INCOME__c income : obj.T_SBSD_INDIV_EMPLMT1__r){
                        if(income.CDE_STATUS__c == 'ACT'){
                            estimatedIncomeTotal = estimatedIncomeTotal + income.Calculated_Annual_Estimated_Income__c;
                            grossMonthlyIncomeTotal = grossMonthlyIncomeTotal + income.Gross_Monthly_Income__c;
                        }
                    }
                    if(estimatedIncomeTotal > 0) {
                        wrapperObj.estimatedIncome = String.valueOf((estimatedIncomeTotal/12).setScale(2, System.RoundingMode.HALF_UP));
                    } else {
                        wrapperObj.estimatedIncome = String.valueOf(estimatedIncomeTotal);
                    }
                    wrapperObj.grossMonthlyIncome = String.valueOf(grossMonthlyIncomeTotal);
                }
                wrapperObj.employmentExpense = String.valueOf(obj.Total_Yearly_Expense__c);
                wrapperObj.eploymentId = obj.Name;     
                wrapperObj.indivSfid = obj.IDN_CLIENT__c;    
                wrapperObj.employmentSfid = obj.Id;
                data.add(wrapperObj);
            }
        }
        Boolean isSuccessful = true;
        String message = '';
        Map<String, Object> objectData = new Map<String, Object>();
        objectData.put('isSuccessful', isSuccessful);
        objectData.put('data', data);
        return new LightningServerResponse(true, 'Success', objectData);        
    }
}