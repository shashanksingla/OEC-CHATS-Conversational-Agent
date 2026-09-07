trigger parentTrainingBrkTrigger on T_INDIV_TRAIN_INFO__c (before insert,before update,after insert,after update,after delete) {
If(Trigger.isAfter ){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseLastUpdatedServices.updateParentTrainignBreak(Trigger.new);
        }
        
    }
    If(Trigger.isBefore ){
        if(Trigger.isInsert || Trigger.isUpdate ){
            CaseLastUpdatedServices.updateParentTrainingTmpBrkEndDate(Trigger.new,Trigger.oldMap);
        }
        
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            CaseLastUpdatedServices.updateParentTrainingTmpBrkAfterDlt(Trigger.old);
        }
            
    }
}