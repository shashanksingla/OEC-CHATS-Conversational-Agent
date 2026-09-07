({
    doInit : function(component, event, helper) {
        var countyRatePlanRecord= component.get("v.countyRatePlanRec");
        if(component.get("v.countyId")!=null){
            
            //CHAT-2131 : validating to check if there exists unapproved county plan for the county.
            helper.validateCountyForNewRatePlan(component, helper);
            countyRatePlanRecord.IDN_COUNTY__c = component.get("v.countyId").substring(0,15);
            component.set("v.countyRatePlanRec", countyRatePlanRecord);

            component.set("v.isNew",true);
            
            var action = component.get("c.ownerCountyValidation");
            action.setParams({"recordId":component.get("v.countyId"), "isCounty": true
                             });
            action.setCallback(this, function(response) {
                var returnValue = response.getReturnValue();
                if(returnValue.countyMatched == false && component.get("v.currentTabNumber") == 1){
                    var recordError = 'The county rate plan record that you are trying to access belongs to '+returnValue.countyName+' county. This does not match your assigned county(ies).';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    helper.callModal(component,"warningModalOnDiffOwnerCounty");
                }   
            });
            $A.enqueueAction(action);
        }
        else if (component.get("v.recordId")!=null){
            var action = component.get("c.ownerCountyValidation");
            action.setParams({"recordId":component.get("v.recordId"), "isCounty": false
                             });
            action.setCallback(this, function(response) {
                var returnValue = response.getReturnValue();
                if(returnValue.countyMatched == false){
                    var recordError = 'The county rate plan record that you are trying to access belongs to '+returnValue.countyName+' county. This does not match your assigned county(ies).';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    helper.callModal(component,"warningModalOnDiffOwnerCounty");
                }else{
                    component.set('v.isFeedbackVisible',returnValue.isFeedbackVisible);                    
                }
            });
            $A.enqueueAction(action);
            countyRatePlanRecord.Id = component.get("v.recordId").substring(0,15);
            component.set("v.countyRatePlanRec", countyRatePlanRecord);    
            helper.getCountyRatePlanRecord(component, helper);
        }
       
    },
    confirmCancel : function(component, event, helper) {
        var recordId;
        if(component.get("v.countyId")!=null){
            recordId = component.get("v.countyId");
        }
        else if(component.get("v.recordId")!=null){
            recordId = component.get("v.recordId");
        }
        
        if(!$A.util.isUndefinedOrNull(component.get("v.countyRatePlanRec").Id)){
            helper.redirectToRecord(component.get("v.countyRatePlanRec").Id);
        }
        else{
            helper.redirectToRecord(recordId);
        }
    },
    saveAsDraft : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.upsertRecords",
            function(response){
                if(response.isSuccessful){
                    component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                    helper.redirectToRecord(component.get("v.countyRatePlanRec").Id);
                }
            }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);
    },
    closeModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnDiffOwnerCounty");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
    },
    closeHolidayWarningModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnHolidayDiff");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
    },
    confirmHolidayWarning : function(component, event, helper){
        var modalCall = component.find("warningModalOnHolidayDiff");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
        var countyRatePlanRec = component.get("v.countyRatePlanRec");
        if(!$A.util.isEmpty(countyRatePlanRec) && !$A.util.isEmpty((countyRatePlanRec).PAYMENT_Q14__c ) ){
            if(countyRatePlanRec.PAYMENT_Q14__c == 'N'){
                countyRatePlanRec.PAYMENT_Q14_3__c ='';
                countyRatePlanRec.PAYMENT_Q14_2__c ='';
                countyRatePlanRec.PAYMENT_Q14_1__c ='';
                component.set('v.countyRatePlanRec',countyRatePlanRec);
            } 
            helper.callServerAndHandleError(component,"c.upsertRecords", 
                                            function(response){
                                                if(component.get("v.isCurrentPageValid")==true){
                                                    component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));   
                                                    var crp = component.get("v.countyRatePlanRec");
            										component.set("v.crpHolidays", crp.PAYMENT_Q13_1__c);                                            
                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                }
                                            }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);                    
        }
    },
    doChangeCurrentTab : function(component, event, helper) {
        component.set("v.pageMessages",[]);
        component.set("v.messageType",null);
    },
    doNext : function(component, event, helper) {
        window.scroll(0, 0);
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            // handling client side validations
            var childCmp = component.find("countyRatePlanFlowScreen1_CountyRatePlanInfo");
            childCmp.callValidateCurrentPage();
          
            if(component.get("v.isCurrentPageValid")){
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                                                        
                                                        var originalTemplate= component.get("v.originalTemplate");
                                                        var currentTemplate= component.get("v.countyRatePlanRec").CDE_RATE_PLAN_TEMPLT__c;
                                                        if(component.get("v.countyId")!=null){  //&& component.get("v.countyRatePlanRec").CDE_RATE_PLAN_TEMPLT__c != '5'
                                                            helper.getCountyRatePlanRecordForTemplate(component, helper);
                                                        }
                                                        else if (component.get("v.recordId")!=null && originalTemplate != currentTemplate){
                                                            component.set("v.originalTemplate", currentTemplate);
                                                            helper.getCountyRatePlanRecordForTemplate(component, helper);
                                                        }
                                                        else{
                                                            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                        }
                                                    }
                                                }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);
                
            }
            var crp = component.get("v.countyRatePlanRec");
            component.set("v.crpHolidays", crp.PAYMENT_Q13_1__c);
        }
        else if(currentTabNumber==2){
            var childCmp = component.find("countyRatePlanFlowScreen2_Payment");
            childCmp.callValidateCurrentPage();
           
            // server side call
            if(component.get("v.isCurrentPageValid")){
                var countyRatePlanRec = component.get("v.countyRatePlanRec");
                var existingHolidays = component.get("v.crpHolidays");
                if(!$A.util.isEmpty(existingHolidays)){
                    existingHolidays = existingHolidays.trim().concat(';');
                } else {
                    existingHolidays = '';
                }
                var newHolidays = countyRatePlanRec.PAYMENT_Q13_1__c || '';
                console.log('existingHolidays-->' + existingHolidays);
                console.log('newHolidays-->' + newHolidays);
                // Modified below 'removed' & 'added' logic by Rishav for CCCAP-8157
                /* for(var i=1;i<=10;i++){
                    if(existingHolidays.indexOf(i+';') == -1 && newHolidays.indexOf(i+';') != -1){
                        added = true;
                    }
                    if(existingHolidays.indexOf(i+';') != -1 && newHolidays.indexOf(i+';') == -1){
                        removed = true;
                    }
                } */
                var oldHolidayList = existingHolidays.split(";").filter(Boolean);
                var newHolidayList = newHolidays.split(";").filter(Boolean);
                var removed = oldHolidayList.some(holiday => !newHolidayList.includes(holiday));
                var added = newHolidayList.some(holiday => !oldHolidayList.includes(holiday));
                var recordError = '';
                if(added == true){
                    recordError += 'Adding a holiday will revert changes on any already marked “Care Not Offered” dates on Provider Calendar.\n\n';
                }
                if(removed == true){
                    recordError += 'Removing a holiday might have an impact on providers and counties may have to enter provider closure records where necessary. A task will be generated and assigned to FA owners for the same.';
                }
                if(added == true || removed == true){
                    component.set("v.msgOnHolidayDiff", recordError);
                    helper.callModal(component,"warningModalOnHolidayDiff");
                }else if(!$A.util.isEmpty(countyRatePlanRec) && !$A.util.isEmpty((countyRatePlanRec).PAYMENT_Q14__c ) ){
                    if(countyRatePlanRec.PAYMENT_Q14__c == 'N'){
                        countyRatePlanRec.PAYMENT_Q14_3__c ='';
                        countyRatePlanRec.PAYMENT_Q14_2__c ='';
                        countyRatePlanRec.PAYMENT_Q14_1__c ='';
                        component.set('v.countyRatePlanRec',countyRatePlanRec);
                    } 
                    helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                                                       
                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    }
                                                }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);                    
                }
            }
        }
        else if(currentTabNumber==3){
            /*var childCmp = component.find("countyRatePlanFlowScreen3_ROO");
                childCmp.callValidateCurrentPage();
               
                if(component.get("v.isCurrentPageValid")){
                    helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                    function(response){
                                                        if(component.get("v.isCurrentPageValid")==true){
                                                            component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                                                            
                                                            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                        }
                                                    }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);
                    
                }*/
        }else if(currentTabNumber==4){
            /*var childCmp = component.find("countyRatePlanFlowScreen4_CFS");
                    childCmp.callValidateCurrentPage();
                    
                    if(component.get("v.isCurrentPageValid")){
                        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                        function(response){
                                                            if(component.get("v.isCurrentPageValid")==true){
                                                                component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                                                              
                                                                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                var isNew= component.get("v.isNew");
                                                                if(isNew){
                                                                    var countyRatePlan = component.get("v.countyRatePlanRec");
                                                                    countyRatePlan.RATE_TYPE__c = component.get("v.templateRateType");
                                                                    component.set("v.countyRatePlanRec",countyRatePlan );
                                                                }
                                                            }
                                                        }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);
                        
                    }*/
        }else if(currentTabNumber==5){
                
        }
    },
    doPrevious : function(component, event, helper) {
        var currentTabNumber= component.get("v.currentTabNumber");
        
        component.set("v.currentTabNumber",currentTabNumber-1);
    },
    doFinish : function(component, event, helper) {
        var childCmp = component.find("countyRatePlanFlowScreen3_ROO");
        childCmp.callValidateCurrentPage();
        
        // server side call
        var countyRatePlanRecord = helper.getUpdatedRatePlanRecord(component);
        var recordId = countyRatePlanRecord.Id;
        if(component.get("v.isCurrentPageValid")){
            countyRatePlanRecord.Flow_Completed__c= true;
        	helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                if(component.get("v.isCurrentPageValid")==true){
                                                    component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                                                    helper.redirectToLightningComponent("c:countyRateAmountFlow", {"recordId": recordId,"showCustomButton2":(component.get('v.isFeedbackVisible'))});
                                                }
                                            }, {'lstSObject':[countyRatePlanRecord], isFinalStep:"true"}, false, null);
            
        }
        
    },
    toggleFeedback: function(component,event,helper){
        component.set('v.showFeedback',!component.get('v.showFeedback'));
    }
})