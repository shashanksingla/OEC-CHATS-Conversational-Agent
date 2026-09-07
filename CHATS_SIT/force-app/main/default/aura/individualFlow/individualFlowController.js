({
    doInit : function(component, event, helper) {
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        if(sObjectName == 'T_SBSD_INDIV__c'){
            component.set("v.isCreate", false);
        }else{
            helper.getIsIntake(component);
        }
    },
    doFinish : function(component, event, helper) {        
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==2){
            // handling client side validations
            var childCmp = component.find("individualCitizenshipPg2");
            childCmp.callValidateCurrentPage();
            var isCurrentPageValid = component.get("v.isCurrentPageValid");
            if(isCurrentPageValid == true){ 
                var indivInfoRec = component.get("v.indivInfoRec");
                var age =helper.getIndividualAge(component);	        
                if(age<19 &&(indivInfoRec.CDE_VALUE_INFO_INDIV__c == 'N/A-not requesting child')){
                    helper.callModal(component,'confirmationModal_individualCitizenshipPg2');
                }else{
                    helper.finishHlp(component, event, helper);
                }
                
            }
        }
    },
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId, "detail");
    },    
    doPrevious : function(component, event, helper) {
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    doNext : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            // handling client side validations
            var childCmp = component.find("individualInfoPg1");
            childCmp.callValidateCurrentPage();
            console.log(component.get("v.isCurrentPageValid"));
            
            
            if(component.get("v.isCurrentPageValid")==true){  
                // Start
                var age =helper.getIndividualAge(component);	        
                var indivRecord = component.get("v.indivRec");
                if(age<19 &&(indivRecord.IND_CDE_TYPE_VERIF_DOB__c == 'N/A-not requesting child')){
                    helper.callModal(component,'confirmationModal_individualInfoPg1');
                }else{
                    var caseRec = component.get("v.caseRec");
                    var indivRecToBeUpserted = component.get("v.indivRec");
                    console.log('indi '+indivRecToBeUpserted);
                    // server side call
                    helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                    function(response){
                                                        var mergedIndiv = helper.merge(component.get("v.indivRec"), response.objectData.upsertedRecords[0]);
                                                        component.set("v.indivRec", mergedIndiv);
                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    }, {'lstSObject':[indivRecToBeUpserted]}, false, null);
                    
                }
                // end
            }
        }
    },
    confirmNext : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        var indivRecToBeUpserted = component.get("v.indivRec");
        console.log('indi '+indivRecToBeUpserted);
        // server side call
        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                        function(response){
                                            var mergedIndiv = helper.merge(component.get("v.indivRec"), response.objectData.upsertedRecords[0]);
                                            component.set("v.indivRec", mergedIndiv);
                                            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                        }, {'lstSObject':[indivRecToBeUpserted]}, false, null);
        component.find("overlayLib").notifyClose();	
        
    },
    confirmFinish : function(component, event, helper){
        component.find("overlayLib").notifyClose();	
        helper.finishHlp(component, event, helper);
        
    },
})