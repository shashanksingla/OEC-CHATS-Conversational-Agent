({
    doInit : function(component, event, helper) {
        helper.doInitHlp(component, event, helper);
    },    
    submitReportRequest:function(component, event, helper) {
        var selectedReport = component.get("v.selectedReport");
        var isValid= true;
        var filters = component.find('input-filters');
        var  countyValid;
        if(!$A.util.isEmpty(component.find("multiSelectPicklist")) && component.get("v.isCountyRequired")){
            if($A.util.isEmpty(component.get("v.selectedCounty"))){
                component.find('multiSelectPicklist').showHelpMessageIfInvalid();
                isValid =false;
            }
            //Added by Nikita for CCCAP-9539
            else{
                if((component.get("v.selectedCounty")).includes("66")){
                    component.set("v.selectedCounty",'66');
                }
            }
        }
        if(!$A.util.isEmpty(component.find("providerLkUpId"))){
            if($A.util.isEmpty(component.get("v.providerIdVal"))){
                component.find("providerLkUpId").showHelpMessageIfInvalid();
                isValid =false;
            }
        }
        if(!$A.util.isEmpty(component.find("providerLkUpId226"))){
            if($A.util.isEmpty(component.get("v.providerIdVal"))){
                component.find("providerLkUpId226").showHelpMessageIfInvalid();
                isValid =false;
            }
        }
        if(!$A.util.isEmpty(component.find("input-field"))){
            if($A.util.isEmpty(component.get("v.selectedCounty"))){
                component.find("input-field").showHelpMessageIfInvalid();
                isValid =false;
            }
        }
        if(!$A.util.isEmpty(filters)){
            if(!$A.util.isEmpty(filters.length)){
                for(var i=0; i<filters.length; i++ ){
                    if(!$A.util.isEmpty(filters[i])){
                        var valid = filters[i].callValidateCurrentPage();
                        if(!valid){
                            isValid=valid;
                        }   
                    }
                }  
            }else{
                if(!$A.util.isEmpty(component.find('input-filters'))){
                    var valid = component.find('input-filters').callValidateCurrentPage();
                    if(!valid){
                        isValid=valid;
                    }   
                }
            }
        } 
        component.set("v.showSpinner", false);
        component.set("v.message",'');
        component.set("v.recordError",[]);
        if(component.get("v.selectedReport").DeveloperName == 'RE306'){
            var hasAnyFilter = false;
            if(!$A.util.isEmpty(component.get("v.selectedCounty"))){
                hasAnyFilter = true;
            }
            if(!hasAnyFilter){
                var dataValue = component.get("v.initData");
                var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList");
                if(!$A.util.isEmpty(reoprtRequestFilterList)){
                    for(var i = 0; i < reoprtRequestFilterList.length; i++){
                        var fieldApiName = reoprtRequestFilterList[i].Field_Api_Name__c;
                        if(!$A.util.isEmpty(dataValue) && !$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")])){
                            if(!$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")][0][fieldApiName])){
                                hasAnyFilter = true;
                                break;
                            }
                        }
                    }
                }
            }
            if(!hasAnyFilter){
                component.set("v.message", 'error');
                component.set("v.recordError", ['At least one filter must be selected.']);
                isValid = false;
            }
        }
        var reportDesc = component.get("v.selectedReport").Description__c;
        var beginDate = component.get("v.beginDate");
        var endDate = component.get("v.endDate");
        var validaity =false;
        if(selectedReport.isMonthYear__c){
            if(selectedReport.isMonthYearFilter__c){
                validaity = helper.checkforMonthYearValidationForRE114(component, event, helper);
            }else{
                if(component.get("v.selectedReport").DeveloperName == 'RE219' || component.get("v.selectedReport").DeveloperName == 'RE222'){
                    validaity =  helper.checkReviewReportCustomValidations(component, event, helper);
                }else{
                    validaity = helper.checkforMonthYearValidation(component, event, helper);
                }
            }
        }else{
              validaity = helper.checkforDateValidation(component, event, helper);  
        }
        console.log('validaity--submitReportRequest-'+validaity);
        console.log('REPORT NAME IS ::' + selectedReport.Report_Name__c);
        console.log('CHECK --> ' + selectedReport.Report_Name__c.startsWith("RE803"));
        if(selectedReport.Report_Name__c.startsWith("RE803")){
            //validaity = false;
            console.log('INSIDE RE803 VALIDATOR');
            validaity = helper.validateRE803Filters(component,event);
            isValid = validaity;
            var valid803 = component.find('input-filters');
            console.log('GOT INPUT FILTERS');
            console.log(Object.getOwnPropertyNames(valid803[0]));
            console.log(Object.getOwnPropertyNames(valid803[1]));
            console.log(Object.getOwnPropertyNames(valid803[2]));
            console.log(valid803);
        }
        //CCCAP-13192
                    else if(component.get("v.selectedReport").DeveloperName=='RE117'){
                        validaity=helper.checkRE117CustomValidations(component, event, helper);
                    }
                    //End CCCAP-13192
        if(selectedReport.Report_Name__c.startsWith("RE705")){
            isValid = validaity;
        }
        if(validaity){
            if(beginDate > endDate && (!$A.util.isEmpty(endDate)) && (!$A.util.isEmpty(beginDate)) && (component.get("v.selectedReport").DeveloperName != 'RE218'&&component.get("v.selectedReport").DeveloperName != 'RE117' )){
                component.set("v.showSpinner", false);
                component.set("v.message",'error');
                component.set("v.recordError",['Start date should be less than End date.']);
            } else {
                if(!$A.util.isEmpty(reportDesc) ){
                    if(isValid){
                        component.set("v.showSpinner", true);
                        helper.submitReportRequestHlp(component, event, helper);
                        if(!$A.util.isEmpty(component.find("providerLkUpId"))){
                            var lookUpCmp = component.find("providerLkUpId");
                            lookUpCmp.clearSelectedValue();
                        }
                        if(!$A.util.isEmpty(component.find("providerLkUpId226"))){
                            var lookUpCmp = component.find("providerLkUpId226");
                            lookUpCmp.clearSelectedValue();
                        }
                    }
                }
            }
        }else{
            component.set("v.showSpinner", false);
        }
        if($A.util.isEmpty(reportDesc)){
            component.find('reportDesc').showHelpMessageIfInvalid();
            component.set("v.message",'error');
            component.set("v.recordError",['You must choose a value from the required filter fields.']);
        }
        /* if(!$A.util.isEmpty(component.get("v.selectedCounty"))){
            component.find("inputMultiSelectPIcklistError").set("v.message","");
            
        }else{
            component.set("v.showSpinner", false);
            var recordError =[];
            var message = 'You must choose a value from the required filter fields.';
            recordError.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError);
            component.find("inputMultiSelectPIcklistError").set("v.message","Please select at least one option.");
        } */
        
    },
    
    navigateToReportHome : function(component, event, helper) {
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef: "c:cannedReportsHomePage"
        });
        event.fire();
    },
    
    navigateToReportInbox : function(component, event, helper) {
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef: "c:cannedReportInboxScreen"
        });
        event.fire();
    },
    
    resetCounty : function(component, event, helper) {
        console.log('selectedCounty---'+component.get("v.selectedCounty"));
        if(!$A.util.isEmpty(component.get("v.selectedCounty"))){
            component.find("inputMultiSelectPIcklistError").set("v.message","");
        }else{
            component.set("v.showSpinner", false);
            var recordError =[];
            var message = 'You must choose a value from the required filter fields.';
            recordError.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError);
            component.find("inputMultiSelectPIcklistError").set("v.message","Please select at least one option.");
        }
    },
    
    validateDate : function(component, event, helper) {
        var selectedEndYear = component.get("v.selectedEndYear");
        var selectedStartYear = component.get("v.selectedStartYear");
        var selectedReport = component.get("v.selectedReport");
        if(!component.get("v.isFinishedFlow") &&
           ((!$A.util.isEmpty(selectedEndYear) && selectedEndYear.length == 4) || (!$A.util.isEmpty(selectedStartYear) && selectedStartYear.length == 4))
          ){
            if(selectedReport.isMonthYearFilter__c){
                helper.checkforMonthYearValidationForRE114(component, event, helper);
            }else{
                if(component.get("v.selectedReport").DeveloperName == 'RE219' || component.get("v.selectedReport").DeveloperName == 'RE222'){
                    helper.checkReviewReportCustomValidations(component, event, helper);
                }else{
                    helper.checkforMonthYearValidation(component, event, helper);
                }
            }
        }
        if($A.util.isEmpty(selectedStartYear) && component.find('startYearMsg')){
            component.find('startYearMsg').set('v.message',"");
        }if($A.util.isEmpty(selectedEndYear) && component.find('endYearMsg')){
            component.find('endYearMsg').set('v.message',"");
        }
    },
    
    validateMonthDate : function(component, event, helper) {
        var selectedStartMonth = component.get("v.selectedStartMonth");
        var selectedEndMonth = component.get("v.selectedEndMonth");
        var selectedStartYear = component.get("v.selectedStartYear");
        var selectedReport = component.get("v.selectedReport");
        if(!component.get("v.isFinishedFlow") && selectedStartYear != null ){
            if(!$A.util.isEmpty(selectedStartMonth)  || (!$A.util.isEmpty(selectedEndMonth))){
                if(selectedReport.isMonthYearFilter__c){
                    helper.checkforMonthYearValidationForRE114(component, event, helper);
                }else{
                    if(component.get("v.selectedReport").DeveloperName == 'RE219' || component.get("v.selectedReport").DeveloperName == 'RE222'){
                        helper.checkReviewReportCustomValidations(component, event, helper);
                    }else{
                        helper.checkforMonthYearValidation(component, event, helper);
                    }
                }
            }
        }
    },
    setProviderValue : function(component, event, helper){        
        var params = event.getParam('arguments');
        if(!$A.util.isEmpty(params.keyValue)){
            var action = component.get('c.getProvider');
            action.setParams({
                'searchKey' : params.key,
                'searchValue' : params.keyValue
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                console.log('state: '+state);
                if(state == 'SUCCESS' && !$A.util.isEmpty(res) && !$A.util.isEmpty(res.objectData)){
                    var provId = res.objectData.providerId;
                    var provName = res.objectData.providerName;
                    if(component.get("v.providerIdVal") != provId){
                        component.set("v.providerIdVal", provId);
                    }
                }
            });        
            $A.enqueueAction(action);
        }
    },
     //Added by Raina for CCCAP-11681
    disableFieldSetValue : function(component, event, helper){
        var params = event.getParam('arguments');
        console.log(JSON.stringify(params));
        if(component.get("v.selectedReport").DeveloperName == 'RE116' && params.key == 'R00883__c'){
            var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList")||[{}];
            let eligibilityTypeIndex = reoprtRequestFilterList.findIndex(val => val.Field_Api_Name__c == 'R00884__c');
            if(eligibilityTypeIndex >-1){
                reoprtRequestFilterList[eligibilityTypeIndex].disabled = (params.keyValue=='Redetermination' || params.keyValue == 'Application date');
            }
            component.set('v.reoprtRequestFilterList',reoprtRequestFilterList);
            if(params.keyValue != 'Eligibility'){
                let initData =  component.get('v.initData');
                initData.Canned_Report_Request_Filter__c[0].R00884__c = undefined;
                component.set('v.initData'+initData);
                var filters = component.find('input-filters');
                if(!$A.util.isEmpty(filters)){
                    if(!$A.util.isEmpty(filters.length)){
                        for(var i=0; i<filters.length; i++ ){
                            if(!$A.util.isEmpty(filters[i])){
                                var fieldAPIName = filters[i].get('v.fieldAPIName');
                                if(fieldAPIName =='R00884__c'){
                                    filters[i].set('v.picklistFieldValue',undefined);
                                }
                            }
                        }  
                    }else{
                        if(!$A.util.isEmpty(component.find('input-filters'))){
                            var fieldAPIName = component.find('input-filters').get('v.fieldAPIName')
                            if(fieldAPIName =='R00884__c'){
                                component.find('input-filters').set('v.picklistFieldValue',undefined);
                            }
                        }
                    }
                }
            }
        }
        //added by Nikita for CCCAP-12973
        if(component.get("v.selectedReport").DeveloperName == 'RE209'){
            var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList")||[{}];
            let initData =  component.get('v.initData');
            if(params.key == 'providerID'){
                let caseIndex = reoprtRequestFilterList.findIndex(val => val.Field_Api_Name__c == 'CaseID');
                if(caseIndex >-1){
                    reoprtRequestFilterList[caseIndex].disabled = !$A.util.isEmpty(params.keyValue);
                    initData.Canned_Report_Request_Filter__c[0].CaseID = undefined;
                }
            }
            if(params.key == 'CaseID'){
                let provIndex = reoprtRequestFilterList.findIndex(val => val.Field_Api_Name__c == 'providerID');
                if(provIndex >-1){
                    reoprtRequestFilterList[provIndex].disabled = !$A.util.isEmpty(params.keyValue);
                    initData.Canned_Report_Request_Filter__c[0].providerID = undefined;
                }
            }       
            component.set('v.initData'+initData);     
            component.set('v.reoprtRequestFilterList',reoprtRequestFilterList);
        }
	}
})