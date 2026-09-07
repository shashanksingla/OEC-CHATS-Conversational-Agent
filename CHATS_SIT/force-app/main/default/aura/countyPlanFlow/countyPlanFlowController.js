({
    doInit : function(component, event, helper) {
        var countyPlanRecord= component.get("v.countyPlanRec");
        if(component.get("v.countyId")!=null){
            //CHAT-2132 : validating to check if there exists unapproved county plan for the county.
            helper.validateCountyForNewCountyPlan(component, helper);
            
            countyPlanRecord.CDE_COUNTY__c=component.get("v.countyId").substring(0,15);
            component.set("v.countyPlanRec",countyPlanRecord);
            component.set("v.isNew",'true');
            var action = component.get("c.ownerCountyValidation");
            action.setParams({"recordId":component.get("v.countyId"), "isCounty": true
                             });
            action.setCallback(this, function(response) {
                var returnValue = response.getReturnValue();
                if(returnValue.countyMatched == false){
                    var recordError = 'The county plan record that you are trying to access belongs to '+returnValue.countyName+' county. This does not match your assigned county(ies).';
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
                    var recordError = 'The county plan record that you are trying to access belongs to '+returnValue.countyName+' county. This does not match your assigned county(ies).';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    helper.callModal(component,"warningModalOnDiffOwnerCounty");
                }else{
	                component.set('v.isFeedbackVisible',returnValue.isFeedbackVisible);
                }
            });
            $A.enqueueAction(action);
            countyPlanRecord.Id = component.get("v.recordId").substring(0,15);
            component.set("v.countyPlanRec",countyPlanRecord);
            helper.getCountyPlanRecord(component, helper);
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
        
        if(!$A.util.isUndefinedOrNull(component.get("v.countyPlanRec").Id)){
            helper.redirectToRecord(component.get("v.countyPlanRec").Id);
        }
        else{
            helper.redirectToRecord(recordId);
        }
    },
    saveAsDraft : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.upsertRecords", 
                function(response){
                    if(response.isSuccessful){
                        if(!component.get("v.countyPlanRec").Id)
                            component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                        helper.redirectToRecord(component.get("v.countyPlanRec").Id);
                    }
                }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
    },
    closeModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnDiffOwnerCounty");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
    },
    doChangeCurrentTab : function(component, event, helper) {
        component.set("v.pageMessages",[]);
        component.set("v.messageType",null);
    },
    doPrevious : function(component, event, helper) {
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    doFinish : function(component, event, helper) {
        var childCmp = component.find("countyPlanFlowScreen5_Eligibility");
        childCmp.callValidateCurrentPage();
        
        var countyPlanRec = component.get("v.countyPlanRec");
        // server side call
        if(component.get("v.isCurrentPageValid")){
            countyPlanRec.Flow_Completed__c = true;
        	component.set("v.countyPlanRec", countyPlanRec);
        	var isFinalStep = component.get("v.isNew");
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                if(component.get("v.isCurrentPageValid")==true){
                                                    component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                   
                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    helper.redirectToRecord(component.get("v.countyPlanRec").Id);
                                                }
                                            }, {'lstSObject':[component.get("v.countyPlanRec")],
                                                "isFinalStep":isFinalStep
                                               }, false, null);
        }
    },
    doNext : function(component, event, helper) {
        window.scroll(0, 0);
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            // handling client side validations
            var childCmp = component.find("countyPlanFlowScreen1_CountyPlanInformation");
            childCmp.callValidateCurrentPage();
            if(component.get("v.isCurrentPageValid")== true){
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                        var originalTemplate= component.get("v.originalTemplate");
                                                        var currentTemplate= component.get("v.countyPlanRec").CDE_COUNTY_PLAN_TEMPLT__c;
                                                        if(component.get("v.countyId")!=null) 
                                                        {
                                                            helper.getCountyPlanRecordForTemplate(component, helper);
                                                        }
                                                        else if (component.get("v.recordId")!=null && originalTemplate != currentTemplate){
                                                            component.set("v.originalTemplate", currentTemplate);
                                                            helper.getCountyPlanRecordForTemplate(component, helper);
                                                        }
                                                        else{
                                                            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                        }    
                                                        helper.updateFPGValue(component);
                                                    }
                                                }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
            }
            
        }
        else if(currentTabNumber==2)
        {
            var childCmp = component.find("countyPlanFlowScreen2_CCDF");
            childCmp.callValidateCurrentPage();
           
            // server side call
            if(component.get("v.isCurrentPageValid")){
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));

                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    }
                                                }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
                
            }
        }
            else if(currentTabNumber==3)
            {
                var childCmp = component.find("countyPlanFlowScreen3_CCCAP");
                childCmp.callValidateCurrentPage();
               
                if(component.get("v.isCurrentPageValid")){
                    helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                    function(response){
                                                        if(component.get("v.isCurrentPageValid")==true){
                                                            component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                           
                                                            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                        }
                                                    }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
                    
                }
            }
                else if(currentTabNumber==4)
                {
                    var childCmp = component.find("countyPlanFlowScreen4_AF");
                    childCmp.callValidateCurrentPage();
                    
                    if(component.get("v.isCurrentPageValid")){
                        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                        function(response){
                                                            if(component.get("v.isCurrentPageValid")==true){
                                                                component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                               
                                                                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                            }
                                                        }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
                        
                    }
                }
                    else if(currentTabNumber==5)
                    {
                        var childCmp = component.find("countyPlanFlowScreen4_1_Risk");
                        childCmp.callValidateCurrentPage();
                        
                        if(component.get("v.isCurrentPageValid")){
                            helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                            function(response){
                                                                if(component.get("v.isCurrentPageValid")==true){
                                                                    component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                                   
                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                }
                                                            }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
                            
                        }
                        
                    }
                        else if(currentTabNumber==6)
                        {
                            var childCmp = component.find("countyPlanFlowScreen5_Eligibility");
                            childCmp.callValidateCurrentPage();
                            
                            if(component.get("v.isCurrentPageValid")){
                                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                                function(response){
                                                                    if(component.get("v.isCurrentPageValid")==true){
                                                                        component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                                    
                                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                    }
                                                                }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
                                
                            }
                            
                        }
                    },
                    toggleFeedback: function(component,event,helper){
                        component.set('v.showFeedback',!component.get('v.showFeedback'));
                    }
                })