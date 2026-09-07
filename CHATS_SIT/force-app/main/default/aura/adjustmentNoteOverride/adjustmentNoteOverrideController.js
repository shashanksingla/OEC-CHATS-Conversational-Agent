({
	doInit : function(component, event, helper) {
        var adjNoteRecord = component.get("v.adjNoteRec");
        if(component.get("v.sObjectName")=='T_ADJMT_CMT__c'){
            adjNoteRecord.Id = component.get("v.recordId");
        }else{
            adjNoteRecord.IDN_ADJMT__c = component.get("v.recordId");
        }
        component.set("v.adjNoteRec",adjNoteRecord);
	},
    doSetHelpText : function(component, event, helper){
        helper.doSetHelpText(component, event, helper);        
    },
    doFinish : function(component, event, helper){
        helper.doFinish(component, event, helper);        
    },
    doCancel : function(component, event, helper){
        helper.doCancel(component, event, helper);        
    }
})