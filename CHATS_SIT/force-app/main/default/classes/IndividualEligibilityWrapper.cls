public class IndividualEligibilityWrapper {
    @AuraEnabled public String firstName{get;set;}
    @AuraEnabled public String lastName{get;set;}
    @AuraEnabled public String stateId{get;set;}
    @AuraEnabled public String overrideReason{get;set;}
    @AuraEnabled public String overrideComments{get;set;}
    @AuraEnabled public String indivId{get;set;}
    @AuraEnabled public String idnIndivFcompsn{get;set;}
    @AuraEnabled public String idnEligtyFcompsn{get;set;}
    @AuraEnabled public String status{get;set;}
    @AuraEnabled public Boolean isParentCaretaker{get;set;}
    @AuraEnabled public Date householdEligibilityBeginDate{get;set;}
    @AuraEnabled public Date individualEnteredHouseholdDate{get;set;}
    
    @AuraEnabled public Date lastIndivEligDetailEndDate{get;set;}
    @AuraEnabled public batchsit_t_indiv_eligty_detail__x indivEligDetail{get;set;}
    @AuraEnabled public batchsit_t_indiv_eligty_detail__x lastIndivEligDetail{get;set;}
    @AuraEnabled public batchsit_t_indiv_eligty_detail__x secondLastIndivEligDetail{get;set;}
    @AuraEnabled public batchsit_t_fcompsn_indiv_eligty__x indivElig{get;set;}
    @AuraEnabled public batchsit_t_fcompsn_indiv_eligty__x lastIndivElig{get;set;}
    @AuraEnabled public batchsit_t_fcompsn_indiv_eligty__x secondLastIndivElig{get;set;}
    @AuraEnabled public List<batchsit_t_indiv_eligty_failr__x> indivEligFailrs{get;set;}
    public IndividualEligibilityWrapper(){
        isParentCaretaker = false;
        status = '';
        firstName='';
        lastName='';
        indivElig = new batchsit_t_fcompsn_indiv_eligty__x();
        indivEligDetail = new batchsit_t_indiv_eligty_detail__x();
        indivEligFailrs = new List<batchsit_t_indiv_eligty_failr__x>();
    }
}