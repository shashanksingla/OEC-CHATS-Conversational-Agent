({
    doSearch : function(component, event, helper) {
        var paymentId = component.get("v.paymentId");
        var providerId = component.get("v.providerId");
        var caseId = component.get("v.caseId");
        var stateId = component.get("v.stateId");
        if($A.util.isEmpty(paymentId) && $A.util.isEmpty(providerId) && $A.util.isEmpty(caseId) && $A.util.isEmpty(stateId)){
            component.set("v.isCurrentPageValid", false);
            component.set("v.hasSearched",false);
            component.set("v.messageType", "Error");
            component.set("v.pageMessages", "At least one of the fields marked as required must be entered");
        }
        else{
            component.set("v.isCurrentPageValid", true);
            helper.callServerAndHandleError(component,"c.doSearchSubPayment", function(response){
                
                var searchResults = response.objectData.SubpaymentSearchResults, temp={};
                if(!$A.util.isEmpty(searchResults)){
                    if(!$A.util.isEmpty(response.objectData.showAuthRecordsWarning)){
                        component.set("v.showAuthRecordsWarning",response.objectData.showAuthRecordsWarning);
                    }
                    for(var i=0; i<searchResults.length; i++){
                        temp = searchResults[i];
                        temp.subPaymentId 		= temp.subPymtId.toString();
                        temp.paymentName 		= temp.pymtId;
                        temp.payDate 			= temp.paymentDatePaid;
                        temp.periodBeginDate 	= temp.servicePeriodBgnDte;
                        temp.periodEndDate 		= temp.servicePeriodEndDte;
                        temp.authorizationId 	= temp.authid;
                        temp.caseId 			= temp.caseId;
                        temp.firstName 			= temp.childFirstName;
                        temp.lastName 			= temp.childLastName;
                        temp.countyName 		= temp.county;
                        searchResults[i] 		= temp;
                        temp = {};
                    }
                }
                if(!$A.util.isEmpty(searchResults) && searchResults.length>200){
                    var showToast = $A.get("e.force:showToast");
                    showToast.setParams({
                        'title': 'Warning',
                        'type': 'warning',
                        'message': 'Over 200 records have been returned, please refine the search criteria.'
                    });
                    showToast.fire();
                }
                component.set("v.subPaymentSearchLst", searchResults);
                component.set("v.hasSearched",true);
            }, {'paymentId':component.get("v.paymentId"),
                'providerId' : component.get("v.providerId"),
                'caseId' : component.get("v.caseId"),
                'countyId' : component.get("v.countyId"),
                'servicePeriodId':component.get("v.servicePeriodId"),
                'stateId':component.get("v.stateId"),
                'childFirstName':component.get("v.childFirstName"),
                'childLastName':component.get("v.childLastName"),
               }, false, null);
        }
    },
    updateLookupFilter : function(component, event, helper){
        var updatedFilter = '';
        updatedFilter = 'DTE_BEGIN_EFFV__c =' + component.get("v.servicePeriodId") + ' OR ' + 
            'DTE_END_EFFV__c =' + component.get("v.servicePeriodId");
        component.set("v.servicePeriodFilter", updatedFilter);
    },
    init: function (cmp, event, helper) {
        cmp.set('v.mycolumns', [
            {label: ' ', fieldName: 'subPaymentId', type: 'url'
             , typeAttributes : {label : 'View'}},
            {label: 'Sub Payment ID', fieldName: 'subPaymentId', type: 'text', sortable: true},
            {label: 'Sub Payment Status', fieldName: 'subPymtStatus', type: 'text', sortable: true},
            {label: 'Payment ID', fieldName: 'paymentName', type: 'text', sortable: true},
            {label: 'Authorization ID', fieldName: 'authorizationId', type: 'text', sortable: true},
            {label: 'Case ID', fieldName: 'caseId', type: 'text', sortable: true},
            {label: 'Service Period Begin Date', fieldName: 'periodBeginDate', type: 'text', sortable: true},
            {label: 'Service Period End Date', fieldName: 'periodEndDate', type: 'text', sortable: true},
            {label: 'Paid Date', fieldName: 'payDate', type: 'text', sortable: true},
            {label: 'County', fieldName: 'countyName', type: 'text', sortable: true},
            {label: 'Child First Name', fieldName: 'firstName', type: 'text', sortable: true},
            {label: 'Child Last Name', fieldName: 'lastName', type: 'text', sortable: true},
            {label: 'Total Sub Payment Rate Paid', fieldName: 'subPymtAmount', type: 'number', sortable: true},
            {label: 'Total Sub Payment Parent Fee', fieldName: 'subPymtCopayAmt', type: 'number', sortable: true},
            {label: 'Total Sub Payment Amount', fieldName: 'subPymtAmount', type: 'number', sortable: true},
        ]);
        //helper.getData(cmp);
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})