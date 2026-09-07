({
     rateTypeChange : function(component, event, helper){
        var newR=component.get("v.slotContract.rtypeVal");
        var clValues=component.get("v.clevelOrg");
        var newClSet=[];
        if(newR==13 || newR==19 || newR==25)
        {
            clValues.filter(function (el) {
                
                if(el.value == 8)
                { 
                    newClSet.push({
                        label:el.label,
                        value:el.value
                    });
                }
              //  return newClSet ;
            });
            component.set("v.clevelOpt", newClSet);
        }else{
            component.set("v.clevelOpt",clValues);
            //   component.set("v.clevelOrg", clValues);
        }
    },
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
        
        var today=component.get("v.today");
        var obegin=component.get("v.slotContractClone.beginDate");
        var newVal=component.get("v.slotContract.beginDate");
        var bginMin=component.get("v.beginDateMin");
        var orgEnd=component.get("v.slotContract.endDate");
        
        var inputCmp = component.find('fieldBegin');
        if(obegin == newVal)
        {
            if(obegin < bginMin)
            {
                anyInvalid=false;
                var authError = 'Record cannot be updated , Slot Contract Begin Date is not greater than today - 9 days.';
                component.set("v.messageText", authError);
                helper.callModal(component,"warningModal");                
            }
        }
        else{
            if(newVal < obegin)
            {
                inputCmp.setCustomValidity("Slot Contract Begin Date cannot be earlier than the original Begin Date on Slot Contract record.");
                anyInvalid=false;
            }else if(newVal < bginMin)
            {
                inputCmp.setCustomValidity("Slot Contract Begin Date cannot be prior to {today - 9 days in the past}.");
                anyInvalid=false;  
            }else if(newVal>orgEnd)
            {
                inputCmp.setCustomValidity("Slot Contract Begin Date should be earlier than Slot Contract End Date.");
                anyInvalid=false;
            }else{
                inputCmp.setCustomValidity("");
            }
            inputCmp.reportValidity(); 
        }    
        var exAuth =component.get("v.slotContract.authVal");
        var beAuth = component.get("v.slotContractClone.authVal");
        var inbegin=false;
        if(newVal >=bginMin  && newVal <= today)
        {
            inbegin=true;
    
        }
        /*if(exAuth != beAuth && obegin == newVal)
        {
           if(!inbegin)
           {
           var countyError = 'Record cannot be updated , You need to change the Slot Contract Begin Date as you are changing Authorization ID.';
           component.set("v.messageText", countyError);
            helper.callModal(component,"warningModal");
            anyInvalid=false;  
           }
        }*/
            
        
        var anyOris = this.checkforAnyOrAllChange(component,helper);
       //  var beAuth = component.get("v.slotContractClone.authVal");
        var occCheck=false;
        if(anyOris == true && $A.util.isUndefinedOrNull(beAuth))
        {
            
            var countyError = 'You have only edited the begin date on this Slot Contract record. Please make changes to either authorization or slot contract record details to save the edits.';
            component.set("v.messageText", countyError);
            helper.callModal(component,"warningModal");
            anyInvalid=false;        
        }else if(anyOris == true && !$A.util.isUndefinedOrNull(beAuth))
        {
            occCheck=true;
        }
        
        if(anyInvalid==true && allValid==true)
        {
            this.updateData(component,helper,occCheck);
        }else{
               component.set("v.spinner", false);
        }
    },
    checkforAnyOrAllChange : function(component,helper)
    {
        var anyVal;
        
        if(component.get("v.slotContract.clevelVal") == component.get("v.slotContractClone.clevelVal") &&
           component.get("v.slotContract.cunitVal") == component.get("v.slotContractClone.cunitVal") &&
           component.get("v.slotContract.rtypeVal") == component.get("v.slotContractClone.rtypeVal") &&
           component.get("v.slotContract.progTyp") == component.get("v.slotContractClone.progTyp") )
        {
            var daysCheck;
            var orgDays=  component.get("v.slotContract.noDays");
            var newDays=component.get("v.slotContractClone.noDays") ;
            
            if(orgDays==newDays)
            {
                daysCheck=true;
                
            }else{
                daysCheck=false;
                
            }
            var cnt=0, newcnt=0;
            for(var m = 0; m < component.get("v.weekValue").length; m++)
            {
                cnt++;
            }
            for(var m = 0; m < component.get("v.orgWeek").length; m++)
            {
                newcnt++;
            }
            var authCheck=false;
            var val =component.get("v.slotContract.authVal");
            var beAuth = component.get("v.slotContractClone.authVal");
            
            if(val!=beAuth)
            {
                authCheck = false;
            }
            else{
                authCheck = true;
            }
            if(cnt == newcnt && authCheck ==true && daysCheck ==true)
            {
                if(component.get("v.slotContractClone.beginDate") != component.get("v.slotContract.beginDate") )
                {
                    anyVal = true; 
                }else{ 
                    anyVal=false;
                }
            }
            else{ 
                anyVal=false;
            }
            
        }
        return   anyVal;      
    },
    getRateType : function(component,helper){
         component.set("v.slotContract.rtypeVal",undefined);
         component.set("v.slotContract.clevelVal", undefined);
        component.set("v.orgCounty",component.get("v.slotContract.countyVal"));
        component.set("v.slotContract.countyVal",component.get("v.slotContractClone.countyVal"));
        if(component.get("v.beginTrue") == true)
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
        component.set("v.slotContract.countyVal",component.get("v.orgCounty"));
    },
    updateData : function(component,helper,occCheck)
    {
        var org = component.get("v.slotContractClone.progTyp");
        var news = component.get("v.slotContract.progTyp");
        var chng=component.get("v.checkChangeProg");
        var chngauth=component.get("v.checkChangeAuth");
        var val=component.get("v.slotContract.authVal");
        var beAuth=component.get("v.slotContractClone.authVal");
        if(component.get("v.firstdone")=='false')
        {
            component.set("v.firstdone",'true');
        }
        if(chng=='true')
        {
            if(org!=news)
            {
                var authError = 'Program Type on this Slot Contract record is being changed. Do you want to proceed further with changes?';
                component.set("v.messageText", authError);           
                helper.callModal(component,"warningMsgModal");
                component.set("v.tmpcheckChangeProg", 'false');
                component.set("v.firstdone",'false');
            }
            else{
                component.set("v.checkChangeProg",'false');
            }
            
        }
        if(chngauth =='true' &&  component.get("v.firstdone")=='true')
        {
            
            if((val==null || val=='') && (!$A.util.isUndefinedOrNull(beAuth)))
            {
                var authError = 'Slot Contract association on the authorization is being removed. Do you want to proceed further with changes?';
                component.set("v.messageText", authError);
                helper.callModal(component,"warningMsgModal",'checkChangeAuth');
                component.set("v.tmpcheckChangeAuth", 'false');
            }
            else if(val!=beAuth && (!$A.util.isUndefinedOrNull(beAuth)))
            {
                var authError = 'Authorization ID on this Slot Contract record is being changed. Do you want to proceed further with changes?';
                component.set("v.messageText", authError);
                helper.callModal(component,"warningMsgModal",'checkChangeAuth');
                component.set("v.tmpcheckChangeAuth", 'false');
            }else{
                component.set("v.checkChangeAuth",'false');
            }
        }
        
        if(component.get("v.checkChangeProg") == 'false' &&  component.get("v.checkChangeAuth") == 'false'){
            component.set("v.slotContract.weekData",component.get("v.weekValue"));
             component.set("v.slotContract.countyVal",component.get("v.slotContractClone.countyVal"));
            //alert('All form entries look valid. Ready to submit!');
            if(component.get("v.slotContract.noDays")== null || component.get("v.slotContract.noDays") == '')
            {
                component.set("v.slotContract.noDays",undefined);;
            }
            
            var action = component.get("c.updateData");
            action.setParams({
                recordData : JSON.stringify(component.get("v.slotContract ")),
                recordid : component.get("v.recordId"),
                occCheck : occCheck
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var result=response.getReturnValue();
                    if(result.isSuccessful)
                    {
                        helper.toastMessage('Success','Slot Contract record Updated Successfully!!');
                        var recordId = component.get("v.recordId");
                        helper.goToRecord(recordId,'detail');
                    }
                    else
                    {
                        if(result.objectData.updateError==false)
                        {
                            var updateError = 'Error occurred while updating record. Contact your system administrator!';
                            component.set("v.messageText", updateError);
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
            component.set("v.slotContract.countyVal",component.get("v.orgCounty"));
        }
    }
})