({
    toastMessage: function (state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
    },
    callModal: function (cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    checkValidity : function(component,helper){
        var anyInvalid=true;
        let waitforAttend = false;
        var inputCmp = component.find('fieldBegin');
        var begin = component.get("v.provClosure.beginDate");   
        var enddt =component.get("v.provClosure.endDate"); 
        var nineDaysAgo = component.get("v.nineDaysAgo"); // Added as part of CCCAP-10618
        var fiscalStartDate = component.get("v.faStartDate"); // Added as part of CCCAP-8947
        var fiscalEndDate = component.get("v.faEndDate"); // Added as part of CCCAP-8947
		var holidayList = component.get("v.countyHolidays");// CCCAP-11572        
        if (begin=='' || begin == null || begin ==undefined) {
            inputCmp.setCustomValidity("Complete this field.");
            anyInvalid=false;
        }else if(begin < nineDaysAgo){  
            inputCmp.setCustomValidity("Cannot be prior to {today + 9 days in the past}");
            anyInvalid=false;
        }else if(begin > fiscalEndDate || begin < fiscalStartDate){
            inputCmp.setCustomValidity("Provider Closure Begin Date cannot be prior to Fiscal Agreement Begin Date or after Fiscal Agreement End Date.");
            anyInvalid=false;
        }
        else{
            inputCmp.setCustomValidity("");
        }
        inputCmp.reportValidity();
        
        var inputCmp1 = component.find('fieldEnd');     
        if (enddt=='' || enddt == null || enddt ==undefined) {
            inputCmp1.setCustomValidity("Complete this field.");
            anyInvalid=false;
        }else if(enddt<begin){
            inputCmp1.setCustomValidity("Provider Closure End Date cannot be before Provider Closure Begin Date.");
            anyInvalid=false;
        }else if(enddt > fiscalEndDate || enddt < fiscalStartDate){
            inputCmp1.setCustomValidity("Provider Closure End Date cannot be after to Fiscal Agreement End Date or prior to Fiscal Agreement Begin Date.");
            anyInvalid=false;
        }else {
            inputCmp1.setCustomValidity("");
        }
        inputCmp1.reportValidity();
//CCCAP-11572
      var isHolidayIncluded = false;
        var currentDate = new Date(begin);
        var lastDate= new Date(enddt);
        while (currentDate <= lastDate) {
            console.log(currentDate);
            if (holidayList.includes($A.localizationService.formatDate(currentDate, "YYYY-MM-DD"))) {
                isHolidayIncluded = true;
                break;
            }
            currentDate.setDate(currentDate.getDate() + 1);
        }

        if (isHolidayIncluded) {
            helper.toastMessage('Error', 'The entered date range includes holiday(s) that are paid by your County Rate Plan. Closure records cannot be created on county-paid holiday(s). Please edit the date range entered to exclude county-paid holidays and attempt the action again.');
            anyInvalid = false;
            component.set("v.provClosure.beginDate","");
            component.set("v.provClosure.endDate","");
        }

//end CCCAP-11572
        if(anyInvalid && begin < component.get("v.today") && component.get("v.attendanceChecked")==false){ //added as part of CCCAP-10618
            component.set("v.hasPastDate", true);
            anyInvalid=false;
            waitforAttend = true;
            var provId = component.get("v.provdId");
            var oneDayAgo=$A.localizationService.formatDate(new Date((new Date()).valueOf() - 1000*60*60*24*1), "YYYY-MM-DD");
            const dateRangesForProv = new Map();
            var startDate = $A.localizationService.formatDateUTC(new Date(begin),'YYYY-MM-DD');
            var endDate = $A.localizationService.formatDateUTC(new Date(enddt),'YYYY-MM-DD');
            while (startDate <= endDate) {
                dateRangesForProv.set(startDate,"false");
                startDate = $A.localizationService.formatDateUTC(new Date((new Date(startDate)).valueOf() + 1000*60*60*24*1), "YYYY-MM-DD");
            }
            component.set("v.spinner", true);
            var action = component.get("c.checkAttendance");
            action.setParams({ provId : provId, fromDate : nineDaysAgo, toDate : oneDayAgo});
            action.setCallback(this, function(response){
                var result=response.getReturnValue();
                if(result.isSuccessful == true){
                    var lstTransaction1 = result.objectData.lstTransaction1;
                    var lstTransaction2 = result.objectData.lstTransaction2;
                    if(!$A.util.isEmpty(lstTransaction1)){
                        for(var i=0;i<lstTransaction1.length;i++){
                            var transactionDateTimeUTC = $A.localizationService.formatDateTimeUTC(lstTransaction1[i].CI_Transaction_Time_c__c);
                            var timezone = $A.get("$Locale.timezone");
                            var formattedTransactionDate = '';
                            $A.localizationService.UTCToWallTime(new Date(transactionDateTimeUTC), timezone, function(walltime) {
                                var dd = walltime.getDate();
                                var MM = walltime.getMonth()+1;
                                var yyyy = walltime.getFullYear();
                                if(dd<10){
                                    dd='0'+dd;
                                } 
                                if(MM<10){
                                    MM='0'+MM;
                                } 
                                formattedTransactionDate = yyyy+'-'+MM+'-'+dd;
                            })
                            if(dateRangesForProv.has(formattedTransactionDate) && formattedTransactionDate >= nineDaysAgo && formattedTransactionDate <= oneDayAgo){
                                dateRangesForProv.set(formattedTransactionDate,"true");
                            }
                        }
                    }
                    if(!$A.util.isEmpty(lstTransaction2)){
                        for(var i=0;i<lstTransaction2.length;i++){
                            var transactionDateTimeUTC = $A.localizationService.formatDateTimeUTC(lstTransaction2[i].CI_Transaction_Time_c__c);
                                var timezone = $A.get("$Locale.timezone");
                                var formattedTransactionDate = '';
                                $A.localizationService.UTCToWallTime(new Date(transactionDateTimeUTC), timezone, function(walltime) {
                                    var dd = walltime.getDate();
                                    var MM = walltime.getMonth()+1;
                                    var yyyy = walltime.getFullYear();
                                    if(dd<10){
                                        dd='0'+dd;
                                    } 
                                    if(MM<10){
                                        MM='0'+MM;
                                    } 
                                    formattedTransactionDate = yyyy+'-'+MM+'-'+dd;
                                })
                            if(dateRangesForProv.has(formattedTransactionDate) && formattedTransactionDate >= nineDaysAgo && formattedTransactionDate <= oneDayAgo){
                                dateRangesForProv.set(formattedTransactionDate,"true");
                            }
                        }
                    }
                    var errorMessageDates = '';
                    for (const [key, value] of dateRangesForProv.entries()) { 
                        if (value === 'true') {
                            var dd = key.substring(8,10);
                            if(dd.substring(0,1) == '0'){
                                dd = dd.substring(1,2);
                            }
                            var mm = key.substring(5,7);
                            if(mm.substring(0,1) == '0'){
                                mm = mm.substring(1,2);
                            }
                            var yyyy = key.substring(0,4);
                            var formattedDate = mm + '/' + dd + '/' + yyyy;
                            errorMessageDates += formattedDate + ', ';
                        }
                    } 
                    if(errorMessageDates.length > 0){
                        var createError = 'The system has found attendance for care date(s) ' + errorMessageDates.substring(0, errorMessageDates.length-2) + ' and attendance will be removed with the closure. Would you like to continue with closure?';
                        component.set("v.messageText", createError);
                        helper.callModal(component,"attendanceFoundWarningMsgModal");                        
                    }
                    else{
                        anyInvalid=true;
                    }
                }else if(result.errorMessage == 'No Records Found.'){
                    anyInvalid=true;
                }

                this.checkforSave(component,helper,anyInvalid);
            });
            $A.enqueueAction(action);
        }
        if(!waitforAttend)
            this.checkforSave(component,helper,anyInvalid);
    },
    checkforSave:function(component,helper,anyInvalid){
        if(anyInvalid==true){
            this.saveRecord(component,helper);
        }else{
            component.set("v.spinner", false);
        }   
    },
    saveRecord : function(component,helper){
        component.set("v.provClosure.proRecId",component.get("v.provdSFId"));
        component.set("v.provClosure.countyId",component.get("v.countySFId"));
        console.log(component.get("v.provClosure.proRecId"));
        //alert('All form entries look valid. Ready to submit!');
        var action = component.get("c.saveData");
        action.setParams({
            recordData : JSON.stringify(component.get("v.provClosure")),
            holidayList : component.get("v.countyHolidays")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            component.set("v.spinner", false);
            if (component.isValid() && state === "SUCCESS"){
                var result=response.getReturnValue();
                
                if(result.isSuccessful){
                    helper.toastMessage('Success','Provider Calendar Records updated successfully !');
                    helper.hideConfirmModal(component);
                    component.set("v.provClosure",undefined);
                    //window.location.reload(); commented for CCCAP-10618
                    var parentComponent = component.get("v.parent");
                    var isPast = component.get("v.hasPastDate");
                    parentComponent.updateCalendarFromChild(isPast);
                }
                else{ 
                    if(result.objectData.createError==false){
                        component.set("v.hasPastDate", false);
                        var createError = 'Error occurred while creating record. Contact your system administrator!';
                        component.set("v.messageText", createError);
                        helper.callModal(component,"warningModal");
                        component.set("v.provClosure",undefined);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    showConfirmModal: function(component){  
        $A.util.addClass(component.find('provClosModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('backDrop'), 'slds-backdrop--open');
    },
    hideConfirmModal: function(component){
        $A.util.removeClass(component.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(component.find('provClosModal'), 'slds-fade-in-open');        
    }
})