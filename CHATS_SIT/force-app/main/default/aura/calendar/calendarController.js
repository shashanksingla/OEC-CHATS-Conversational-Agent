({
    doInit : function(component, event, helper) {
        var today = new Date();
        var month = today.getMonth(); // Returns 9
        var year = today.getFullYear();
        component.set("v.selectedMonth",month);
        component.set("v.selectedYear",year);
        component.set("v.isEncumbrnceCreated",true);
        var rateTypeOptions = component.get("v.rateTypeOptions");
        var options = [];
        options.push({
            'label' : '--None--',
            'value' : null,
            'class' : 'optionClass'
        });
        var concatOptions=options.concat(rateTypeOptions);
        component.set("v.rateTypeOptions",concatOptions);
        component.set("v.months",
                      [{ value: "0", label: "January" },
                       { value: "1", label: "February" },
                       { value: "2", label: "March" },
                       { value: "3", label: "April" },
                       { value: "4", label: "May" },
                       { value: "5", label: "June" },
                       { value: "6", label: "July" },
                       { value: "7", label: "August" },
                       { value: "8", label: "September" },
                       { value: "9", label: "October" },
                       { value: "10", label: "November" },
                       { value: "11", label: "December" }]
                     );
                     var action = component.get('c.fetchProviderClosureRecs');
                     action.setParams({
                         'provRecId' : component.get("v.provIdValtwo"),
                         'countyId' : component.get("v.countySFId")
                     });
                     action.setCallback(this, function(response) {
                         var state = response.getState();
                         if (state == 'SUCCESS') {
                             var res =response.getReturnValue();
                             if(res.isSuccessful){
                                 if(res.objectData.provClosDates){
                                     component.set("v.provClosDteOptions", res.objectData.provClosDates);
                                 }
                             }
                         } 
                     });        
                     $A.enqueueAction(action);
    },
    viewCalendar : function(component, event, helper) {
        var allValid = component.find('viewCalendarInput').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        if (allValid) {    
            
            var seletedMonth = component.get("v.selectedMonth");//component.find("month").get("v.value");
            var seletedYear = component.get("v.selectedYear");//component.find("year").get("v.value");
            //component.find("selectedMonth").set("v.value", seletedMonth);
            //component.find("selectedYear").set("v.value", seletedYear);
            helper.getDaysInAMonth(seletedMonth, seletedYear, component);
        } else {
        }},
    updateAuthEncmbrCalendarCell : function(component, event, helper) {
        var mapDateToEncumbranceUpdate = component.get("v.mapDateToEncumbranceUpdate");
        var lstEncumbranceToBeUpdated= [];
        for(var key in mapDateToEncumbranceUpdate){
            var encumbranceRec = mapDateToEncumbranceUpdate[key];
            encumbranceRec.sobjectType ='batchsit_t_auth_encmbr__x';
            lstEncumbranceToBeUpdated.push(encumbranceRec);
        }
        component.set("v.lstEncumbranceToBeUpdated", lstEncumbranceToBeUpdated);
        if(lstEncumbranceToBeUpdated.length>0){
        helper.callServerAndHandleError(component,"c.callUpdate", 
                                        function(response){
                                            var cells = component.find('authEncmbrEditCell');
                                            if(response.isSuccessful==true){
                                                debugger;
                                                for(var i in cells){
                                                    var cell = cells[i];
                                                    var isDirty = cell.get('v.isDirty');
                                                    //var careDate = cell.get('v.anAuthEncmbr').dte_care__c ;
                                                    if(isDirty == 'true' ){
                                                        cell.set("v.updatedSuccessfully", 'true');
                                                        cell.set("v.isDirty",false);
                                                        var authEncmbr= cell.get("v.anAuthEncmbr");
                                                        cell.set("v.originalHours", authEncmbr.cnt_hour_care__c);
                                                        cell.set("v.originalRateType", authEncmbr.cde_type_unit_care__c)
                                                    }
                                                }
                                                component.set("v.mapDateToEncumbranceUpdate",{});
                                            }
                                            else{
                                                for(var i in cells){
                                                    var cell = cells[i];
                                                    var isDirty = cell.get('v.isDirty');
                                                    if(isDirty == 'true' ){
                                                        cell.set("v.updatedSuccessfully", 'false');
                                                        cell.set("v.recordError",'Problem saving record, error: ' + response.message);
                                                    }
                                                }  
                                            }
                                        }, {'lstAuthEncumbRec':lstEncumbranceToBeUpdated}, false, null);
            }
        else{
            helper.fireToast('Dismissible', 'Error', 'Error!', 'You must edit at least one day to save changes to the schedule');
        }  
    },
    handleUnsavedChanges : function(component, event, helper) {
        var cells = component.find('authEncmbrEditCell');
        var isInvalid=false;
        for(var i in cells){
            var cell = cells[i];
            var isDirty = cell.get('v.isDirty');
            if(isDirty == 'true'){
                isInvalid=true;
            }
        }
        return isInvalid;
    },
    updateMapDateToEncumbrance : function(component, event, helper) {
        var mapDateToEncumbranceUpdate = component.get("v.mapDateToEncumbranceUpdate");
        var encumbranceRec = event.getParam("encumbranceRec");
        var isDelete = event.getParam("isDelete");
        var key = encumbranceRec.dte_care__c;
        if(!isDelete){
            mapDateToEncumbranceUpdate[key] = encumbranceRec;
        }else{
            delete mapDateToEncumbranceUpdate[key];            
        }
        component.set("v.mapDateToEncumbranceUpdate",mapDateToEncumbranceUpdate);
    }
})