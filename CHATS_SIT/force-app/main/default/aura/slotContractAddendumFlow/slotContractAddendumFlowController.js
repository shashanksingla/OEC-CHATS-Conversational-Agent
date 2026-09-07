({
	doInit : function(component, event, helper) {
		if(component.get("v.addendumBeginDate")==null||component.get("v.addendumBeginDate")==''){
            component.set("v.addendumBeginDate", '');
        }
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                            component.set("v.countyName",response.objectData.countyName);
                                            component.set("v.providerFARec",response.objectData.fiscalAgreement);
                                            component.set("v.providerQualityRating",response.objectData.providerQualityRating);
                                            component.set("v.maxProviderSlots",response.objectData.maxProviderSlots);
                                            component.set("v.addendumRec",response.objectData.slotContractRec);
                                            var addendumRecord = component.get("v.addendumRec");
                                            if(addendumRecord.Id != null){
                                                component.set("v.isCreate", false);
                                                component.set("v.currentTabName", 'Edit Slot Contract Addendum');
                                                component.set("v.cancelMsg", 'Cancel Slot Contract Addendum Update?');
                                                if(addendumRecord.CDE_STATUS__c != 'DFT'){                                                    
                                                    helper.callModal(component,"editNotAllowedModal");
                                                }
                                            }
                                            if(response.objectData.effectiveBeginDate!=null) {
                                                component.set("v.addendumBeginDate",response.objectData.effectiveBeginDate);                                                
                                                addendumRecord.DTE_BEGIN_ADDENDUM__c = response.objectData.effectiveBeginDate;
                                                component.set("v.addendumRec", addendumRecord);
                                            }
                                            if(response.objectData.countyMatched == false) {
                                                var recordError = 'The Fiscal Agreement record that you are trying to access belongs to '+response.objectData.countyName+' county. This does not match your assigned county(ies).';
                                               	component.set("v.msgOnDiffOwnerCounty", recordError);
                                               	helper.callModal(component,"warningModalOnDiffOwnerCounty");
                                            }
                                            if(response.objectData.isSlotEnabled == null || response.objectData.isSlotEnabled != 'Y' || response.objectData.maxProviderSlots == null) {
                                                var recordError = 'Slot Contracts option is not enabled for '+response.objectData.countyName+' County.'
                                                component.set("v.msgforSlotContractOption", recordError);
                                                helper.callModal(component,"slotContractNotAllowedModal");
                                            }
                                        },
                                        {'prvdrFiscalAgreementId':component.get("v.recordId")}, false, null);
	},
    doFinish: function(component, event, helper){
        var errors = [];
        var isValid = true;
        var addendumRecord = component.get("v.addendumRec");
        var faRecord = component.get("v.providerFARec");
        var slotCmp = component.find('T_SLOT_CONTRACT_ADDENDUM__c-CNT_SLOT_CONTRACTS__c');
        var beginDateCmp = component.find('T_SLOT_CONTRACT_ADDENDUM__c-DTE_BEGIN_ADDENDUM__c');
        var endDateCmp = component.find('T_SLOT_CONTRACT_ADDENDUM__c-DTE_END_ADDENDUM__c');
        slotCmp.set("v.message", '');
        beginDateCmp.set("v.message", '');
        endDateCmp.set("v.message", '');
        
        var today = new Date();
        if(addendumRecord.CNT_SLOT_CONTRACTS__c == null ){
            slotCmp.set("v.message",'Please enter a value');
            isValid = false;
        } else if(addendumRecord.CNT_SLOT_CONTRACTS__c <= 0){
            slotCmp.set("v.message",'Number of Slot Contracts should be greater than 0');
            isValid = false;
        } else if(addendumRecord.CNT_SLOT_CONTRACTS__c > component.get("v.maxProviderSlots")){
            slotCmp.set("v.message", 'Max allowed slot contracts per provider are '+component.get("v.maxProviderSlots"));
            isValid = false;
        }
        if(addendumRecord.DTE_BEGIN_ADDENDUM__c == null || addendumRecord.DTE_BEGIN_ADDENDUM__c == ''){
            beginDateCmp.set("v.message",'Please enter a value');
            isValid = false;
        } else {
            var bDateArr = addendumRecord.DTE_BEGIN_ADDENDUM__c.split('-');
            var bDate = new Date(bDateArr[0], bDateArr[1]-1, bDateArr[2]);
            if(addendumRecord.DTE_BEGIN_ADDENDUM__c < component.get("v.addendumBeginDate") || bDate.getDate() != 1){
                if(addendumRecord.Id != null){
                    beginDateCmp.set("v.message",'Begin Date should be First Day of Future Month and greater than current Begin Date');
                } else {
                    beginDateCmp.set("v.message",'Begin Date should be First Day of Future Month');
                }
                isValid = false;
            }
        }
        if(addendumRecord.DTE_END_ADDENDUM__c == null || addendumRecord.DTE_END_ADDENDUM__c == ''){
            endDateCmp.set("v.message",'Please enter a value');
            isValid = false;
        } else {
            var eDateArr = addendumRecord.DTE_END_ADDENDUM__c.split('-');
            var eDate = new Date(eDateArr[0], eDateArr[1]-1, eDateArr[2]);
            var tempDate = new Date(eDate.getTime() + 86400000);
            if(tempDate.getDate() != 1){
                endDateCmp.set("v.message",'End Date should be Last Day of Month');
                isValid = false;
            } else if(addendumRecord.DTE_END_ADDENDUM__c > faRecord.DTE_END_AGRMT__c){
                endDateCmp.set("v.message",'End Date cannot be greater than Fiscal Agreement End Date');
                isValid = false;
            } else if(addendumRecord.DTE_BEGIN_ADDENDUM__c != null){
                var bDateArr = addendumRecord.DTE_BEGIN_ADDENDUM__c.split('-');
                var bDate = new Date(bDateArr[0], bDateArr[1]-1, bDateArr[2]);
                
                if(bDate >= eDate){
                    endDateCmp.set("v.message",'End Date should be greater than Begin Date');
                    isValid = false;
                } else {
                    var tempDate = new Date(bDate.setMonth(bDate.getMonth()+12));
                    if(tempDate < eDate){
                        endDateCmp.set("v.message",'Max of 12 months of span allowed between begin and end date');
                        isValid = false;
                    }
                }
            }
        }
        
        if(isValid == true){
            var bDateArr = addendumRecord.DTE_BEGIN_ADDENDUM__c.split('-');
            var bDate = new Date(bDateArr[0], bDateArr[1]-1, bDateArr[2]);
            var today = new Date();
            var Difference_In_Time = bDate.getTime() - today.getTime();
 			var Difference_In_Days = Difference_In_Time / (1000 * 3600 * 24);
            console.log(Difference_In_Days);
            if(Difference_In_Days <= 15){
                helper.callModal(component,"warningForBeginDateModal");
            }else {
            	helper.saveAddendumRecord(component, helper);
            }
        }
       
        component.set("v.pageMessages", errors);
        component.set("v.messageType", "error");
    }, 
    actionOnConfirmYesButton: function(component, event, helper){
       var modalCall = component.find("warningForBeginDateModal");
       modalCall.hideConfirmModal();
        helper.saveAddendumRecord(component, helper);
    },
    doCancel: function(component, event, helper){
        helper.callModal(component,'confirmationModalOnCancel');
    },    
    actionOnCancelYesButton: function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    }
})