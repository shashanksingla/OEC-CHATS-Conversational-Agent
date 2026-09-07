trigger CorrespondanceAndLangPrefTrigger on T_PROVR_PREF__c (before insert,before update ) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CorrespondanceAndLangPrefTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            CorrespondanceAndLangPrefService.updateCorrespondanceAndLangPrefForActiveStatus(Trigger.new);
        }
        
        if(Trigger.isUpdate){
            CorrespondanceAndLangPrefService.updateCorrespondanceAndLangPrefForActiveStatus(Trigger.new);
        }
    }
}