({
    callModal : function(component, modalName) {
        debugger;
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
                /*var sectionInformation = component.get("v.sectionInformation"); 
                var sectionBreakerPoint = 0;
                for(var i=0;i<fieldDefinitions.length;i++){
                    var fieldDefinition = fieldDefinitions[i];
                    if(!$A.util.isEmpty(sectionInformation[fieldDefinition.fieldAPIName])){
                        fieldDefinition.preSectionName = sectionInformation[fieldDefinition.fieldAPIName];
                        if(i!=0 && sectionBreakerPoint%2==0){
                            fieldDefinition.sectionBreakerPoint = true;
                            sectionBreakerPoint = 0;
                        }else{
                            sectionBreakerPoint++;
                        }
                    }
                    if(!$A.util.isEmpty(fieldDefinition.referenecedObjectName) && component.get("v.sObjectName")==fieldDefinition.referenecedObjectName){
                        var providerFiscalAgreement = component.get("v.providerFiscalAgreement");
                        providerFiscalAgreement[fieldDefinition.fieldAPIName] = component.get("v.recordId");
                    }
                }*/
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
                            debugger;
                            component.set("v.showSpinner", false);
                            //component.set("v.providerFiscalAgreement", response.getReturnValue());
                            
                            if(component.get("v.providerFiscalAgreement").DTE_END_AGRMT__c) {
                                component.set("v.effectiveEndDate", response.getReturnValue().DTE_END_AGRMT__c);
                            }
                            if(!$A.util.isEmpty(response.getReturnValue().OwnerId)){
                                component.set("v.ownerId", response.getReturnValue().OwnerId);
                            }
                        });
                        $A.enqueueAction(getDataOnLoad);
                    } else{
                        
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        component.set("v.providerFiscalAgreement.OwnerId",userId);
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
        var effectiveEndDate= component.get('v.effectiveEndDate');
        var currentDate =  this.getCurrentSystemDate();
        var reasonForClosure= component.get('v.reasonForClosure');
        //var todayDate = new date();
        //CCCAP-15537 changing the condition to compare with begin date as well
        if(effectiveEndDate < currentDate || component.get("v.providerFiscalAgreement").DTE_END_AGRMT__c < effectiveEndDate || effectiveEndDate<component.get("v.providerFiscalAgreement").DTE_BEGIN_AGRMT__c) 
        {
            component.find('effectiveEndDate').set('v.message', 'Fiscal Agreement End Date should be greater or equal to today, less than or equal to the current FA end date and End Date may not be before Begin Date.') ;
            isValid = false;
        }else{
            component.find('effectiveEndDate').set('v.message', '') ; 
        }
        if(reasonForClosure == null){
            component.find('reasonForClosure').set('v.message', 'Fiscal Agreement can not be closed as there is no Reason for Closure') ;
            isValid = false;
        }else{
            component.find('reasonForClosure').set('v.message', '') ; 
        }
        return isValid;
    },
    
    getCurrentSystemDate : function(addDays, addMonths){
        debugger;
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