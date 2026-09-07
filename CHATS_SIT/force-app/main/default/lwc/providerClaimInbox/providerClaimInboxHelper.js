export const claimHelper = {
    checkCustomValidations(cmp) {
        var isValid = true;
        var currentDate = new Date();
        var cmpFromDate = cmp.claimInboxWrapper.fromDate;
        var fromDate;
        var cmpToDate = cmp.claimInboxWrapper.toDate;
        var toDate;
        if (cmpFromDate != null) {
            fromDate = new Date(cmp.claimInboxWrapper.fromDate);
            // eslint-disable-next-line vars-on-top
            var earlierToDate = new Date(fromDate.getFullYear(), fromDate.getMonth(), fromDate.getDate() + 31);
        }
        if (cmpToDate != null) {
            toDate = new Date(cmp.claimInboxWrapper.toDate);
        }
        // eslint-disable-next-line vars-on-top
        var earlierFromDate = new Date(currentDate.getFullYear() - 4, currentDate.getMonth(), currentDate.getDate());
        let fromDateCmp = cmp.template.querySelector('[data-id="fromDate"]');
        let toDateCmp = cmp.template.querySelector('[data-id="toDate"]');
        if (fromDateCmp) {
            if ((fromDate != null || fromDate != undefined || fromDate != '') && fromDate > currentDate) {
                fromDateCmp.message = ' Claim Submitted Begin Date should be less than today.';
                isValid = false;
            } else if ((fromDate != null || fromDate != undefined || fromDate != '') && fromDate < earlierFromDate) {
                fromDateCmp.message = ' Claim Submitted Begin Date cannot be earlier than 4 years.';
                isValid = false;
            } else {
                fromDateCmp.message = '';
            }
        }
        if (toDateCmp) {
            if ((toDate != null || toDate != undefined || toDate != '') && toDate > currentDate) {
                toDateCmp.message = 'Claim Submitted End Date should be less than today.';
                isValid = false;
            } else if ((toDate != null || toDate != undefined || toDate != '') && toDate < fromDate) {
                toDateCmp.message = 'Claim Submitted End Date cannot be less than Claim Submitted Begin Date.';
                isValid = false;
            } else if ((toDate != null || toDate != undefined || toDate != '') && toDate > earlierToDate) {
                toDateCmp.message = 'Claim Submitted End Date cannot be more than 1 Month after Claim Submitted Begin Date.';
                isValid = false;
            } else {
                toDateCmp.message = '';
            }
        }
        return isValid;
    },
    showHideMonths(cmp) {
        let hideM = [];
        var currentTime = new Date()
        var currentMonth = currentTime.getMonth();
        let currentYear = currentTime.getFullYear();
        if (cmp.claimInboxWrapper.careYear == currentYear) {
            let i = 12;
            while (i > currentMonth + 1) {
                if (i == cmp.claimInboxWrapper.careMonth) {
                    cmp.claimInboxWrapper.careMonth = undefined;
                }
                hideM.push(i.toString());
                i--;
            }
        }
        cmp.hiddenMonths = hideM;
    },
    handleValueUpdates(cmp, fieldName, detail) {
        let resetMonths = false;
        let claimWrap = JSON.parse(JSON.stringify(cmp.claimInboxWrapper));
        let payload = (detail || {}).payload;
        let selValue = (detail || {}).value; // standard component value
        let customEventValue = (payload || {}).value; // custom event value
        if (fieldName == 'fromDate') {
            claimWrap.fromDate = selValue;
        } else if (fieldName == 'toDate') {
            claimWrap.toDate = selValue;
        } else if (fieldName == 'radioButtonGroup') {
            claimWrap.searchType = selValue;
        } else if (fieldName == 'providerName') {
            claimWrap.providerName = selValue;
            let searchCmp = cmp.template.querySelector(".providerId");
            if (searchCmp) {
                if (selValue.length > 0) {
                    searchCmp.disabled = true;
                } else {
                    searchCmp.disabled = false;
                }
                searchCmp.clearSelectedValue();
            }
        } else if (fieldName == 'T_CHATS_PROVR_STATUS__c-Name') {
            claimWrap.providerId = detail.record.Id;
            claimWrap.providerName = undefined;
        } else if (fieldName == 'User_Owner_County__c') {
            let countyVal = '';
            if (customEventValue) {
                countyVal = customEventValue.replace(";;", ";");
            }
            claimWrap.county = countyVal;
        } else if (fieldName == 'Provider_Manual_Claim__c_Claim_Status__c') {
            let statusVal = '';
            if (customEventValue) {
                statusVal = customEventValue.replace(";;", ";");
            }
            claimWrap.status = statusVal;
        } else if (fieldName == 'Provider_Manual_Claim__c_Care_Month__c') {
            claimWrap.careMonth = customEventValue;
        } else if (fieldName == 'Provider_Manual_Claim__c_Care_Year__c') {
            claimWrap.careYear = customEventValue;
            resetMonths = true;
        }
        cmp.claimInboxWrapper = claimWrap;
        if (resetMonths) {
            this.showHideMonths(cmp);
        }
        cmp.claimResultWrapper = undefined;
    },
    updatePagination(cmp) {
        let paginationList = [];
        let pageSize = cmp.pageSize;

        // Slice the sorted dataset for the current page
        paginationList = cmp.FinalList.slice(cmp.start, cmp.start + pageSize);

        cmp.claimResultWrapper = paginationList;
    }
}