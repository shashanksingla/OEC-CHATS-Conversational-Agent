/**
 * Trigger: CaseReviewTrigger
 * Object: Case_Review__c
 * Handler: caseReviewApexController
 * Created: April 2026 as part of CCCAP-15192
 */
trigger CaseReviewTrigger on Case_Review__c (before delete) {
    if(TriggersOnOffServices.triggerStatus('CaseReviewTrigger')) {
        return; // Trigger is disabled via custom setting
    }
    
    if(Trigger.isBefore && Trigger.isDelete) {
        for(Case_Review__c record : Trigger.old) {
            String errorMessage = caseReviewApexController.validateCaseReviewDelete(record.Id);
            if(errorMessage != null) {
                record.addError(errorMessage);
            }
        }
    }
}