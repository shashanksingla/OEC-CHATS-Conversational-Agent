({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component, "c.getIneligibleReason", function(response){
          
            
            component.set('v.eligibleRunSFId',response.objectData.eligibleRunSFId);
            var ineligReasons = [];
            var ineligibilityFailures = component.get("v.ineligibilityFailures");
            var reasonToIndivIneligibilityFailure = {};
            var reasonFieldAPIName = !$A.util.isEmpty(component.get("v.FCIndividualID"))?'cde_reason_failr_eligty_indiv__c':'cde_reason_failr_fcompsn__c';
            if(!$A.util.isEmpty(ineligibilityFailures)){
                ineligibilityFailures.forEach(function(ineligReasonFailr){
                    reasonToIndivIneligibilityFailure[parseInt(ineligReasonFailr[reasonFieldAPIName])]=ineligReasonFailr;
                });
            }
           var ineligReasonsToBeDisplayed = [];
            response.objectData.ineligReasons.forEach(function(ineligReason){
                var selected = !$A.util.isEmpty(ineligReason.CDE_REASON__c) && !$A.util.isEmpty(reasonToIndivIneligibilityFailure[parseInt(ineligReason.CDE_REASON__c)])?true:false;
                if(selected==true){
                    ineligReasonsToBeDisplayed.push(ineligReason.TXT_REASON_DESC_SHORT__c);
                }
                var reasonCode = ineligReason.CDE_REASON__c;
                /*if(reasonCode.length!=3){
                    reasonCode = '000'+reasonCode;
                    reasonCode = reasonCode.substring(reasonCode.length-3,reasonCode.length);
                }*/
                ineligReasons.push({
                    'selected':selected,
                    'code':reasonCode,
                    'description':ineligReason.TXT_REASON_DESC_SHORT__c
                });
            });
            
           
            component.set("v.ineligReasons",ineligReasons);
            component.set("v.ineligReasonsToBeDisplayed",ineligReasonsToBeDisplayed);
        }, {'FCEligibilityID':component.get("v.FCEligibilityID")
           }, true, null);
    },
    doShowEligibilityFlowFailureReasonOverride : function(component, event, helper){
        
        $A.createComponent("c:eligibilityFlow_FailureReason_Override", {
            ineligibilityFailures:component.get("v.ineligibilityFailures"),
            FCIndividualID:component.get("v.FCIndividualID"),
            FCEligibilityID:component.get("v.FCEligibilityID"),
            ineligReasons:component.get("v.ineligReasons"),
            eligibleRunSFId:component.get("v.eligibleRunSFId")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: !$A.util.isEmpty(component.get("v.FCIndividualID"))?'Individual Ineligibility Reasons':'Household Ineligibility Reasons',
                    body: content,
                    showCloseButton: false,
                    cssClass: "slds-modal_large",
                    closeCallback: function() {
                        
                    }                                       
                });
            }
        });
    }
})