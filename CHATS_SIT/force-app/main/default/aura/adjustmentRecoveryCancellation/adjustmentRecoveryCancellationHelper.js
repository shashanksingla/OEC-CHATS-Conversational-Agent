({
    validateForm : function(component,event,helper,cancelRecord) {
        component.set('v.isLoading',true);
        if(!cancelRecord.CDE_RSN_CANCELLATION__c || !cancelRecord.DTE_DISC_CANCELLATION__c || !cancelRecord.RSN_CANCEL_SUBJECT__c  || !cancelRecord.RSN_CANCEL_BODY__c ){
            var recordError2 =[];
            recordError2.push('There are errors on this page.  Please correct them to proceed.');
            component.set("v.messageType",'error');
            component.get("v.action","");
            component.set("v.recordError",recordError2);
            component.set('v.isLoading',false);
        }else{
            component.set("v.messageType",null);
            component.set("v.recordError",[]);
            if(component.get("v.action")!='save' && !component.get("v.warningAccepted") && cancelRecord.Id &&
               (cancelRecord.CDE_STATUS__c == '2' || cancelRecord.CDE_STATUS__c == '6')){
                event.preventDefault();
                component.set('v.showConfirmDialog',true);
                component.set('v.isLoading',false);
            }else{
                component.find("cancellationForm").submit(cancelRecord);
                event.preventDefault();
                component.get("v.action","");
            }
        }
    },
    checkforWarning:function(component,event,helper){
        if(component.get('v.sObjectName') == 'T_ADJMT_CANCEL__c' && 
           (component.get("v.adjRecord").CDE_STATUS__c=='3'|| component.get("v.adjRecord").CDE_STATUS__c=='4' || component.get("v.adjRecord").CDE_STATUS__c=='5')
           && component.get('v.isAdmin')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "warning!",
                "message": component.get('v.reminderMsg'),
                "type":"warning"
            });
            toastEvent.fire();
        }
    }
})