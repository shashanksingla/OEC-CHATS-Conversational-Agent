({
    callModal: function (cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    
    decrementCurrentTabNumber: function (cmp) {
        cmp.set("v.currentTabNumber", cmp.get("v.currentTabNumber") - 1);
    },
    
    exemptDecrementCurrentTabNumber: function (cmp) {
        cmp.set("v.showFinishBtnForExmptProvider", false);
        cmp.set("v.currentTabNumber", cmp.get("v.currentTabNumber") - 2);
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
    
    actionOnDoFinish: function (component, event, helper) {
        var self = this;
        var time = 1; //in second
        component.set("v.retryAttempts", component.get("v.retryAttempts") + 1);
        var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
        //var lstFiscalRateAmount= component.get("v.lstFiscalRateAmount");
        var lstFiscalRateAmount = [];
        for (var key in mapFiscalRateAmount) {
            var fiscalRateAmount = mapFiscalRateAmount[key];
            delete fiscalRateAmount.Id;
            fiscalRateAmount.sobjectType = 'batchsit_t_fiscal_rate__x';
            fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;
            lstFiscalRateAmount.push(fiscalRateAmount);
        }
        component.set("v.lstFiscalRateAmount", lstFiscalRateAmount);
        //var childCmp = component.find("rateScheduleFlow_RATFeesFiscalScreen"); //Commented by Rishav for CCCAP-2616
        //var childCmp1 = component.find("rateScheduleFlow_FiscalRate");
        var facilityType = component.get("v.CDE_TYPE_FACILITY__c");
        if (facilityType != 'EXE') {
            if (component.get("v.isCurrentPageValid")) {
                var fromFields = ['AMT_TRANS_FA__c', 'AMT_REG_FA__c', 'AMT_ACT_FA__c'];
                var copyToFields = ['AMT_TRANS_CTY__c', 'AMT_REG_CTY__c', 'AMT_ACT_CTY__c'];
                for (var j = 0; j < copyToFields.length; j++) {
                    //component.set("v.fiscalRateValues." + fromFields[j], childCmp.get('v.' + fromFields[j])); //Commented by Rishav for CCCAP-2616
                    var faValue = component.get("v.fiscalRateValues." + fromFields[j]);
                    component.set('v.fiscalRateValues.' + copyToFields[j], faValue);
                }
                var rateSchedule = component.get("v.rateSchedule");
                rateSchedule.Is_Flow_Completed__c = true;
                component.set('v.rateSchedule', rateSchedule);
                helper.callServerAndHandleError(component, "c.insertFiscalRateRecords",
                                                function (response) {
                                                    component.set("v.showSpinner", true);
                                                    if (component.get("v.isCurrentPageValid") == true) {
                                                        if (response.isSuccessful) {
                                                            if (response.successMessage == 'Success') {
                                                                component.set("v.retryAttempts", 0);
                                                                var lstFiscalRateAmount = component.get("v.lstFiscalRateAmount");
                                                                component.set("v.showSpinner", false);
                                                                helper.callServerAndHandleError(component, "c.upsertRecordsFinal",
                                                                                                function (response) {
                                                                                                    if (component.get("v.isCurrentPageValid") == true) {
                                                                                                        component.set("v.fiscalRateValues", helper.merge(component.get("v.fiscalRateValues"), response.objectData.upsertedRecords[0]));
                                                                                                        var providerId = component.get("v.providerFiscalAgreementRec").ID_SERVICE__c;
                                                                                                        helper.callServerAndHandleError(component, "c.finishRateSchedule",
                                                                                                                                        function (response) {
                                                                                                                                            if (response.isSuccessful) {
                                                                                                                                                var recordId = component.get("v.recordId");
                                                                                                                                                helper.goToRecord(recordId, 'detail');
                                                                                                                                            }
                                                                                                                                        }, { 'providerId': providerId, 'rateSchedule': rateSchedule }, false, null);
                                                                                                    }
                                                                                                }, { 'lstSObject': [component.get("v.rateSchedule"), component.get("v.fiscalRateValues")], 'isFinalStep': true }, false, null);
                                                            } else {
                                                                if (response.objectData.Retry && component.get("v.retryAttempts") < ($A.get("$Label.c.Retry_Number"))) {
                                                                    window.setTimeout(
                                                                        $A.getCallback(function () {
                                                                            self.actionOnDoFinish(component, event, helper);
                                                                        }), time * 5000
                                                                    );
                                                                } else {
                                                                    this.toastMessage('Error', 'The process of creating Rate Schedule is taking more time, please wait and click Complete.');
                                                                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                                                                    dismissActionPanel.fire();
                                                                    component.set("v.showSpinner", false);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }, { 'lstFiscalRateAmount': component.get("v.lstFiscalRateAmount") }, false, null);
            }
        } else {
            if (component.get("v.isCurrentPageValid")) {
                var rateSchedule = component.get("v.rateSchedule");
                rateSchedule.Is_Flow_Completed__c = true;
                component.set('v.rateSchedule', rateSchedule);
                helper.callServerAndHandleError(component, "c.insertFiscalRateRecords",
                                                function (response) {
                                                    component.set("v.showSpinner", true);
                                                    if (component.get("v.isCurrentPageValid") == true) {
                                                        if (response.isSuccessful) {
                                                            if (response.successMessage == 'Success') {
                                                                component.set("v.retryAttempts", 0);
                                                                var lstFiscalRateAmount = component.get("v.lstFiscalRateAmount");
                                                                component.set("v.showSpinner", false);
                                                                helper.callServerAndHandleError(component, "c.upsertRecordsFinal",
                                                                                                function (response) {
                                                                                                    if (component.get("v.isCurrentPageValid") == true) {
                                                                                                        component.set("v.fiscalRateValues", helper.merge(component.get("v.fiscalRateValues"), response.objectData.upsertedRecords[0]));
                                                                                                        var providerId = component.get("v.providerFiscalAgreementRec").ID_SERVICE__c;
                                                                                                        helper.callServerAndHandleError(component, "c.finishRateSchedule",
                                                                                                                                        function (response) {
                                                                                                                                            if (response.isSuccessful) {
                                                                                                                                                helper.callServerAndHandleError(component, "c.triggerCorspdCR707",
                                                                                                                                                                                function (response) {
                                                                                                                                                                                    if (response.isSuccessful) {
                                                                                                                                                                                        helper.callServerAndHandleError(component, "c.triggerCorspdCR707",
                                                                                                                                                                                                                        function (response) {
                                                                                                                                                                                                                            if (response.isSuccessful) {
                                                                                                                                                                                                                                var recordId = component.get("v.recordId");
                                                                                                                                                                                                                                helper.goToRecord(recordId, 'detail');
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                        }, { 'rateScheduleId': component.get("v.rateSchedule").Id }, false, null);
                                                                                                                                                                                    }
                                                                                                                                                                                },
                                                                                                                                                                                {
                                                                                                                                                                                    'rateScheduleId': [component.get("v.rateSchedule")].Id
                                                                                                                                                                                }, false, null);
                                                                                                                                            }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                            'providerId': providerId, 'rateSchedule': rateSchedule
                                                                                                                                        }, false, null);
                                                                                                    }
                                                                                                },
                                                                                                {
                                                                                                    'lstSObject': [component.get("v.rateSchedule"), component.get("v.fiscalRateValues")], 'isFinalStep': true
                                                                                                }, false, null);
                                                            } else {
                                                                if (response.objectData.Retry && component.get("v.retryAttempts") < ($A.get("$Label.c.Retry_Number"))) {
                                                                    window.setTimeout(
                                                                        $A.getCallback(function () {
                                                                            self.actionOnDoFinish(component, event, helper);
                                                                        }), time * 5000
                                                                    );
                                                                } else {
                                                                    this.toastMessage('Error', 'The process of creating Rate Schedule is taking more time, please wait and click Complete.');
                                                                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                                                                    dismissActionPanel.fire();
                                                                    component.set("v.showSpinner", false);
                                                                }
                                                            }
                                                        }
                                                    }
                                                },
                                                {
                                                    'lstFiscalRateAmount': component.get("v.lstFiscalRateAmount")
                                                }, false, null);
                
            }
        }
    },
    
    clearObjectFields: function (domObject, sObjectFields) {
        for (var eachFiscalObjField in sObjectFields) {
            domObject[sObjectFields[eachFiscalObjField]] = '';
        }
    },
    
    actionOnDoNextTab1: function (component, event, helper) {
        var rateScheduleRec = component.get("v.rateSchedule");
        var selectedRateTypes = component.get("v.selectedRateTypes");
        var rateType = '';
        for (var i = 0; i < selectedRateTypes.length; i++) {
            rateType += selectedRateTypes[i] + ';';
        }
        rateScheduleRec.CDE_RATE_TYPE__c = rateType;
        rateScheduleRec.DTE_BEGIN_EFFV__c = component.get("v.effectiveBeginDate");
        rateScheduleRec.IDN_AGRMT_FISCAL__c = component.get("v.recordId");
        component.set("v.rateSchedule", rateScheduleRec);
        var childCmp = component.find("rateScheduleFlow_NewRateSchedule");
        childCmp.callValidateCurrentPage();
        if (component.get("v.isCurrentPageValid")) {
            helper.callServerAndHandleError(component, "c.upsertRecords",
                                            function (response) {
                                                if (component.get("v.isCurrentPageValid") == true) {
                                                    component.set("v.rateSchedule", helper.merge(component.get("v.rateSchedule"), response.objectData.upsertedRecords[0]));
                                                    var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
                                                    component.set('v.mapExistingFiscalRateAmount', mapFiscalRateAmount);
                                                    var lstFiscalRateAmount = [];
                                                    for (var key in mapFiscalRateAmount) {
                                                        var fiscalRateAmount = mapFiscalRateAmount[key];
                                                        if (fiscalRateAmount.Id == '' || fiscalRateAmount.Id == undefined || fiscalRateAmount.Id == null) {
                                                            delete fiscalRateAmount.Id;
                                                        }
                                                        fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;
                                                        var rateSchedule = component.get("v.rateSchedule");
                                                        var lstRateTypesFromSchedule = rateSchedule.CDE_RATE_TYPE__c.split(";");
                                                        if (lstRateTypesFromSchedule.indexOf(fiscalRateAmount.cde_rate_type__c) != -1) {
                                                            lstFiscalRateAmount.push(fiscalRateAmount);
                                                        }
                                                    }
                                                    var mapExistingFiscalRateAmount = {};
                                                    for (var i = 0; i < lstFiscalRateAmount.length; i++) {
                                                        var key = lstFiscalRateAmount[i].cde_rate_type__c + '_' + lstFiscalRateAmount[i].cde_age_group__c + '_' + lstFiscalRateAmount[i].cde_care_unit__c;
                                                        var fiscalRateAmount = lstFiscalRateAmount[i];
                                                        delete fiscalRateAmount.Id;
                                                        fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;;
                                                        mapExistingFiscalRateAmount[key] = fiscalRateAmount;
                                                    }
                                                    component.set("v.mapExistingFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount, {}));
                                                    component.set("v.mapFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount, {}));
                                                    component.set("v.lstFiscalRateAmount", lstFiscalRateAmount);
                                                    component.set("v.lstExistingFiscalRateAmount", lstFiscalRateAmount);
                                                    var exemptFacType = component.get("v.CDE_TYPE_FACILITY__c");
                                                    if (exemptFacType == 'EXE') {
                                                        component.set("v.showFinishBtnForExmptProvider", true);
                                                        if (component.get("v.mapFiscalRateAmount") != null && component.get("v.mapFiscalRateAmount") != "") {
                                                            this.getExmptCellingRate(component, event, helper);
                                                        }
                                                    } else {
                                                        component.set("v.currentTabNumber", component.get("v.currentTabNumber") + 1);
                                                    }
                                                    component.set("v.doNextEnabled", false);
                                                }
                                            },
                                            {
                                                'lstSObject': [component.get("v.rateSchedule")]
                                            }, false, null);
        }
    },
    
    getTierValue: function (providerQualityRating, providerType) {
        if (providerType == 'EXE') {
            return '1';
        } else if (providerQualityRating == 'Level 1') {
            return '2';
        } else if (providerQualityRating == 'Level 2') {
            return '3';
        } else if (providerQualityRating == 'Level 3') {
            return '4';
        } else if (providerQualityRating == 'Level 4') {
            return '5';
        } else if (providerQualityRating == 'Level 5') {
            return '6';
        }
    },
    
    validate: function (component) {
        var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
        var hasBlankEntries = false;
        var cellsHavingOutOfRangeValue = 0;
        var isValid = true;
        for (var key in mapFiscalRateAmount) {
            if (mapFiscalRateAmount[key].amt_provr__c == undefined || mapFiscalRateAmount[key].amt_provr__c == null) {
                hasBlankEntries = true;
            }
            if (mapFiscalRateAmount[key].amt_provr__c < 0) {
                cellsHavingOutOfRangeValue++;
            }
        }
        var error = [];
        if (hasBlankEntries) {
            error.push("Please fill out all the entries");
            isValid = false;
        }
        if (cellsHavingOutOfRangeValue == 1) {
            error.push("Amount can not be less than 0.");
            isValid = false;
        }
        if (cellsHavingOutOfRangeValue > 1) {
            error.push("One or more cells have amount less than 0. Please correct it.");
            isValid = false;
        }
        component.set("v.pageMessages", error);
        component.set("v.messageType", "error");
        return isValid;
    },
    
    getFutureDate: function (days) {
        var futureDate = new Date(new Date().getTime() + days * 24 * 60 * 60 * 1000);
        var dd = futureDate.getDate();
        var MM = futureDate.getMonth() + 1;
        var yyyy = futureDate.getFullYear();
        if (dd < 10) {
            dd = '0' + dd;
        }
        if (MM < 10) {
            MM = '0' + MM;
        }
        return yyyy + '-' + MM + '-' + dd;
    },
    
    getExmptCellingRate: function (component, event, helper) {
        var providerType = component.get('v.CDE_TYPE_FACILITY__c');
        var providerQualityRating = component.get('v.providerQualityRating');
        var tierValue = helper.getTierValue(providerQualityRating, providerType);
        var selectedRateTypes = component.get("v.selectedRateTypes");
        var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
        component.set('v.mapExistingFiscalRateAmount', mapFiscalRateAmount);
        var lstFiscalRateAmount = [];
        for (var key in mapFiscalRateAmount) {
            var fiscalRateAmount = mapFiscalRateAmount[key];
            if (fiscalRateAmount.Id == '' || fiscalRateAmount.Id == undefined || fiscalRateAmount.Id == null) {
                delete fiscalRateAmount.Id;
            }
            fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;
            lstFiscalRateAmount.push(fiscalRateAmount);
        }
        component.set("v.lstFiscalRateAmount", lstFiscalRateAmount);
        var lstFiscalRateAmount = component.get("v.lstFiscalRateAmount");
        helper.callServerAndHandleError(component, "c.getCeilingAmountForExe",
                                        function (response) {
                                            var lstCountyRateAmt = response.objectData.lstCountyRateAmt;
                                            var mapExistingFiscalRateAmount = {};
                                            for (var i = 0; i < lstCountyRateAmt.length; i++) {
                                                var key = lstCountyRateAmt[i].CDE_RATE_TYPE__c + '_' + lstCountyRateAmt[i].CDE_AGE_GROUP__c + '_' + lstCountyRateAmt[i].CDE_UNIT__c;
                                                var fiscalRateAmount = {};
                                                fiscalRateAmount.cde_rate_type__c = lstCountyRateAmt[i].CDE_RATE_TYPE__c;
                                                fiscalRateAmount.cde_age_group__c = lstCountyRateAmt[i].CDE_AGE_GROUP__c;
                                                fiscalRateAmount.cde_care_unit__c = lstCountyRateAmt[i].CDE_UNIT__c;
                                                fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;
                                                fiscalRateAmount.amt_fa__c = lstCountyRateAmt[i].NBR_AMOUNT__c;
                                                fiscalRateAmount.amt_provr__c = lstCountyRateAmt[i].NBR_AMOUNT__c;
                                                mapExistingFiscalRateAmount[key] = fiscalRateAmount;
                                            }
                                            component.set("v.mapExistingFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount, {}));
                                            component.set("v.mapFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount, {}));
                                            var lstFiscalRateAmount = [];
                                            for (var key in mapExistingFiscalRateAmount) {
                                                var fiscalRateAmount = mapExistingFiscalRateAmount[key];
                                                lstFiscalRateAmount.push(fiscalRateAmount);
                                            }
                                            component.set("v.lstFiscalRateAmount", lstFiscalRateAmount);
                                            component.set("v.lstExistingFiscalRateAmount", lstFiscalRateAmount);
                                            component.set("v.currentTabNumber", component.get("v.currentTabNumber") + 2);
                                        },
                                        {
                                            'countyRatePlanId': component.get("v.countyRatePlan").Id,
                                            'providerType': providerType,
                                            'tierValue': tierValue,
                                            'selectedRateLst': selectedRateTypes
                                        }, false, null);
    }
})