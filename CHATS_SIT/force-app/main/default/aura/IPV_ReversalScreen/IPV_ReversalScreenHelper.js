({
    doInit : function(cmp, evt, hlp){
        var isReadOnly = cmp.get("v.isReadOnly");
        if(isReadOnly){
            cmp.find('forceRecordCmpRev').reloadRecord(true);
        }
    },
    checkCustomValidations : function(cmp){
        var isValid = this.verifyReversalDate(cmp); 
        return isValid;        
    },
    handleSaveRecord : function(cmp,helper) {
        var recordId = cmp.get("v.recordId");
        var ipvRec = cmp.get("v.ipvRec");
        ipvRec.Reversal_Created__c= true;
        cmp.set("v.ipvRec", ipvRec);
        cmp.set("v.showSpinner", true);
        cmp.find("forceRecordCmpRev").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "success","Success","Please review associated Adjustment Recovery records and take appropriate action");
                helper.redirectToRecord(recordId);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error","User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' +
                            JSON.stringify(saveResult.error));
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error",'Problem saving record, error: ' +JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error",'Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    verifyReversalDate: function(cmp){
        var isValid = true;
        if(!cmp.get("v.isReadOnly")){
            var ipvRec = cmp.get("v.ipvRec");
            if (ipvRec.Reversal_Date__c!=undefined && this.getDateInUTC(ipvRec.Reversal_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Reversal_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Reversal_Date__c").set("v.message",'');
                isValid = true;
            }            
        }
        return isValid;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    }
})