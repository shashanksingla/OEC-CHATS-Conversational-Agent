trigger indivParentEduTempBrkTrigger on T_INDIV_EDUC_INFO__c (before insert,before update,after insert,after update,after delete) {
    If(Trigger.isAfter ){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseLastUpdatedServices.updateTeenEduInfoOnParentObject(Trigger.new);
        }
        
    }
    If(Trigger.isBefore ){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseLastUpdatedServices.updateTeenParentTmpBrkEndDate(Trigger.new,Trigger.oldMap);
        }
        
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            CaseLastUpdatedServices.updateTeenEduBrkAfterDlt(Trigger.old);
        }
            
    }
}