({
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    },
    
    doFinishHlp : function(component, event, helper) {
        try {
            component.set("v.showSpinner", true);
            var childCmp = component.find("setFutureParentFeePg2");
            childCmp.callValidateCurrentPage();
            var effAuthDate = helper.getDateInUTC(component.get("v.newCaseCopayRec").dte_begin_effv__c);
            var effAuthDateStr = effAuthDate.getFullYear()+'-'+(effAuthDate.getMonth()+1)+'-'+effAuthDate.getDate();
            if(component.get("v.isCurrentPageValid") == true){
                helper.callServerAndHandleError(component,"c.saveCaseCopayRecord", function(response){
                    if(!$A.util.isEmpty(response.objectData)){
                        if(!$A.util.isEmpty(response.objectData.caseCopayRecExtIdCreated)){
                            component.set("v.caseCopayRecExtIdCreated",response.objectData.caseCopayRecExtIdCreated);
                        }
                        if(!$A.util.isEmpty(response.objectData.xLog)){
                            helper.doDeleteParentFee(component, event, helper,response.objectData.xLog);
                        }
                        if(!$A.util.isEmpty(response.objectData) && !$A.util.isEmpty(response.objectData.title) && (!$A.util.isEmpty(response.objectData.isSuccessful))){
                            component.set("v.noDataReturnedFromServer",true);
                            component.set("v.title",response.objectData.title);
                            component.set("v.description",response.objectData.description);
                        } else {
                            helper.AuthParentFeeUpdate(component, event, helper);
                            component.set("v.isCaseCopayCreated", true); 
                        }
                    }
                },{'caseCopayRec' : component.get("v.caseCopayRec"),
                   'parentFee':(component.get("v.newCaseCopayRec").amt_copay_case_assesd__c).toString(),
                   'effectiveDate':component.get("v.newCaseCopayRec").dte_begin_effv__c,
                   'overrideReason':component.get("v.newCaseCopayRec").cde_reason_ovrd__c,
                   'isFirstCaseCopayRec':component.get("v.isFirstCaseCopayRec"),
                   'newCaseCopayRec' : component.get("v.newCaseCopayRec")},false, null);
            } else {
                component.set("v.disablecConfirmationModalYesButton", false);
                component.set("v.showSpinner", false);
            }
        } catch(ex) {
            component.set("v.disablecConfirmationModalYesButton", false);
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
        }
    },
    
    AuthParentFeeUpdate :function(component, event, helper) {
        try {
            var currentDate = this.getDateInUTC(new Date());
            var recordId = component.get("v.recordId");
            var newCaseCopayRec = component.get("v.newCaseCopayRec");
            var newEffectiveDate =newCaseCopayRec.dte_begin_effv__c;
            var isUpdate = false;
            var effectiveDate = this.getDateInUTC(newEffectiveDate);
            var effAuthDate = helper.getDateInUTC(component.get("v.newCaseCopayRec").dte_begin_effv__c);
            if((this.getDateInUTC(component.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() &&
               component.get("v.caseCopayRec").amt_copay_case_assesd__c != component.get("v.newCaseCopayRec").amt_copay_case_assesd__c){
                isUpdate=true; 
            }
            var childCmp = component.find("setFutureParentFeePg2");
            var effAuthDateStr = effAuthDate.getFullYear()+'-'+(effAuthDate.getMonth()+1)+'-'+effAuthDate.getDate();
            helper.callServerAndHandleError(component,"c.updateAuthCopay", function(response){
                if(!$A.util.isEmpty(response.objectData)){
                    if(!$A.util.isEmpty(response.objectData.xLog)){
                        helper.doDeleteParentFee(component, event, helper,response.objectData.xLog);
                    }
                    if(!$A.util.isEmpty(response.objectData) && !$A.util.isEmpty(response.objectData.title) && (!$A.util.isEmpty(response.objectData.isSuccessful))){
                        component.set("v.noDataReturnedFromServer",true);
                        component.set("v.title",response.objectData.title);
                        component.set("v.description",response.objectData.description);
                    }else{
                        if($A.util.isEmpty(component.get("v.caseCopayRec").dte_end_effv__c)){
                            if((this.getDateInUTC(component.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() ){
                                isUpdate=true; 
                                console.log('success redirect');
                                helper.goToRecord(component.get("v.recordId"),'detail');
                                helper.fireToast("dismissible","success","","Case and Authorization Parent Fee records have been created sucessfully.");
                            }else{
                                helper.AuthParentFeeCreation(component, event, helper);
                            }
                        }else if(!$A.util.isEmpty(component.get("v.caseCopayRec").dte_end_effv__c) && (this.getDateInUTC(component.get("v.caseCopayRec").dte_end_effv__c)) <=currentDate){
                            debugger;
                            console.log('inside creation of auth parent fee');
                                helper.AuthParentFeeCreation(component, event, helper);
                        }
                        console.log('success redirect');
                    }
                }
            },{
                'authCopayWrapStr' : JSON.stringify(childCmp.get('v.authCopayWrapList')),
                'effDtStr':effAuthDateStr,
                'isUpdate':isUpdate
            }, false, null);
        } catch(ex) {
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
        }
    },
    
    AuthParentFeeCreation :function(component, event, helper) {
        try {
            var recordId = component.get("v.recordId");
            var effAuthDate = helper.getDateInUTC(component.get("v.newCaseCopayRec").dte_begin_effv__c);
            var childCmp = component.find("setFutureParentFeePg2");
            console.log('effAuthDate---'+effAuthDate);
            var effAuthDateStr = effAuthDate.getFullYear()+'-'+(effAuthDate.getMonth()+1)+'-'+effAuthDate.getDate();
            console.log('effAuthDate 1---'+JSON.stringify(effAuthDateStr));
            console.log("Validations got passed");
            helper.callServerAndHandleError(component,"c.saveAuthCopay", function(response){
                console.log('response after assess parent fee save: '+JSON.stringify(response));
                if(!$A.util.isEmpty(response.objectData)){
                    if(!$A.util.isEmpty(response.objectData.xLog)){
                        helper.doDeleteParentFee(component, event, helper,response.objectData.xLog);
                    }
                    if(!$A.util.isEmpty(response.objectData) && !$A.util.isEmpty(response.objectData.title) && (!$A.util.isEmpty(response.objectData.isSuccessful))){
                        component.set("v.noDataReturnedFromServer",true);
                        component.set("v.title",response.objectData.title);
                        component.set("v.description",response.objectData.description);
                    } else {
                        console.log('success redirect');
                        helper.goToRecord(component.get("v.recordId"),'detail');
                        helper.fireToast("dismissible","success","","Case and Authorization Parent Fee records have been created sucessfully.");
                    }
                }
            },{
                'authCopayWrapStr' : JSON.stringify(childCmp.get('v.authCopayWrapList')),
                'effDtStr':effAuthDateStr
            }, false, null);
        } catch(ex) {
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
        }
    },
    
    doDeleteParentFee : function(component, event, helper,expLog) {
        try {
            console.log(component.get("v.caseCopayRecExtIdCreated"));
            if(!$A.util.isEmpty(component.get("v.caseCopayRecExtIdCreated"))){
                helper.callServerAndHandleError(component,"c.deleteParentFeeData", 
                                                function(response){
                                                    if(!$A.util.isEmpty(expLog)){
                                                        helper.callServer(component,"c.logException", 
                                                                          function(response){
                                                                              console.log("Exception occurred on server and has been logged.");
                                                                          }, {"xLog":expLog}, false);
                                                    }
                                                    if(!$A.util.isEmpty(response.objectData)){
                                                        if(!$A.util.isEmpty(response.objectData.xLog)){
                                                            helper.callServer(component,"c.logException", 
                                                                              function(response){
                                                                                  console.log("Exception occurred on server and has been logged.");
                                                                              }, {"xLog":response.objectData.xLog}, false);
                                                        }
                                                        if(!$A.util.isEmpty(response.objectData.title)){
                                                            component.set("v.noDataReturnedFromServer",true);
                                                            component.set("v.title",response.objectData.title);
                                                            component.set("v.description",response.objectData.description);
                                                        }
                                                    } else {
                                                        component.set("v.caseCopayRecExtIdCreated",'');
                                                        // helper.goToRecord(component.get("v.recordId"),'detail');
                                                        // helper.fireToast("dismissible","success","","Case Parent Fee data has been deleted.");
                                                    }
                                                },{"caseCopayExternalId":JSON.stringify(component.get("v.caseCopayRecExtIdCreated"))}, false, null);
            }
        } catch(ex) {
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
        }
    },
    
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    doValidateParentFeeChange :  function(component, event, helper) {
        component.set("v.showSpinner", true);
        var childCmp = component.find("setFutureParentFeePg2");
        childCmp.callValidateCurrentPage();
        var effAuthDate = helper.getDateInUTC(component.get("v.newCaseCopayRec").dte_begin_effv__c);
        var effAuthDateStr = effAuthDate.getFullYear()+'-'+(effAuthDate.getMonth()+1)+'-'+effAuthDate.getDate();
        if(component.get("v.isCurrentPageValid")==true){
            // CCCAP-4767 Changes
            // if((this.getDateInUTC(component.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() &&
            // component.get("v.caseCopayRec").amt_copay_case_assesd__c != component.get("v.newCaseCopayRec").amt_copay_case_assesd__c){
            // Check for auth copay allocation change if any to show warning message
            var authCopayWrapListCopy = component.get("v.authCopayWrapListCopy");
            var authCopayWrapList = childCmp.get('v.authCopayWrapList');
            var authCopayWrapCopyMap = authCopayWrapListCopy.reduce(function(map, obj) {
                map[obj.authName] = obj.allocatedAuthAmount;
                return map;
            }, {});
            var isUpdate = false;
            if(!$A.util.isEmpty(authCopayWrapList)){
                for(var i=0;i<authCopayWrapList.length;i++){
                    if(authCopayWrapCopyMap[authCopayWrapList[i].authName] != authCopayWrapList[i].allocatedAuthAmount){
                        isUpdate = true;
                        // helper.callModal(component,'confirmationModalOnParentFeeChange');
                    }
                }
                if(isUpdate){
                    helper.callModal(component,'confirmationModalOnParentFeeChange');
                } else {
                    var amount = component.get("v.newCaseCopayRec").amt_copay_case_assesd__c;
                    //var msg ='The parent fee allocated to child '+amount+' exceeds the cost of care. Please contact the caretaker to determine if it is most beneficial to close their CCCAP case.'
                    var msg ='The assessed Parent Fee exceeds the cost of care. Please contact the adult caretaker/teen parent to provide case management and discuss their options.'
                    component.set("v.parentFeeExceedPrvPayMsg",msg);
                    if(component.get("v.showPrivatePayAmtMsg")){
                        helper.callModal(component,'confirmationModalOnParentFeeExceedPrvPay');
                    } else {
                        helper.doFinishHlp(component, event, helper); 
                    }
                }
            }else {
            component.set("v.showSpinner", false);
        }
        } else {
            component.set("v.showSpinner", false);
        }
    },
})