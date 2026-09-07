({
    setAuthBeginDateMin :  function(component) {
        //Begin Date has to be the first of a month and 
        //greater than the current system date (can't be equal)
        //Authorization Begin Date cannot be earlier than the 
        //child's eligibility begin date.
        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
        component.set("v.authBeginDateMin",  today.getFullYear() + "-" + monthDigit + "-" + today.getDate());
    },
    
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        var result = this.validateAuthSlotBeginDate(cmp);
        return result;
    },
    
    handleBeginDateUpdate :  function(component) {
        var filter = 'CDE_TYPE_STATUS__c=\'OPN\' and ID_SERVICE__r.CDE_STATUS_PROVR__c NOT IN  (\'Closed\',\'Pending\') ';
        if(component.get("v.authRec.DTE_BEGIN_EFFV_AUTH__c") != undefined && component.get("v.authRec.DTE_BEGIN_EFFV_AUTH__c") !='undefined'){
            filter = filter+ ' and DTE_BEGIN_AGRMT__c <= ' + component.get("v.authRec.DTE_BEGIN_EFFV_AUTH__c");
        }
        component.set("v.lookupFilter",filter); 
    },
    
    validateProviderIdVal :  function(component, event, helper){
        var isCreate = component.get("v.isCreate");
        var authRec =component.get("v.authRec"); 
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var providerId = component.get("v.providerIdVal");
        var caseObj = component.get("v.caseRec");
        
        if(providerId && beginDate){
            if(isCreate){
                var action1 = component.get('c.validateProviders');
                action1.setParams({
                    'providerId':providerId,'beginDate':beginDate,'caseObj':caseObj
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    if (component.isValid() && state == 'SUCCESS') {
                        var res =response.getReturnValue();
                        // Alert the user with the value returned 
                        // from the server
                        if(res.isSuccessful){
                            component.set("v.isInvalidProvider",false);
                            component.set("v.isReqProviderLocation",res.objectData.isReqProviderLocation);
                            authRec.IDN_PROVR__c = providerId;
                            component.find("ProviderILkUpId").set("v.message",'');
                            component.set("v.findProviderName",providerId);
                            component.set("v.authRec",authRec);
                            this.getRateTypeOptionsVal(component, event, helper);
                            // Start: Added by Rishav for CCCAP-2618
                            component.set("v.isProviderExempt", res.objectData.isProviderExempt);
                            if(!res.objectData.isProviderExempt){
                                helper.setTransFeeRestriction(component, event, helper);
                            }
                            // End: CCCAP-2618
                        } else {
                            component.set("v.isInvalidProvider",true);
                            component.find("ProviderILkUpId").set("v.message",'Invalid provider, please check related Fiscal Agreement and Rate Schedule records for this provider or select different provider. \n Or change the Authorization Begin Date');
                        }
                    } else {
                        //error in InputPicklist
                    }
                });        
                $A.enqueueAction(action1); 
            }
        } else {
            if(beginDate =='' || beginDate == undefined){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Please select Authorization begin date to validate the provider."
                });
                toastEvent.fire();
            }
        }
    },

    getSCAssociations : function(component, event, helper){
        var providerId = component.get("v.providerIdVal");
        var caseObj = component.get("v.caseRec");
        var isCreate = component.get("v.isCreate");
        var authRec = component.get("v.authRec");
        var beginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        if(isCreate){
            var action1 = component.get('c.fetchSCAssociations');
            action1.setParams({
                'SCId':null,'providerId':providerId,'caseObj':caseObj, 'authBeginDate':beginDate
            });
        }
        else if(!isCreate){
            var provid=authRec.IDN_PROVR__c;
            var caseid=authRec.IDN_CASE__r.CDE_COUNTY__c;
            var slotid=authRec.IDN_SLOT_CONTRACT__c;
            component.set("v.caseRec.CDE_COUNTY__c",caseid);            
            var action1 = component.get('c.fetchSCAssociations');
            action1.setParams({               
                'SCId':slotid,'providerId':provid,'caseObj':caseObj, 'authBeginDate':beginDate
            });
        }
        action1.setCallback(this, function(response) {
            console.log('action call back');
            var state = response.getState();
            var res = response.getReturnValue();
            console.log('state: '+state);
            if (state == 'SUCCESS') {
                if(res.isSuccessful){                       
                    component.set("v.slotContractOptions",res.objectData.slotContractOptions);
                    component.set("v.isCountyRateSCQ",true);
                    console.log("slot contract ids" + res.objectData.slotContractOptions);                   
                } else {
                    component.set("v.isCountyRateSCQ",false);
                }     
            } else {
                component.set("v.isCountyRateSCQ",false);
            }
        });        
        $A.enqueueAction(action1);       
    },
    populateSlotFields : function(component, event, helper){
        var authRec = component.get('v.authRec');
        var scAssRecId = authRec.IDN_SLOT_CONTRACT__c;
        var action = component.get('c.queryPopulateSCAssRecord');
        action.setParams({
            'scAssId' : scAssRecId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){                        
                    if(!$A.util.isEmpty(scAssRecId)){
                        var scAssRec=component.get('v.SCAssociationRec');
                        scAssRec.DTE_BEGIN_SLOT__c=res.objectData.scAssRecBgnDte;
                        scAssRec.DTE_END_SLOT__c=res.objectData.scAssRecEndDte;
                        scAssRec.CDE_CARE_LEVEL__c=res.objectData.scAssCareLvl;
                        scAssRec.SLOT_CONTRACT_DESCRIPTION__c=res.objectData.scAssDesc;
                        component.set("v.SCAssociationRec",scAssRec);
                        component.set("v.mandatory", true);
                    } 
                    else{
                        component.set("v.SCAssociationRec",{'sobjectType':'T_SLOT_CONTRACT__c','IDN_AUTH__c':'','DTE_BEGIN_SLOT__c':'','DTE_END_SLOT__c':'','CDE_CARE_LEVEL__c':'','SLOT_CONTRACT_DESCRIPTION__c':''});
                        component.set("v.mandatory", false);
                    }                      
                }
            } 
        });
        $A.enqueueAction(action); 
    },
    validateAuthSlotBeginDate : function(component){
        var isValid = true;
        var authRec = component.get("v.authRec");
        var authRecId = authRec.Id;
        var scAsscRecId = authRec.IDN_SLOT_CONTRACT__c;
        var authBginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        var authEndDate = authRec.DTE_END_EFFV_AUTH__c;
        var authBginDateCmp = component.find('T_AUTH__c-DTE_BEGIN_EFFV_AUTH__c');
        var authSlotBginDate = authRec.DTE_BEGIN_SLOT__c;
        var authSlotBginDateCmp = component.find('AuthSlotBeginDate');
        var scAssRec = component.get("v.SCAssociationRec");
        var slotEndDte = scAssRec.DTE_END_SLOT__c;
        var slotBgnDte = scAssRec.DTE_BEGIN_SLOT__c;
        var isCreate = component.get("v.isCreate");
        var isReadOnly = component.get("v.isReadOnly");
        
        var authRecClone = component.get("v.authRecClone");
        var oldSlotId = authRecClone.IDN_SLOT_CONTRACT__c;
        var oldSlotDate = authRecClone.DTE_BEGIN_SLOT__c;
        var checkValidations = false;
        
        if(!$A.util.isEmpty(authBginDate)){
            var bDateArrone = authBginDate.split('-');
            var bDateone = new Date(bDateArrone[0], bDateArrone[1]-1, bDateArrone[2]);
            var todayone = new Date();
            var Difference_In_Time_one = todayone.getTime() - bDateone.getTime();
            var Difference_In_Days_one = Difference_In_Time_one / (1000 * 3600 * 24);
            
            if(isCreate && Difference_In_Days_one > 10 && !isReadOnly){
                isValid = false;
                authBginDateCmp.set('v.message', 'Cannot be prior to {today + 9 days in the past}');  
            }
        }
        if(!isReadOnly && (isCreate || oldSlotId != scAsscRecId || oldSlotDate != authSlotBginDate)){
            checkValidations = true;
        }
        if(checkValidations && !$A.util.isEmpty(authSlotBginDate)){
            var bDateArr = authSlotBginDate.split('-');
            var bDate = new Date(bDateArr[0], bDateArr[1]-1, bDateArr[2]);
            var today = new Date();
            var Difference_In_Time = today.getTime() - bDate.getTime();
 	        var Difference_In_Days = Difference_In_Time / (1000 * 3600 * 24);
            
            if(!$A.util.isEmpty(authBginDate) && authSlotBginDate < authBginDate){
                isValid = false;
                authSlotBginDateCmp.set('v.message', 'Authorization Slot Begin Date should be greater than or equal to Authorization Begin Date');
            }
            else if(!$A.util.isEmpty(authEndDate) && authSlotBginDate > authEndDate){
                isValid = false;
                authSlotBginDateCmp.set('v.message', 'Authorization Slot Begin Date should be less than or equal to Authorization End Date');
            }
            else if(Difference_In_Days > 10){
                isValid = false;
                authSlotBginDateCmp.set('v.message', 'Authorization Slot Begin Date cannot have a date prior to today minus 9 days in past');  
            }
            else if(!$A.util.isEmpty(slotEndDte) && authSlotBginDate > slotEndDte){
                isValid = false;
                authSlotBginDateCmp.set('v.message', 'Authorization Slot Begin Date should be less than the Slot Contract End Date');  
            }
            else if(!$A.util.isEmpty(slotBgnDte) && authSlotBginDate < slotBgnDte){
                isValid = false;
                authSlotBginDateCmp.set('v.message', 'Authorization Slot Begin Date should be greater than equal to Slot Contract Begin Date');  
            }else{
                authSlotBginDateCmp.set('v.message', '') ; 
            }
        }
        component.set("v.authRec",authRec);
        if(!$A.util.isEmpty(scAsscRecId)){
            scAssRec.Id=scAsscRecId;
            component.set("v.SCAssociationRec",scAssRec);
        }
        return isValid;
    }, 

              
    
    
    getRateTypeOptionsVal : function(component, event, helper){
        // Get Rate Types
        var isCreate = component.get("v.isCreate");
        var authRec =component.get("v.authRec");
        var authId = authRec.Id;
        if(isCreate){
            authId=component.get("v.caseRec").Id;
        } else {
            authId=authRec.Id
        }
        var providerId = component.get("v.providerIdVal");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var clientId =authRec.IDN_CLIENT__c;
        if(!$A.util.isEmpty(clientId)){
            var action1 = component.get('c.getRateTypeOptions');
            action1.setParams({
                'authId' : authId,'isCreate':isCreate,'providerId':providerId,'beginDate':beginDate,'clientId':clientId
            });
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    component.set("v.rateTypeOptions",response.getReturnValue());
                } else {
                }
            });        
            $A.enqueueAction(action1);
        }
    },
    
    validateProviderBasedOnBeginDt :function(component, event, helper){
        var isCreate = component.get("v.isCreate");
        var authRec =component.get("v.authRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var providerId = component.get("v.providerIdVal");
        var caseObj = component.get("v.caseRec");  
        
        if(providerId != '' && providerId != undefined && beginDate !='' && beginDate != undefined){
            if(isCreate){
                var action1 = component.get('c.validateProviders');
                action1.setParams({
                    'providerId':providerId,'beginDate':beginDate,'caseObj':caseObj 
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    if (component.isValid() && state == 'SUCCESS') {
                        var res =response.getReturnValue();
                        // Alert the user with the value returned 
                        // from the server
                        if(res.isSuccessful){
                            component.set("v.isInvalidProvider",false);
                            component.set("v.isReqProviderLocation",res.objectData.isReqProviderLocation);
                            authRec.IDN_PROVR__c = providerId;
                            component.find("ProviderILkUpId").set("v.message",'');
                            // component.set("v.findProviderName",providerId);
                            //component.set("v.authRec",authRec);
                            this.getRateTypeOptionsVal(component, event, helper);
                        }else{
                            component.set("v.isInvalidProvider",true);
                            component.set("v.rateTypeOptions",[]);
                            
                            component.find("ProviderILkUpId").set("v.message",'Invalid provider, please check related fiscal agreement records for this provider or select different provider.');
                        }
                    } else {
                        
                    }
                });        
                $A.enqueueAction(action1); 
            }
        } else {
            if(beginDate =='' || beginDate == undefined){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Please select Authorization begin date to validate the provider."
                });
                toastEvent.fire();
            }
        }
    },
    
    validateIndicatorBasedOnBeginDt : function(component, event, helper){
        var isCreate = component.get("v.isCreate");
        var authRec =component.get("v.authRec");
        var caseObj = component.get("v.caseRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        
        if(isCreate){
            var action1 = component.get('c.checkCountyIndicator');
            action1.setParams({
                'recordId' : caseObj.Id,'beginDate':beginDate
            });
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    var res =response.getReturnValue();
                    if(res.isSuccessful){
                        if(res.objectData.showContractToIndicator){
                            component.set("v.isShowContractToIndicator",res.objectData.showContractToIndicator);
                        }
                        if(res.objectData.protectiveServiceIndicator){
                            component.set("v.isProtectiveServiceIndicator",res.objectData.protectiveServiceIndicator);
                        }
                        if(res.objectData.showDropInDaysIndicator){
                            component.set("v.isDropInDaysIndicator",res.objectData.showDropInDaysIndicator);
                            var authRec = component.get("v.authRec");
                            component.set("v.numberOfDaysDrop",res.objectData.numberOfDaysDrop);
                        } else{
                            component.set("v.isDropInDaysIndicator",false);
                            component.set("v.numberOfDaysDrop",0);
                        }
                        // Start: Added by Rishav for CCCAP-2618
                        if(!component.get("v.isProviderExempt")){
                            helper.setTransFeeRestriction(component, event, helper);
                        }
                        // End: CCCAP-2618
                    }
                } else {
                }
            });        
            $A.enqueueAction(action1);
        }
    },
    
    // Start: Added by Rishav for CCCAP-2618
    setTransFeeRestriction: function(component, event, helper){
        var isCreate = component.get("v.isCreate");
        var isReadOnly = component.get("v.isReadOnly");
        /*
         * Create New Authorization --> isCreate = true, isReadOnly = false
         * View Authorization --> isCreate = false, isReadOnly = true
         * Edit Authorization --> isCreate = false, isReadOnly = false
         */
        if(isCreate) /* Create New Authorization */ {
            var beginDate = component.get("v.authRec.DTE_BEGIN_EFFV_AUTH__c");
            var providerId = component.get("v.providerIdVal");
            var caseCountyId = component.get("v.caseRec.CDE_COUNTY__c");
            if(!$A.util.isEmpty(caseCountyId) && !$A.util.isEmpty(beginDate) && !$A.util.isEmpty(providerId)){
                var action = component.get('c.executeTransportationFeeLogic');
                action.setParams({
                    'beginDate':beginDate, 'providerId':providerId, 'caseCountyId':caseCountyId
                });
                action.setCallback(this, function(response) {
                                                console.log('res', JSON.stringify(response.getReturnValue));

                    var state = response.getState();
                    if (component.isValid() && state == 'SUCCESS') {
                        var res = response.getReturnValue();
                        if(res.isSuccessful){
                            console.log('res', res.objectData);
                            console.log('typeof', typeof res.objectData);

                            component.set("v.showTransFeeRestriction", res.objectData.showTransFeeRestriction);
                            component.set("v.authRec.CDE_TRANS_FEE__c", res.objectData.transFeeRestrictionValue);
                            console.log('has key', ('transFeeRestrictionValue' in res.objectData));

                            console.log('value',res.objectData.transFeeRestrictionValue);
                            console.log('auth0',component.get("v.authRec.CDE_TRANS_FEE__c"));
							                            console.log('res', JSON.stringify(response));

                        }
                    }
                });        
                $A.enqueueAction(action);
            }
            console.log('auth',component.get("v.authRec.CDE_TRANS_FEE__c"));

        } else /* View & Edit Authorization */ {
            var providerType = component.get("v.authRec.IDN_PROVR__r.CDE_TYPE_PROVR__c");
            var EXEMPT = $A.get("$Label.c.Exempt_Provider_Type");
            if(EXEMPT.includes(providerType)){
                component.set("v.isProviderExempt", true);
                component.set("v.showTransFeeRestriction", false);
                if(!isReadOnly)
                    component.set("v.authRec.CDE_TRANS_FEE__c", null);
            } else {
                var beginDate = component.get("v.authRec.DTE_BEGIN_EFFV_AUTH__c");
                var providerId = component.get("v.authRec.IDN_PROVR__c");
                var caseCountyId = component.get("v.authRec.IDN_CASE__r.CDE_COUNTY__c");
                if(!$A.util.isEmpty(caseCountyId) && !$A.util.isEmpty(beginDate) && !$A.util.isEmpty(providerId)){
                    var action = component.get('c.executeTransportationFeeLogic');
                    action.setParams({
                        'beginDate':beginDate, 'providerId':providerId, 'caseCountyId':caseCountyId
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state == 'SUCCESS') {
                            var res = response.getReturnValue();
                            if(res.isSuccessful){
                                component.set("v.showTransFeeRestriction", res.objectData.showTransFeeRestriction);
                            }
                        }
                    });        
                    $A.enqueueAction(action);

                }
            }
        }
    },
    // End: CCCAP-2618
    
    checkChildDisability : function(component, event, helper){
        var authRecToBeUpserted = component.get("v.authRec");
        var caseRec = component.get("v.caseRec");
        var caseId = caseRec.Id;
        var clientId = authRecToBeUpserted.IDN_CLIENT__c;
        var beginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
        
        if(!$A.util.isEmpty(beginDate) && !$A.util.isEmpty(clientId)){
            var action = component.get('c.disabilityCheck');
            action.setParams({
                'childId':clientId,
                'beginDate':beginDate
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    var res =response.getReturnValue();
                    if(res.isSuccessful){
                        if(res.objectData.isChildDisable){
                            component.set("v.isChildDisable",res.objectData.isChildDisable);
                        }
                        else{
                            component.set("v.isChildDisable",false);
                        }
                    }else{
                        var message = res.errorMessage;
                        component.find("T_AUTH__c-IDN_CLIENT__c").set("v.message",message);
                    }
                }
            });        
            $A.enqueueAction(action);
        }
    },   
    
    validateIndicatorInEditFlow : function(component, event, helper){
        var isCreate = component.get("v.isCreate");
        var authRec =component.get("v.authRec");
        var caseObj = component.get("v.caseRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var action1 = component.get('c.checkCountyIndicator');
        action1.setParams({
            'recordId' : authRec.CDE_COUNTY__c,'beginDate':beginDate
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData.showDropInDaysIndicator){
                        component.set("v.isDropInDaysIndicator",res.objectData.showDropInDaysIndicator);
                        var authRec = component.get("v.authRec");
                        component.set("v.numberOfDaysDrop",res.objectData.numberOfDaysDrop);
                        if(!isCreate){
                            component.set("v.authDropInDays",authRec.Number_of_Drop_in_Days__c);
                        }else{
                            component.set("v.authDropInDays",res.objectData.numberOfDaysDrop);
                        }
                    }
                    else{
                        component.set("v.isDropInDaysIndicator",false);
                        component.set("v.numberOfDaysDrop",0);
                    }
                    
                }
            } else {
                console.log('error in InputPicklist');
            }
        });        
        $A.enqueueAction(action1);
    }
    
   /* 
   setChildStateOptionsHlp : function(component, event, helper){
        var authRecToBeUpserted = component.get("v.authRec");
        var caseRec = component.get("v.caseRec");
        var childStateOptions = component.get("v.childStateOptions");
        var caseId = caseRec.Id;
        var clientId = authRecToBeUpserted.IDN_CLIENT__c;
        var beginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
        if(!$A.util.isEmpty(beginDate)){
        var action = component.get('c.getChildStateOptions');
        action.setParams({
            'caseId':caseId,
            'beginDate':beginDate
        });
           action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false); 
            if (component.isValid() && state == 'SUCCESS') {
                debugger;
                var returnedPicklistValues = response.getReturnValue();
                 var options = [];
                console.log('options-childStateOptions-'+JSON.stringify(returnedPicklistValues));
                
               
                options = options.concat(returnedPicklistValues.map(function(v) {
                    if(authRecToBeUpserted.IDN_CLIENT__c == v.value){
                       return {
                        'label' : v.label,
                        'value' : v.value,
                           'selected' : true,
                    };  
                    }
                    else{
                         return {
                        'label' : v.label,
                        'value' : v.value,
                    };
                    }
                })); 
                debugger;
                var isValidOption = false;
                console.log('lenth--'+options.length);
                if(!$A.util.isEmpty(options)){
                    for(var i=0;i< options.length;i++){
                        
                        if(options[i].value == authRecToBeUpserted.IDN_CLIENT__c ){
                            debugger;
                           isValidOption = true;
                            break;
                        }
                    }   
                }
                debugger;
                console.log('lenth--'+childStateOptions.length);
                if(!isValidOption){
                    if(!$A.util.isEmpty(childStateOptions)){
                        for(var j=0;j<childStateOptions.length;j++){
                            debugger;
                            if(childStateOptions[j].value == authRecToBeUpserted.IDN_CLIENT__c){
                                debugger;
                                childStateOptions[j].selected = true;
                                options.push(childStateOptions[j]);
                            }
                        }
                    }
                }
                //authRecToBeUpserted.IDN_CLIENT__c ='';
                component.set('v.childStateOptions', options);
                //  component.set('v.authRec', authRecToBeUpserted);                
            } else {
                console.log('error in InputPicklist');
            }
               component.set("v.showSpinner", false);            
           });        
            $A.enqueueAction(action);
        }
        
    },
    
    determineEligibility : function(component, event, helper){
        var authRecToBeUpserted = component.get("v.authRec");
        var caseRec = component.get("v.caseRec");
        var caseId = caseRec.Id;
        var clientId = authRecToBeUpserted.IDN_CLIENT__c;
        var beginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
        debugger;
        if(!$A.util.isEmpty(beginDate) && !$A.util.isEmpty(clientId)){
            component.set("v.showSectionSpinner",true);
        
        var action = component.get('c.isCaseEligible');
        action.setParams({
            'caseRecId' : caseId,
            'individualRecId':clientId,
            'newAuthorizations':authRecToBeUpserted
        });
        action.setCallback(this, function(response) {
            debugger;
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData){
                        if(res.objectData.Enddate){
                            component.find("T_AUTH__c-IDN_CLIENT__c").set("v.message",'');
                        }
                    }
                    
                }else{
                    var message = res.errorMessage;
                    
                    component.find("T_AUTH__c-IDN_CLIENT__c").set("v.message",message);
                    
                }
                component.set("v.showSectionSpinner", false); 
            } else {
                component.set("v.showSectionSpinner", false);
            }
        });        
        $A.enqueueAction(action);
        }
    },
    */
})