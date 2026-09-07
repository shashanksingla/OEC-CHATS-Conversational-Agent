({
	fetchUserId : function(component, event, helper) {
        var action = component.get('c.fetchLoggedInProfileId');
        action.setParams({
            'caseCommentId' : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res= response.getReturnValue();
                component.set('v.loggedUserProfleName',res.objectData.profileName);
                var caseCmtRec =res.objectData.caseCommentRec
                component.set('v.recordOwnerId',caseCmtRec.createdbyid__c);
                component.set("v.caseRecordId",res.objectData.caseRecordId);
                component.set("v.caseName",res.objectData.caseName);
                helper.validateCommentOwner(component, event, helper);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                    }
                } else {
                }
            }
        });
        $A.enqueueAction(action);
	},
	getDateInUTC: function(date) {  
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    },
    validateCommentOwner : function(component, event, helper) {
        var recordOwner = component.get("v.recordOwnerId");
        var loggedInUserId= component.get("v.loggedInUserId");
        var loggedUserProfleName = component.get("v.loggedUserProfleName");
        if( !$A.util.isEmpty(component.get("v.recordOwnerId")) && component.get("v.recordOwnerId") != loggedInUserId && loggedUserProfleName=='Read Only User' ){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error Message',
                message:"Looks like there\'s a problem.\n  Oops...you don\'t have the necessary privileges to create this record. See your administrator for help.",
                messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
                duration:' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
            helper.redirectToRecord(component.get("v.recordId"));
        }
    },
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        if(modalCall){
	        modalCall.openModal();
        }else{
            this.redirectToRecord(cmp.get("v.recordId"));
        }
    }
})