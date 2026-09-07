({
    getAdjustmentRecord: function(component) {
        var adjustment = component.get("v.adjustment");
        return {
            'Id':adjustment.Id,
            'sobjectType':'T_ADJMT__c',
            'CDE_TYPE_CLSFN__c':adjustment.CDE_TYPE_CLSFN__c,
            'IND_ORD_COURT_ADJMT__c':adjustment.IND_ORD_COURT_ADJMT__c,
            'CDE_REASON__c':adjustment.CDE_REASON__c,
            'CDE_TYPE_CLSFN__c':adjustment.CDE_TYPE_CLSFN__c,
            'Recovery_Initiative__c':adjustment.Recovery_Initiative__c,
            'CDE_EDIT_REASON__c':adjustment.CDE_EDIT_REASON__c
        };
    },
    
    setAddressFields : function(component, objectData) {
        var address = {'sobjectType':'T_ADJMT_ADDR__c'};
        if(objectData.addressList){
            //component.set("v.responsiblePartiesAddressList",objectData.addressList);
            component.set("v.responsiblePartiesAddressListClone",objectData.addressList);
        }
        if(objectData.responsiblePartiesAddressList){
            //component.set("v.responsiblePartiesAddressList",objectData.addressList);
            component.set("v.responsiblePartiesAddressList",objectData.responsiblePartiesAddressList);
        }
        var responsiblePartiesAddressList = component.get("v.responsiblePartiesAddressListClone");
        if(objectData.adjustment.Adjustment__r){
            address = objectData.adjustment.Adjustment__r[0];
        }else{
            if(objectData.adjustment.IDN_CASE__c!=undefined && objectData.adjustment.IDN_CASE__c!=null){
                if(objectData.caseRec && objectData.caseRec.T_SBSD_CASE3__r && objectData.caseRec.T_SBSD_CASE3__r[0]){
                    address.ADR_LINE_1__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_LINE_1__c;
                    address.ADR_LINE_2__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_LINE_2__c;
                    address.ADR_CITY__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_CITY__c;
                    address.ADR_STATE__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_STATE__c;
                    if(objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c != undefined && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c !=null){
                        address.ADR_ZIP_MAIN__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c.toString();
                    }
                    if(objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c != undefined && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c !=null){
                        address.ADR_ZIP_EXTN__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c.toString();
                    }
                    if(!$A.util.isEmpty(responsiblePartiesAddressList)){
                        for(var i=0;i<responsiblePartiesAddressList.length;i++){
                            responsiblePartiesAddressList[i].ADR_LINE_1__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_LINE_1__c;
                            responsiblePartiesAddressList[i].ADR_LINE_2__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_LINE_2__c;
                            responsiblePartiesAddressList[i].ADR_CITY__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_CITY__c;
                            responsiblePartiesAddressList[i].ADR_STATE__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_STATE__c;
                            if(objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c != undefined && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c !=null){
                                responsiblePartiesAddressList[i].ADR_ZIP_MAIN__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_MAIN__c.toString();
                            }
                            if(objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c != undefined && objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c !=null){
                                responsiblePartiesAddressList[i].ADR_ZIP_EXTN__c = objectData.caseRec.T_SBSD_CASE3__r[0].ADR_ZIP_EXTN__c.toString();
                            }  
                        }
                    }
                }
            }else if(objectData.adjustment.IDN_PROVR__c && objectData.adjustment.IDN_PROVR__c!=null){
                address.ADR_LINE_1__c = objectData.adjustment.IDN_PROVR__r.ADR_LINE1_MLNG__c;
                //address.ADR_LINE_2__c = objectData.adjustment.IDN_PROVR__r.ADR_LINE1__c;
                address.ADR_CITY__c = objectData.adjustment.IDN_PROVR__r.ADR_CITY_MLNG__c;
                address.ADR_STATE__c = objectData.adjustment.IDN_PROVR__r.ADR_STATE_MLNG__c;
                address.ADR_ZIP_MAIN__c = objectData.adjustment.IDN_PROVR__r.ADR_ZIP_MLNG__c;
                if(!$A.util.isEmpty(responsiblePartiesAddressList)){
                    for(var i=0;i<responsiblePartiesAddressList.length;i++){
                        responsiblePartiesAddressList[i].ADR_LINE_1__c = objectData.adjustment.IDN_PROVR__r.ADR_LINE1_MLNG__c;
                        //address.ADR_LINE_2__c = objectData.adjustment.IDN_PROVR__r.ADR_LINE1__c;
                        responsiblePartiesAddressList[i].ADR_CITY__c = objectData.adjustment.IDN_PROVR__r.ADR_CITY_MLNG__c;
                        responsiblePartiesAddressList[i].ADR_STATE__c = objectData.adjustment.IDN_PROVR__r.ADR_STATE_MLNG__c;
                        responsiblePartiesAddressList[i].ADR_ZIP_MAIN__c = objectData.adjustment.IDN_PROVR__r.ADR_ZIP_MLNG__c;
                    }
                }
            }
            address.IDN_ADJMT__c = component.get("v.recordId");
        }
        component.set("v.address",address);
    },
    
    setAdjustmentReasonOptions : function(component,objectData){
        if(objectData.adjustment){
            var adjustmentReasonOptions = [{'value':null,'label':'--None--','selected':false}];
            if(!$A.util.isEmpty(objectData.adjustment.CDE_REASON__c)){
                var reason = objectData.adjustment.CDE_REASON__c;
                if(objectData.adjustment.IDN_PROVR__c && objectData.adjustment.IDN_PROVR__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Claim'){
                    adjustmentReasonOptions.push({'value':'24','label':'Care provided-not paid automatically','selected':objectData.adjustment.CDE_REASON__c=='Care provided-not paid automatically'?true:false});
                    adjustmentReasonOptions.push({'value':'25','label':'Care provided-payment rate type change','selected':objectData.adjustment.CDE_REASON__c=='Care provided-payment rate type change'?true:false});
                    adjustmentReasonOptions.push({'value':'26','label':'ART Fees','selected':objectData.adjustment.CDE_REASON__c=='ART Fees'?true:false});
                    adjustmentReasonOptions.push({'value':'28','label':'Care paid at incorrect rate/rate type','selected':objectData.adjustment.CDE_REASON__c=='Care paid at incorrect rate/rate type'?true:false});
                    adjustmentReasonOptions.push({'value':'31','label':'Parent fee adjustment','selected':objectData.adjustment.CDE_REASON__c=='Parent fee adjustment'?true:false});
                }else if(objectData.adjustment.IDN_PROVR__c && objectData.adjustment.IDN_PROVR__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Recovery'){
                    // if(reason.includes('Fraud (Refer To Court Decision Or Consent Agreement)')){
                    adjustmentReasonOptions.push({'value':'14','label':'Fraud (Refer To Court Decision Or Consent Agreement)','selected':objectData.adjustment.CDE_REASON__c=='Fraud (Refer To Court Decision Or Consent Agreement)'?true:false});
                    // }
                    if(reason.includes('Tax Intercept')){
                        adjustmentReasonOptions.push({'value':'21','label':'Tax Intercept','selected':objectData.adjustment.CDE_REASON__c=='Tax Intercept'?true:false});
                    }
                    adjustmentReasonOptions.push({'value':'25','label':'Care provided-payment rate type change','selected':objectData.adjustment.CDE_REASON__c=='Care provided-payment rate type change'?true:false});
                    adjustmentReasonOptions.push({'value':'26','label':'ART Fees','selected':objectData.adjustment.CDE_REASON__c=='ART Fees'?true:false});
                    adjustmentReasonOptions.push({'value':'27','label':'Care Not Provided','selected':objectData.adjustment.CDE_REASON__c=='Care Not Provided'?true:false});
                    adjustmentReasonOptions.push({'value':'28','label':'Care paid at incorrect rate/rate type','selected':objectData.adjustment.CDE_REASON__c=='Care paid at incorrect rate/rate type'?true:false});
                    adjustmentReasonOptions.push({'value':'30','label':'License Closed/Suspended','selected':objectData.adjustment.CDE_REASON__c=='License Closed/Suspended'?true:false});
                    adjustmentReasonOptions.push({'value':'31','label':'Parent fee adjustment','selected':objectData.adjustment.CDE_REASON__c=='Parent fee adjustment'?true:false});
                }else if(objectData.adjustment.IDN_CASE__c && objectData.adjustment.IDN_CASE__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Recovery'){
                    adjustmentReasonOptions.push({'value':'1','label':'Household Ineligible Due to Income Exceeding 85% SMI','selected':objectData.adjustment.CDE_REASON__c=='Household Ineligible Due to Income Exceeding 85% SMI'?true:false});
                    if(reason.includes('Incorrectly Reported Household Composition')){
                        adjustmentReasonOptions.push({'value':'7','label':'Incorrectly Reported Household Composition','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Household Composition'?true:false});
                    }
                    if(reason.includes('Incorrectly Reported Earned Income')){
                        adjustmentReasonOptions.push({'value':'8','label':'Incorrectly Reported Earned Income','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Earned Income'?true:false});
                    }
                    console.log('objectData.adjustment.CDE_REASON__c-----'+objectData.adjustment.CDE_REASON__c);
                    if(reason.includes('Incorrectly Reported Unearned Income')){
                        adjustmentReasonOptions.push({'value':'9','label':'Incorrectly Reported Unearned Income','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Unearned Income'?true:false});
                    }
                    adjustmentReasonOptions.push({'value':'10','label':'Interim Benefits Were Issued While Awaiting A Hearing','selected':objectData.adjustment.CDE_REASON__c=='Interim Benefits Were Issued While Awaiting A Hearing'?true:false});
                    if(reason.includes('Other Household Error')){
                        adjustmentReasonOptions.push({'value':'11','label':'Other Household Error','selected':objectData.adjustment.CDE_REASON__c=='Other Household Error'?true:false});
                    }
                    adjustmentReasonOptions.push({'value':'13','label':'Intentional Program Violation/Fraud','selected':objectData.adjustment.CDE_REASON__c=='Intentional Program Violation/Fraud'?true:false});
                    if(reason.includes('Fraud (Refer To Court Decision Or Consent Agreement)')){
                        adjustmentReasonOptions.push({'value':'14','label':'Fraud (Refer To Court Decision Or Consent Agreement)','selected':objectData.adjustment.CDE_REASON__c=='Fraud (Refer To Court Decision Or Consent Agreement)'?true:false});
                    }
                    if(reason.includes('Client Recovery/Parental Fee')){
                        adjustmentReasonOptions.push({'value':'15','label':'Client Recovery/Parental Fee','selected':objectData.adjustment.CDE_REASON__c=='Client Recovery/Parental Fee'?true:false});
                    }
                    if(reason.includes('Tax Intercept')){
                        adjustmentReasonOptions.push({'value':'21','label':'Tax Intercept','selected':objectData.adjustment.CDE_REASON__c=='Tax Intercept'?true:false});
                    }
                    adjustmentReasonOptions.push({'value':'22','label':'Client Failed to accurately report Eligible Activity','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report Eligible Activity'?true:false});
                    adjustmentReasonOptions.push({'value':'32','label':'Client Failed to accurately report HH comp','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report HH comp'?true:false});
                    adjustmentReasonOptions.push({'value':'33','label':'Client Failed to accurately report income','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report income'?true:false});
                    adjustmentReasonOptions.push({'value':'34','label':'Client Failed to accurately report residency','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report residency'?true:false});
                    adjustmentReasonOptions.push({'value':'35','label':'Client falsely reported expenses','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported expenses'?true:false});
                    adjustmentReasonOptions.push({'value':'36','label':'Client falsely reported income','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported income'?true:false});
                    adjustmentReasonOptions.push({'value':'37','label':'Client falsely reported eligibility information','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported eligibility information'?true:false});
                } 
            }else{
                if(objectData.adjustment.IDN_PROVR__c && objectData.adjustment.IDN_PROVR__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Claim'){
                    adjustmentReasonOptions.push({'value':'24','label':'Care provided-not paid automatically','selected':objectData.adjustment.CDE_REASON__c=='Care provided-not paid automatically'?true:false});
                    adjustmentReasonOptions.push({'value':'25','label':'Care provided-payment rate type change','selected':objectData.adjustment.CDE_REASON__c=='Care provided-payment rate type change'?true:false});
                    adjustmentReasonOptions.push({'value':'26','label':'ART Fees','selected':objectData.adjustment.CDE_REASON__c=='ART Fees'?true:false});
                    adjustmentReasonOptions.push({'value':'28','label':'Care paid at incorrect rate/rate type','selected':objectData.adjustment.CDE_REASON__c=='Care paid at incorrect rate/rate type'?true:false});
                    adjustmentReasonOptions.push({'value':'31','label':'Parent fee adjustment','selected':objectData.adjustment.CDE_REASON__c=='Parent fee adjustment'?true:false});
                }else if(objectData.adjustment.IDN_PROVR__c && objectData.adjustment.IDN_PROVR__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Recovery'){
                    adjustmentReasonOptions.push({'value':'14','label':'Fraud (Refer To Court Decision Or Consent Agreement)','selected':objectData.adjustment.CDE_REASON__c=='Fraud (Refer To Court Decision Or Consent Agreement)'?true:false});
                    //adjustmentReasonOptions.push({'value':'21','label':'Tax Intercept','selected':objectData.adjustment.CDE_REASON__c=='Tax Intercept'?true:false});
                    adjustmentReasonOptions.push({'value':'25','label':'Care provided-payment rate type change','selected':objectData.adjustment.CDE_REASON__c=='Care provided-payment rate type change'?true:false});
                    adjustmentReasonOptions.push({'value':'26','label':'ART Fees','selected':objectData.adjustment.CDE_REASON__c=='ART Fees'?true:false});
                    adjustmentReasonOptions.push({'value':'27','label':'Care Not Provided','selected':objectData.adjustment.CDE_REASON__c=='Care Not Provided'?true:false});
                    adjustmentReasonOptions.push({'value':'28','label':'Care paid at incorrect rate/rate type','selected':objectData.adjustment.CDE_REASON__c=='Care paid at incorrect rate/rate type'?true:false});
                    adjustmentReasonOptions.push({'value':'30','label':'License Closed/Suspended','selected':objectData.adjustment.CDE_REASON__c=='License Closed/Suspended'?true:false});
                    adjustmentReasonOptions.push({'value':'31','label':'Parent fee adjustment','selected':objectData.adjustment.CDE_REASON__c=='Parent fee adjustment'?true:false});
                }else if(objectData.adjustment.IDN_CASE__c && objectData.adjustment.IDN_CASE__c!=null && objectData.adjustment.CDE_TYPE_ADJMT__c=='Recovery'){
                    adjustmentReasonOptions.push({'value':'1','label':'Household Ineligible Due to Income Exceeding 85% SMI','selected':objectData.adjustment.CDE_REASON__c=='Household Ineligible Due to Income Exceeding 85% SMI'?true:false});
                    //adjustmentReasonOptions.push({'value':'7','label':'Incorrectly Reported Household Composition','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Household Composition'?true:false});
                    //adjustmentReasonOptions.push({'value':'8','label':'Incorrectly Reported Earned Income','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Earned Income'?true:false});
                    // adjustmentReasonOptions.push({'value':'9','label':'Incorrectly Reported Unearned Income','selected':objectData.adjustment.CDE_REASON__c=='Incorrectly Reported Unearned Income'?true:false});
                    adjustmentReasonOptions.push({'value':'10','label':'Interim Benefits Were Issued While Awaiting A Hearing','selected':objectData.adjustment.CDE_REASON__c=='Interim Benefits Were Issued While Awaiting A Hearing'?true:false});
                    //adjustmentReasonOptions.push({'value':'11','label':'Other Household Error','selected':objectData.adjustment.CDE_REASON__c=='Other Household Error'?true:false});
                    adjustmentReasonOptions.push({'value':'13','label':'Intentional Program Violation/Fraud','selected':objectData.adjustment.CDE_REASON__c=='Intentional Program Violation/Fraud'?true:false});
                    //adjustmentReasonOptions.push({'value':'14','label':'Fraud (Refer To Court Decision Or Consent Agreement)','selected':objectData.adjustment.CDE_REASON__c=='Fraud (Refer To Court Decision Or Consent Agreement)'?true:false});
                    //adjustmentReasonOptions.push({'value':'15','label':'Client Recovery/Parental Fee','selected':objectData.adjustment.CDE_REASON__c=='Client Recovery/Parental Fee'?true:false});
                    //adjustmentReasonOptions.push({'value':'21','label':'Tax Intercept','selected':objectData.adjustment.CDE_REASON__c=='Tax Intercept'?true:false});
                    adjustmentReasonOptions.push({'value':'22','label':'Client Failed to accurately report Eligible Activity','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report Eligible Activity'?true:false});
                    adjustmentReasonOptions.push({'value':'32','label':'Client Failed to accurately report HH comp','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report HH comp'?true:false});
                    adjustmentReasonOptions.push({'value':'33','label':'Client Failed to accurately report income','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report income'?true:false});
                    adjustmentReasonOptions.push({'value':'34','label':'Client Failed to accurately report residency','selected':objectData.adjustment.CDE_REASON__c=='Client Failed to accurately report residency'?true:false});
                    adjustmentReasonOptions.push({'value':'35','label':'Client falsely reported expenses','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported expenses'?true:false});
                    adjustmentReasonOptions.push({'value':'36','label':'Client falsely reported income','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported income'?true:false});
                    adjustmentReasonOptions.push({'value':'37','label':'Client falsely reported eligibility information','selected':objectData.adjustment.CDE_REASON__c=='Client falsely reported eligibility information'?true:false});
                } 
            }
            component.set("v.adjustmentReasonOptions",adjustmentReasonOptions);
            adjustmentReasonOptions.forEach(function(adjustmentReasonOption){
                if(adjustmentReasonOption.selected==true){
                    //  component.set("v.adjustment.CDE_REASON__c",adjustmentReasonOption.value);
                }
            });
        }
    },
    
    getReasonPicklistToLabel : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var adjustment = component.get("v.adjustment");
        var adjustmentReasonOptions = component.get("v.adjustmentReasonOptions");
        if(adjustment){
            if(adjustmentReasonOptions){
                var selectedLabel = '';
                adjustmentReasonOptions.forEach(function(adjustmentReasonOption){
                    if(adjustmentReasonOption.selected==true){
                        selectedLabel = selectedLabel+adjustmentReasonOption.label+';'
                        console.log('selectedLabel--'+selectedLabel)
                    }
                });
                if(!$A.util.isEmpty(selectedLabel)){
                    component.set("v.adjustment.CDE_REASON__c",selectedLabel);   
                }
            }
        }
    },
    
    setResponsibleParties : function(component,objectData){
        var adjustment = component.get("v.adjustment");
        if(objectData.responsibleParties){
            component.set("v.responsibleParties",objectData.responsibleParties);
        }
        if(objectData.responsiblePartyList){
            component.set("v.responsiblePartyList",objectData.responsiblePartyList);
        }
        var selectedResponsibleParties = [];
        if(objectData.adjustment.Adjustent5__r){
            // var responsiblePartyList = [];//component.get("v.responsiblePartyList");
            objectData.adjustment.Adjustent5__r.forEach(function(existingResponsibleParty){
                var responsiblePartyObj = component.get("v.responsiblePartyObj");
                console.log('existingResponsibleParty--'+JSON.stringify(existingResponsibleParty));
                if(component.get("v.pageMode")=='view' && (!$A.util.isEmpty(existingResponsibleParty.IDN_CLIENT__c))){
                    responsiblePartyObj.IDN_CLIENT__c =existingResponsibleParty.IDN_CLIENT__c;
                    responsiblePartyObj.IDN_ADJMT__c =adjustment.Id;
                    responsiblePartyObj.Responsible_Party_Name__c =existingResponsibleParty.IDN_CLIENT__r.NAM_LAST__c+', '+existingResponsibleParty.IDN_CLIENT__r.NAM_FIRST__c;
                    selectedResponsibleParties.push(existingResponsibleParty.IDN_CLIENT__r.NAM_LAST__c+', '+existingResponsibleParty.IDN_CLIENT__r.NAM_FIRST__c);
                } else {
                    responsiblePartyObj.IDN_CLIENT__c =existingResponsibleParty.IDN_CLIENT__c;
                    responsiblePartyObj.IDN_ADJMT__c =adjustment.Id;
                    responsiblePartyObj.Responsible_Party_Name__c =existingResponsibleParty.IDN_CLIENT__r.NAM_LAST__c+', '+existingResponsibleParty.IDN_CLIENT__r.NAM_FIRST__c;
                    selectedResponsibleParties.push(existingResponsibleParty.IDN_CLIENT__c);
                }
                //responsiblePartyList.push(existingResponsibleParty);
            });
            //component.set("v.responsiblePartyList",responsiblePartyList);
            component.set("v.selectedResponsibleParties",selectedResponsibleParties);
        }
    },
    
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        if(modalCall){
            modalCall.openModal();
        } else {
            this.redirectToRecord(cmp.get("v.recordId"));
        }
    },
    
    decrementCurrentTabNumber : function(cmp){
        cmp.set("v.currentTabNumber",cmp.get("v.currentTabNumber")-1);
    },
    
    updateOrNewRec : function(component) {
        var childCmp = component.find("adjustmentFlow_AdjustmentEntry_NonSub");
        var inputCmp =childCmp;
        if(component.get("v.adjustmentEntryEditMode")==true) {
            var objToUpdate = childCmp.get("v.nonAdjustmentDetail");
            objToUpdate.IDN_AUTH__c = inputCmp.get("v.authId");
            objToUpdate.AMT_DETAIL_ADJMT__c = inputCmp.get("v.AMT_DETAIL_ADJMT__c");
            objToUpdate.IDN_PROG_FNDG__c = inputCmp.get("v.authorizationAssocFundingProg");
            this.callServerAndHandleError(component,"c.upsertRecords", function(response){
                component.set("v.adjustmentEntryEditMode", false);
                var nonAdjustmentDetail = component.get("v.nonAdjustmentDetailObj");
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                component.set("v.closeConfirmModal",true);
            },{'lstSObject':[objToUpdate]}, false, null);
        } else{
            var nonAdjustmentDetail = {'sobjectType':'T_NON_ADJMT_DETAIL__c',
                                       'IDN_AUTH__c':inputCmp.get("v.authId"),
                                       'AMT_DETAIL_ADJMT__c':inputCmp.get("v.AMT_DETAIL_ADJMT__c"),
                                       'IDN_PROG_FNDG__c':inputCmp.get("v.authorizationAssocFundingProg"),
                                       'IDN_ADJMT__c':component.get("v.recordId")};
            this.callServerAndHandleError(component,"c.upsertRecords", function(response){
                var nonAdjustmentDetail = [];
                if(component.get("v.nonAdjustmentDetailObj")) {
                    nonAdjustmentDetail = component.get("v.nonAdjustmentDetailObj");
                }
                nonAdjustmentDetail.push(response.objectData.upsertedRecords[0]);
                component.set("v.nonAdjustmentDetailObj",nonAdjustmentDetail);    
                component.set("v.authId","");  
                component.set("v.authorizationAssocIndiv",""); 
                component.set("v.authorizationObj",{}); 
                var inputCmp = component.find("adjustmentFlow_AdjustmentEntry_NonSub");
                inputCmp.set("v.authorizationAssocFundingProg","");  
                inputCmp.set("v.AMT_DETAIL_ADJMT__c",0);
                //component.set("v.closeConfirmModal",true);
                var confirmationModalOnNewNonDetail = component.find("confirmationModalOnNewNonDetail");
                confirmationModalOnNewNonDetail.hideConfirmModal();
                if(component.get("v.doNextIncrement")) {
                    component.set("v.doNextIncrement", false);
                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                }
                // compEvent.fire();
            },{'lstSObject':[nonAdjustmentDetail]}, false, null);
        }
    },
    
    openModalforAdjustmentNote : function(component) {
        var modalBody;
        var componentName = "c:adjustmentNoteOverride";
        var params = {"recordId": component.get("v.recordId"), "fromAdjustmentFlow": true};
        var modalHeader="Adjustment Note";
        if(componentName){
            $A.createComponent(componentName, params,
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       component.find('modalOverlay').showCustomModal({
                                           header: modalHeader,
                                           body: modalBody,
                                           showCloseButton: true,
                                           cssClass: "slds-modal_large"
                                       })
                                   }
                               });
        }
    },
    
    closeModal : function(component,event,helper){
        component.find("modalOverlay").notifyClose();
        component.find("overlayLib").notifyClose();
        component.find('confirmationModalAdjNotes').hideConfirmModal();
    }
})