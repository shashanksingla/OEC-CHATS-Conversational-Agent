({
    doInit : function(component, event, helper) {
        console.log('recordId'+component.get('v.recordId'));
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "T_ADJMT_CANCL_NOTES__c",
            "defaultFieldValues":{
                "IDN_ADJMT_CANCEL__c":component.get('v.recordId')                
            }
        });
        createRecordEvent.fire();
    }
})