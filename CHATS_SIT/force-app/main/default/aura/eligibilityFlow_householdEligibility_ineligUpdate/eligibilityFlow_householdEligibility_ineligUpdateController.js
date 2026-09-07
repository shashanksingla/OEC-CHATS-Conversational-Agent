({
    doInit : function(component, event, helper) {
        
        var ineligFailureRecs = component.get("v.householdIneligibilityFailure");
        var ineligFailureReasons='';
        if(ineligFailureRecs!=undefined &&  ineligFailureRecs!=null) {
            
            if(ineligFailureRecs.length > 0) {
                for(var i=0; i<ineligFailureRecs.length; i++) {
                    if(i==0) {
                        ineligFailureReasons = ineligFailureReasons + ineligFailureRecs[i].cde_reason_failr_fcompsn__c;   
                    } else {
                        ineligFailureReasons = ineligFailureReasons + ',' + ineligFailureRecs[i].cde_reason_failr_fcompsn__c;       
                    }
                    
                }
              
                
            }   
        }
        component.set("v.ineligFailureReasons",ineligFailureReasons);
        
        component.set("v.loadDoInit", true);
    },
    
    updateIneligReasons : function(component,event,helper) {
        var ineligCode = event.getSource().get("v.value");
        var toCreate = event.getSource().get("v.checked");
        var inelig = event.getSource().get("v.label");
        var elementPresent=false;
        if(component.get("v.householdIneligibilityFailure")) {
            component.get("v.householdIneligibilityFailure").forEach(function(ineligReasons){
               
                if(ineligReasons.cde_reason_failr_fcompsn__c == ineligCode) {
                    elementPresent=true;
                    if(!toCreate) {
                        var deleteIneligReasons = component.get("v.deleteIneligReasons");
                        deleteIneligReasons.push(ineligReasons);
                        component.set("v.deleteIneligReasons", deleteIneligReasons);
                        var addIneligReasons =  component.get("v.addIneligReasons");
                        if(addIneligReasons.indexOf(inelig)>=0) {
                            addIneligReasons.splice(addIneligReasons.indexOf(ineligCode),1);
                            component.set("v.addIneligReasons", addIneligReasons); 
                        }
                    }
                } else {
                    if(toCreate) {
                        var addIneligReasons =  component.get("v.addIneligReasons");
                        if(addIneligReasons.indexOf(inelig) <0) {
                            addIneligReasons.push(inelig);   
                        }
                        //component.set("v.addIneligReasons", addIneligReasons);  
                        var deleteIneligReasons = component.get("v.deleteIneligReasons");
                        if(deleteIneligReasons.length>0) {                      
                            deleteIneligReasons.forEach(function(delIneligReas) {
                                if(delIneligReas.cde_reason_failr_fcompsn__c == ineligCode) {
                                    deleteIneligReasons.splice(deleteIneligReasons.indexOf(delIneligReas),1);
                                    component.set("v.deleteIneligReasons", deleteIneligReasons);
                                }
                            });   
                        }
                    }
                }
            });   
            if(elementPresent) {
                var addIneligReasons =  component.get("v.addIneligReasons");
                addIneligReasons.splice(addIneligReasons.indexOf(inelig), 1);
            }
        } else{
            if(toCreate) {
                var addIneligReasons =  component.get("v.addIneligReasons");
                if(addIneligReasons.indexOf(inelig) <0) {
                    addIneligReasons.push(inelig);   
                }
            } else {
                var addIneligReasons =  component.get("v.addIneligReasons");
                if(addIneligReasons.indexOf(inelig) >0) {
                    addIneligReasons.splice(addIneligReasons.indexOf(inelig), 1); 
                }
            }
        }
        
    },
    
    updateIndivInelig : function(component, event, helper) {
        var parentId = component.get("v.householdEligibilityId");
        var sObjectsToUpdate =[];
        var ineligReasonsLst = component.get("v.ineligReasons");
        component.get("v.addIneligReasons").forEach(function(ineligReasons){
            var idn_doc__c='';
            if(ineligReasonsLst) {
                for(var i=0;i<ineligReasonsLst.length;i++) {
                    if(ineligReasonsLst.CDE_REASON__c == ineligReasons) {
                        idn_doc__c=ineligReasonsLst.IDN_DOC__c;
                    }
                }
            }
            sObjectsToUpdate.push({'sobjectType' : 'batchsit_t_fcompsn_failr__x',
                                   'cde_reason_failr_fcompsn__c' : ineligReasons.toString(),
                                   'idn_eligty_fcompsn__c' : component.get("v.householdEligibilityId"),
                                   'ind_updtd_user__c' : 'Y',
                                   'idn_doc__c':idn_doc__c});    
        });
        helper.callServer(component,"c.insertExternalObjRecords", function(response) {
            helper.callServer(component,"c.deleteRecords", function(response) {
                helper.closeIneligReason(component, true);
            },{'deleteObjects':component.get("v.deleteIneligReasons")},false,null);
        },{lstSObject:sObjectsToUpdate,
           isFinalStep:true}, false, null);  
    },
    
    closeModal : function(component, event, helper) {
        helper.closeIneligReason(component, false);
    }
})