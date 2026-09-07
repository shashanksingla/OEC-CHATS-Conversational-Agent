({
	callModal: function (cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    toastMessage: function (state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
    },
    saveUpdates :  function(component,event,helper){    
        var modalCall = component.find('provCal');
        modalCall.checkForUpdate();
        var isAnyUncheck=false;
        var hasPastDate = false;
        var today=$A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        if(component.get("v.ifError")=='noupdate'){  
             helper.toastMessage('Error','You must edit at least one day to save changes to the schedule');
            // 'Dismissible', 'Error', 'Error!', 'You must edit at least one day to save changes to the schedule'
            component.set("v.spinner", false);
        }
        else{
            console.log('newList => '+JSON.stringify(component.get("v.updatedList")));
            component.get("v.updatedList").forEach(function(element){  
                if(element.checked==false && !$A.util.isEmpty(element.comment)){
                    isAnyUncheck=true;
                }
                if($A.localizationService.formatDate(element.newbeginDate, "YYYY-MM-DD") < today){ 
                    hasPastDate = true;
                    component.set("v.hasPastDate", true);
                }
            });  
            if(isAnyUncheck==true && component.get("v.oncChecked")==false){
                var createError = 'There are date(s) with comment but not checked as closed. CHATS will not consider these dates as closures.';
                component.set("v.messageText", createError);
                helper.callModal(component,"warningMsgModal");
                component.set("v.spinner", false);
            }
            else if(hasPastDate && component.get("v.attendanceChecked")==false){ //added as part of CCCAP-10618
                var provId = component.get("v.provdId");
                var oneDayAgo=$A.localizationService.formatDate(new Date((new Date()).valueOf() - 1000*60*60*24*1), "YYYY-MM-DD");
                var nineDaysAgo = $A.localizationService.formatDate(new Date((new Date()).valueOf() - 1000*60*60*24*9), "YYYY-MM-DD");

                const checkedDates = new Map();
                component.get("v.updatedList").forEach(function(element){  
                    if(element.checked==true){
                        checkedDates.set($A.localizationService.formatDate(element.newbeginDate, "YYYY-MM-DD"),"false");
                    }
                });
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
                                if(checkedDates.has(formattedTransactionDate) && formattedTransactionDate >= nineDaysAgo && formattedTransactionDate <= oneDayAgo){
                                    checkedDates.set(formattedTransactionDate,"true");
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
                                if(checkedDates.has(formattedTransactionDate) && formattedTransactionDate >= nineDaysAgo && formattedTransactionDate <= oneDayAgo){
                                    checkedDates.set(formattedTransactionDate,"true");
                                }
                            }
                        }
                        var errorMessageDates = '';
                        for (const [key, value] of checkedDates.entries()) { 
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
                            component.set("v.attendanceChecked", true);
                            helper.saveUpdates(component,event,helper);
                        }
                    }                    
                    else if(result.errorMessage == 'No Records Found.'){
                        component.set("v.attendanceChecked", true);
                        helper.saveUpdates(component,event,helper);
                    }
                    component.set("v.spinner", false);
                });
                $A.enqueueAction(action);
            }
            else if(component.get("v.ifError") == 'false'){
                helper.toastMessage('Error','Please complete error messages on the page.');
                component.set("v.spinner", false);
            }
                else{
                var action = component.get("c.updateData");
                action.setParams({
                    recordData : JSON.stringify(component.get("v.updatedList")),
                    provId : component.get("v.provdSFId"),
                    countyId : component.get("v.countySFId"),
                    faId : component.get("v.recordId")
                });
                action.setCallback(this, function(response){
                    var state = response.getState();
                    var modalCall = component.find('provCal');
                    modalCall.updateStatus();
            
                    if (component.isValid() && state === "SUCCESS"){
                        var result=response.getReturnValue();                
                        if(result.isSuccessful){
                            helper.toastMessage('Success','Provider Calendar Records updated successfully !');
                            component.set("v.updatedList",[]);
                            component.set("v.changedList",[])
                            //  helper.hideConfirmModal(component);
                            component.set("v.provClosure",[]);
                            component.set("v.provClosList",result.objectData.updatedProv);
                            component.set("v.attendanceChecked", false);
                        }else{ 
                            if(result.objectData.createError==false){
                                var createError = 'Error occurred while creating record. Contact your system administrator!';
                                component.set("v.messageText", createError);
                                helper.callModal(component,"warningModal");
                                component.set("v.provClosure",[]);
                            }
                        }
                    }
                    component.set("v.spinner", false);
                });
                $A.enqueueAction(action);
            }
        }
	}
})