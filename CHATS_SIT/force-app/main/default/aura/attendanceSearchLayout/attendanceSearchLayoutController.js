({
    fetchResults : function(component, event, helper) {
        debugger;
        var childCmp = component.find("AttendanceSearchScreen");
        childCmp.callValidateCurrentPage();
        console.log(component.get("v.isCurrentPageValid"));
        component.set("v.searchResults1",{});
        component.set("v.searchResults2",{});
        if(component.get("v.isCurrentPageValid")){
            var providerRec= component.get("v.providerRec");
            var caseRec= component.get("v.caseRec");
            var individualRec= component.get("v.individualRec");
            var providerNameId='';
            var caseNameId='';
            var stateId='';
            if(providerRec!=null){
             providerNameId= providerRec.Name;
            }
            if(caseRec!=null){
             caseNameId= caseRec.Name;
            }
            if(individualRec!=null){
             stateId= individualRec.IDN_STATE__c;
            }
            helper.callServerAndHandleError(component,"c.getAttendanceResults", 
                                            function(response){
                                                debugger;
                                                console.log(response);
                                                var lstTransaction1 = response.objectData.lstTransaction1;
                                                var lstTransaction2 = response.objectData.lstTransaction2;
                                                var transactionTypeMap = response.objectData.transactionTypeMap;
                                                var transactionStatusMap = response.objectData.transactionStatusMap;
                                                if(!$A.util.isEmpty(lstTransaction1)){
                                                for(var i=0;i<lstTransaction1.length;i++){
                                                    lstTransaction1[i].Reporting_Transaction_Type_c__c = transactionTypeMap[lstTransaction1[i].Reporting_Transaction_Type_c__c];
                                                    lstTransaction1[i].Reporting_Transaction_Result_c__c = transactionStatusMap[lstTransaction1[i].Reporting_Transaction_Result_c__c];
                                                }
                                                     component.set("v.searchResults1",lstTransaction1);
                                                }
                                                if(!$A.util.isEmpty(lstTransaction2)){
                                                for(var i=0;i<lstTransaction2.length;i++){
                                                   lstTransaction2[i].reporting_Transaction_Type__c = transactionTypeMap[lstTransaction2[i].reporting_Transaction_Type__c];
                                                   lstTransaction2[i].reporting_Transaction_Result__c = transactionStatusMap[lstTransaction2[i].reporting_Transaction_Result__c];
                                                }
                                                     component.set("v.searchResults2",lstTransaction2);
                                                }   
                                               
                                               
                                                
                                            }, {'providerId':providerNameId,
                                                'caseId':caseNameId,
                                                'stateId':stateId,
                                                'fromDate':component.get("v.beginDate"),
                                                'toDate': component.get("v.endDate")}, false, null);
        }
    }
})