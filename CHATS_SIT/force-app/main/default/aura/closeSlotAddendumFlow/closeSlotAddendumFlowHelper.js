({
    callModal : function(component, modalName) {
        //debugger;
        var modalCall = component.find(modalName);
        modalCall.openModal();
    },
    
    getInitData : function(component) {
        component.set("v.showSpinner", true);
        var getFielDefinitionAction = component.get("c.getFieldDefinition");
        getFielDefinitionAction.setParams({
            lstObjectToField : component.get("v.fieldNames")
        });
        getFielDefinitionAction.setCallback(this, function(response){
            if(response.getState()=='SUCCESS') {
                var fieldDefinitions = response.getReturnValue();
                component.set("v.fieldDefinition",fieldDefinitions);
                if(response.getReturnValue()) {
                    var receivedMap = response.getReturnValue();
                    var dataString = JSON.stringify(receivedMap);
                    if(!$A.util.isEmpty(component.get("v.parentId"))){
                        var getDataOnLoad = component.get("c.getDataOnLoadInCHATS");
                        getDataOnLoad.setParams({
                            fieldList: dataString,
                            sObjectId: component.get("v.parentId")
                        });
                        getDataOnLoad.setCallback(this, function(response){
                            //debugger;
                            component.set("v.showSpinner", false);
                            //component.set("v.providerFiscalAgreement", response.getReturnValue());
                            
                            if(component.get("v.slotContractAddendum").DTE_END_ADDENDUM__c) {
                                component.set("v.effectiveEndDate", response.getReturnValue().DTE_END_ADDENDUM__c);
                            }
                            if(!$A.util.isEmpty(response.getReturnValue().OwnerId)){
                                component.set("v.ownerId", response.getReturnValue().OwnerId);
                            }
                        });
                        $A.enqueueAction(getDataOnLoad);
                    } else{
                        
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        component.set("v.slotContractAddendum.OwnerId",userId);
                        component.set("v.showSpinner", false);
                        component.set("v.initDataLoaded",true);
                    }
                }                  
            }
            else if(response.getState()=='ERROR') {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(getFielDefinitionAction);
    },
    
    checkCustomValidations : function(component,helper){
        var isValid= true;
        var effectiveEndDate = component.get('v.effectiveEndDate');
        var endDateCmp = component.find('effectiveEndDate');
        var currentDate =  this.getCurrentSystemDate();
        var reasonForClosure= component.get('v.reasonForClosure');
        var addendumRecord = component.get('v.slotContractAddendum');
        var effectiveBeginDate = addendumRecord.DTE_BEGIN_ADDENDUM__c;
        var FAeffectiveEndDate=addendumRecord.IDN_FISCAL_AGREEMENT__r.DTE_END_AGRMT__c;
        console.log('Begin Date'+effectiveBeginDate);
        
        if($A.util.isEmpty(effectiveEndDate)){
            endDateCmp.set('v.message', 'Slot Contract Addendum can not be closed without Addendum End Date') ;
            isValid = false;
        } else if(effectiveEndDate <= effectiveBeginDate){
            endDateCmp.set('v.message', 'Slot Contract Addendum End Date should be greater than Slot Contract Addendum Begin Date');
            isValid = false;
        }else if(effectiveEndDate < currentDate || addendumRecord.DTE_END_ADDENDUM__c < effectiveEndDate) {            
            endDateCmp.set('v.message', 'Slot Contract Addendum End Date should be greater than or equal to today’s date OR less than or equal to current Slot Contract Addendum End Date.');
            isValid = false;
        }else if(effectiveEndDate > FAeffectiveEndDate) {            
            endDateCmp.set('v.message', 'Slot Contract Addendum End Date cannot be greater than Fiscal Agreement End Date');
            isValid = false;
        }
        
        else {
            var eDateArr = effectiveEndDate.split('-');
            var eDate = new Date(eDateArr[0], eDateArr[1]-1, eDateArr[2]);
            var tempDate = new Date(eDate.getTime() + 86400000);
            if(tempDate.getDate() != 1){
                endDateCmp.set("v.message",'Slot Contract Addendum End Date should be last day of Month');
                isValid = false;
            } else{
                endDateCmp.set('v.message', '') ; 
            }
        }
        
        if($A.util.isEmpty(reasonForClosure)){
            component.find('reasonForClosure').set('v.message', 'Slot Contract Addendum can not be closed without Reason for Closure') ;
            isValid = false;
        }else{
            component.find('reasonForClosure').set('v.message', '') ; 
        }
        return isValid;
    },
    
    getCurrentSystemDate : function(addDays, addMonths){
        //debugger;
        var today = new Date();
        if(addDays && addDays != null){
        today = today + addDays;
        }
        if (addMonths && addMonths!=null){
           today = today.setMonth(today.getMonth()+addMonths); 
        }
        var dd = today.getDate();
        var MM = today.getMonth()+1;
        var yyyy = today.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    }
})