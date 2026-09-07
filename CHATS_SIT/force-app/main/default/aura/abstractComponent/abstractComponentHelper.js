({
    doContinuousCallOuts : function(cmp, methodName, params, callback){
        cmp.set("v.showSpinner", true);
        cmp.find("proxy").invoke(methodName, params, function(response) {
            cmp.set("v.showSpinner", false);
            
            if(!$A.util.isEmpty(response)){
                if(response.isSuccessful==true){
                    callback.call(this,response);
                }else{
                    var pageMessages = [response.errorMessage];
                    cmp.set("v.pageMessages",pageMessages);
                    cmp.set("v.messageType","error");
                }
            }else{
                cmp.set("v.pageMessages",[$A.get("$Label.c.NO_SERVER_RESPONSE")]);
            }
        });
    },
    
    callServerAndHandleError : function(cmp, method, callback, params, cacheable, successMessage) {
        
        cmp.set("v.pageMessages",[]);
        cmp.set("v.fieldValidationErrors",[]);
        cmp.set("v.messageType",null);
        
        this.callServer(cmp, method, function(response){
            // pass returned value to callback function
            if(response.isSuccessful==true){
                
                callback.call(this,response);
                if(successMessage && successMessage!=null){
                    cmp.set("v.pageMessages",[successMessage]);
                    cmp.set("v.messageType","success");
                }
            }else{
                var pageMessages = [response.errorMessage];
                var messageType = response.messageType || 'error';
                var lstAPXFieldValidationError = response.lstAPXFieldValidationError;
                if(lstAPXFieldValidationError){
                    var lstOnlyAPXFieldValidationError = [];
                    for(var i=0;i<lstAPXFieldValidationError.length;i++){
                        if(lstAPXFieldValidationError[i].isTopOfPageError==true){
                            pageMessages.push(lstAPXFieldValidationError[i].errorMessage);
                        }else{
                            lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                        }
                    }
                    cmp.set("v.fieldValidationErrors",lstOnlyAPXFieldValidationError);
                }
                var missingPageMessages = [];
                if(response.objectData != undefined){
                    var dmlErrMessages = response.objectData.dmlErrorMessages;
                    if(dmlErrMessages && dmlErrMessages.length > 0){
                        for(var i=0;i<dmlErrMessages.length;i++){
                            missingPageMessages.push(dmlErrMessages[i]);
                        }
                    }
                }
                cmp.set("v.missingPageMessages",missingPageMessages);
                cmp.set("v.pageMessages",pageMessages);
                cmp.set("v.messageType",messageType);
            }
        }, params, cacheable);
    },
    
    callServerAndDeleteRecordsByIds : function(cmp, callback, recordIdsToBeDeleted) {
        
        this.callServerAndHandleError(cmp,"c.deleteJunkRecordsByIds", 
                                      function(response){
                                          callback.call(this,response);
                                      }, {'idsToBeDeleted':recordIdsToBeDeleted}, false, null);
    },
    
    callServerAndDeleteRecords : function(cmp, callback, recordsToBeDeleted) {
        
        var onlyRecordsToBeDeleted = [];
        recordsToBeDeleted.forEach(function(rec){
            if(rec.Id!=undefined && rec.Id!=null && rec.Id!=''){
                onlyRecordsToBeDeleted.push(rec);
            }
        });
        this.callServerAndHandleError(cmp,"c.deleteJunkRecords", 
                                      function(response){
                                          callback.call(this,response);
                                      }, {'recordsToBeDeleted':onlyRecordsToBeDeleted}, false, null);
    },
    
    callServerForExternalObjAndHandleError : function(cmp, method, callback, params, cacheable, successMessage) {
        cmp.set("v.pageMessages",[]);
        cmp.set("v.fieldValidationErrors",[]);
        cmp.set("v.messageType",null);
        
        this.callServer(cmp, method, function(response){
            // pass returned value to callback function
            if(response.isSuccessful==true){
                callback.call(this,response);
                if(successMessage && successMessage!=null){
                    cmp.set("v.pageMessages",[successMessage]);
                    cmp.set("v.messageType","success");
                }
            }else{
                var pageMessages = [response.errorMessage];
                var lstAPXFieldValidationError = response.lstAPXFieldValidationError;
                if(lstAPXFieldValidationError){
                    var lstOnlyAPXFieldValidationError = [];
                    for(var i=0;i<lstAPXFieldValidationError.length;i++){
                        if(lstAPXFieldValidationError[i].isTopOfPageError==true){
                            pageMessages.push(lstAPXFieldValidationError[i].errorMessage);
                        }else{
                            lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                        }
                    }
                    cmp.set("v.fieldValidationErrors",lstOnlyAPXFieldValidationError);
                }
                cmp.set("v.pageMessages",pageMessages);
                cmp.set("v.messageType","error");
            }
        }, params, cacheable);
    },
    
    goToRecord: function(authId, slideDevName){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": authId,
            "slideDevName": slideDevName
        });
        navEvt.fire();
    },
    
    getCurrentSystemDate : function(addDays,addMonths,addYears){ 
        var today = new Date();
        var dd = addDays?today.getDate()+addDays:today.getDate();
        var MM = addMonths?today.getMonth()+1+addMonths:today.getMonth()+1;
        var yyyy = addYears?today.getFullYear()+addYears:today.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    },
    
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },

    /*
     Author: Rishav Maji
     Description: Generic method to be used for adding day/month/year/any combination to any input Date
     I/O: Input in YYYY-MM-DD format, ouput in localized date format when keepInputFormat is false otherwise YYYY-MM-DD format
   	*/
    genericDateUpdateLogic : function(inputDate, addDays, addMonths, addYears, keepInputFormat){ 
        var returnDate = null;
        if(inputDate){
            var inputDateSplitted = inputDate.split("-");
            var dateInstance = new Date(inputDateSplitted[0], inputDateSplitted[1]-1, inputDateSplitted[2]);
            if(addDays)
                dateInstance.setDate(dateInstance.getDate() + addDays);
            if(addMonths)
                dateInstance.setMonth(dateInstance.getMonth() + addMonths);
            if(addYears)
                dateInstance.setFullYear(dateInstance.getFullYear() + addYears);
            if(keepInputFormat){
                let DD = dateInstance.getDate();
                let MM = dateInstance.getMonth() + 1;
                let YYYY = dateInstance.getFullYear();
                if(DD<10)
                    DD='0'+DD;
                if(MM<10)
                    MM='0'+MM;
                returnDate = YYYY+'-'+MM+'-'+DD;
            } else {
                returnDate = $A.localizationService.formatDate(dateInstance);
            }
        }
        return returnDate;
    },
    
    /*
     Author: Rishav Maji
     Description: Generic method to show toast alert messeges as green Success, yellow Warning & red Error
     I/O: type = success / warning / error, messege = custom string
   	*/ 
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if(type == 'error'){
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": message
            });
        }
        if(type == 'success'){
            toastEvent.setParams({
                "title": "Success!",
                "type":'success',
                "message": message
            });
        }
        if(type == 'warning'){
            toastEvent.setParams({
                "title": "Warning!",
                "type":'warning',
                "message": message
            });
        }
        toastEvent.fire();
    }
})