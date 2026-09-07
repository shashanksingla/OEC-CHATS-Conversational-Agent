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
    checkValidity : function(component,helper)
    {
        var anyInvalid=true;
        var allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        var bginMin = component.get("v.beginDateMin");
        var newMax =component.get("v.endDateMax");
        var today=component.get("v.today");
        
        
        var inputCmp = component.find('fieldBegin');
        var value = component.get("v.slotContract.beginDate");
        
        
        if (value=='' || value == null || value ==undefined) {
            inputCmp.setCustomValidity("Complete this field.");
            anyInvalid=false;
        } else if(value < bginMin)
        {  
            inputCmp.setCustomValidity("Slot Contract Begin Date cannot be prior to {today - 9 days in the past}.");
            anyInvalid=false;
        }
            else{
                inputCmp.setCustomValidity("");
            }
        inputCmp.reportValidity(); 
        var inputCmp1 = component.find('fieldEnd');
        var value1 =component.get("v.slotContract.endDate");
        var tod=new Date(value1);
        
        if (value1=='' || value1 == null || value1 ==undefined) {
            inputCmp1.setCustomValidity("Complete this field.");
            anyInvalid=false;
        }else if(value1<today)
        {
            inputCmp1.setCustomValidity("Slot Contract End Date cannot be prior to today.");
            anyInvalid=false;
        }else if(value1<value)
        {
            inputCmp1.setCustomValidity("Slot Contract End Date should be greater or same as Slot Contract Begin Date.");
            anyInvalid=false;
        }else if(tod>newMax)
        {
            if(value=='' || value == null || value ==undefined)
            {
                inputCmp1.setCustomValidity("Difference between Today and Slot Contract End Date cannot be greater than 12 months.");
            }else{
                inputCmp1.setCustomValidity("Difference between Slot Contract Begin Date and Slot Contract End Date cannot be greater than 12 months.");
                
            } anyInvalid=false;
        }else {
            inputCmp1.setCustomValidity("");
        }
        
        /* else if(value1>newMax)
            {
                inputCmp1.setCustomValidity("Difference between Slot Contract Begin Date and Slot Contract End Date cannot be greater than 12 months.");
                anyInvalid=false;
            }else {
                inputCmp1.setCustomValidity("");
            }*/
        inputCmp1.reportValidity(); 
        
        if(anyInvalid==true && allValid==true)
        {
            this.saveRecord(component,helper);
        }else{
               component.set("v.spinner", false);
        }
    },
    getRateType : function(component,helper){
         component.set("v.slotContract.rtypeVal",undefined);
         component.set("v.slotContract.clevelVal", undefined);
        
        if( component.get("v.beginTrue") == true && component.get("v.countyTrue") == true )
        {           
            var action = component.get("c.getRateTypeByBegin");
            action.setParams({
                recordData : JSON.stringify(component.get("v.slotContract "))
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var result=response.getReturnValue();
                    if(result.isSuccessful)
                    {
                        
                        var rtyset = result.objectData.rtype;
                        var rtValues = [];
                        for(var key in rtyset){
                            rtValues.push({
                                label: key,
                                value: rtyset[key]
                            });
                        }
                        component.set("v.rtypeOpt", rtValues);
                        
                        console.log('rtValues '+JSON.stringify(rtValues));
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    saveRecord : function(component,helper)
    {
        component.set("v.slotContract.weekData",component.get("v.weekValue"));
        //alert('All form entries look valid. Ready to submit!');
        var action = component.get("c.saveData");
        action.setParams({
            recordData : JSON.stringify(component.get("v.slotContract "))
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS"){
                var result=response.getReturnValue();
                var sno;
                var sid;
                if(result.isSuccessful)
                {
                    sno=result.objectData.sno;
                    sid=result.objectData.sid
                    
                   // helper.toastMessage('Success','Slot Contract record '+sno+' created successfully !');
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                       type: 'success',
                        message: 'This is a required message',
                        messageTemplate: 'Slot Contract record {0} created successfully !',
                        messageTemplateData: [ {
                            label: sno,
                            url: '/'+sid
                        } ]
                    });
                    toastEvent.fire();
                    var recordId = component.get("v.recordId");
                    helper.goToRecord(recordId,'detail');
                }
                else
                {
                    
                    if(result.objectData.countyCheck==false) {
                        var countyError = 'Record creation failed. The County you selected does not match your assigned county.';
                        component.set("v.messageText", countyError);
                        helper.callModal(component,"warningModal");
                    }
                    else if(result.objectData.addendumcheck==false){
                        var addendumError = 'Record creation failed. Either you do not have an addendum with selected County and Provider or do not have addendum record with the selected begin date of slot contract.';
                        component.set("v.messageText", addendumError);
                        helper.callModal(component,"warningModal");
                    }
                        else if(result.objectData.addendumEndCheck==false)
                        {
                            var addendumEndError = 'Record creation failed. Slot Contract end date greater than Addendum end date.';
                            component.set("v.messageText", addendumEndError);
                            helper.callModal(component,"warningModal");
                        }else if(result.objectData.addendumCountCheck==false)
                        {
                            var addendumCountError = 'Record creation failed. Maximum number of slot contracts already created against the addendum.';
                            //helper.toastMessage('Error',addendumCountError);
                            component.set("v.messageText", addendumCountError);
                            helper.callModal(component,"warningModal");
                        }else if(result.objectData.createError==false)
                        {
                            var createError = 'Error occurred while creating record. Contact your system administrator!';
                            component.set("v.messageText", createError);
                            helper.callModal(component,"warningModal");
                        }else if(result.objectData.authDate==false)
                        {
                            var authError = 'Record creation failed. Authorization End Date is less than Slot Contract Begin Date';
                            component.set("v.messageText", authError);
                            helper.callModal(component,"warningModal");
                        }else if(result.objectData.authCounty==false)
                        {
                            var authError = 'Record creation failed. Slot Contract County does not match the Authorization County.';
                            component.set("v.messageText", authError);
                            helper.callModal(component,"warningModal");
                        }else if(result.objectData.slotBeFalse==false)
                        {
                            var authError = 'Record creation failed. Slot Contract End Date is prior to Authorization Begin Date.';
                            component.set("v.messageText", authError);
                            helper.callModal(component,"warningModal");  
                        }else if(result.objectData.authPrFalse==false)
                        {
                            var authError = 'Record creation failed. Slot Contract Provider does not match the Authorization Provider.';
                            component.set("v.messageText", authError);
                            helper.callModal(component,"warningModal");  
                        }else if(result.objectData.existSlot==false)
                        {
                            var authError = 'The Authorization ID is already associated with another Slot Contract record. Please use the edit Slot Contract functionality to change the associations.';
                            component.set("v.messageText", authError);
                            helper.callModal(component,"warningModal");  
                        }
                    
                }
            }
            
        });
        $A.enqueueAction(action);
    }
})