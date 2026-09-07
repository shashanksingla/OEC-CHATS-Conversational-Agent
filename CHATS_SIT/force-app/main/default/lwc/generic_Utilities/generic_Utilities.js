import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import delegateConRequest from '@salesforce/apexContinuation/RequestController.delegateConRequest';
import delegateRequest from '@salesforce/apex/RequestController.delegateRequest';
import { RefreshEvent } from 'lightning/refresh';

export const helper = {
    /** -------------functions extracted from genericUtilities.js(Aura)  START ----------------*/
    callServer(cmp, className, methodName, callback, params) {
        cmp.showSpinner = true;
        delegateRequest({
            className: className, methodName: methodName, jsonParam: params
        }).then((result) => {
            cmp.showSpinner = false;
            callback.call(this, JSON.parse(result));
        }).catch((error) => {
            this.handleError(error, cmp);
        })
    },
    callConServer(cmp, className, methodName, callback, params) {
        cmp.showSpinner = true;
        delegateConRequest({
            className: className, methodName: methodName, jsonParam: params
        }).then((result) => {
            cmp.showSpinner = false;
            callback.call(this, JSON.parse(result));
        }).catch((error) => {
            this.handleError(error, cmp);
        })
    },
    handleError(error, cmp) {
        var errormsg = "";
        if (error && error.body) {
            errormsg = error.body.message;
        }
        cmp.error = errormsg;
        if (errormsg) {
            this.showToast(cmp, 'Error!', errormsg, 'error', 'dismissible');
        }
        cmp.showSpinner = false;
        cmp.error = errormsg;
        
        cmp.showSpinner = false;
    },
    merge(obj1, obj2) {
        var obj3 = {};
        for (var attrname in obj1) { obj3[attrname] = obj1[attrname]; }
        for (var attrname in obj2) { obj3[attrname] = obj2[attrname]; }
        return obj3;
    },
    getCurrentSystemDate(addDays, addMonths, addYears) {

        var today = new Date();
        var dd = addDays ? today.getDate() + addDays : today.getDate();
        var MM = addMonths ? today.getMonth() + 1 + addMonths : today.getMonth() + 1;
        var yyyy = addYears ? today.getFullYear() + addYears : today.getFullYear();
        if (dd < 10) {
            dd = '0' + dd;
        }
        if (MM < 10) {
            MM = '0' + MM;
        }
        return yyyy + '-' + MM + '-' + dd;
    },
    handleDate(dateValue, addDays, addMonths, addYears) {
        var dd = addDays ? dateValue.getDate() + addDays : dateValue.getDate();
        var MM = addMonths ? dateValue.getMonth() + 1 + addMonths : dateValue.getMonth() + 1;
        var yyyy = addYears ? dateValue.getFullYear() + addYears : dateValue.getFullYear();
        if (dd < 10) {
            dd = '0' + dd;
        }
        if (MM < 10) {
            MM = '0' + MM;
        }
        return yyyy + '-' + MM + '-' + dd;
    },
    redirectToLightningComponent(cmp, componentName, params) {
        cmp[NavigationMixin.Navigate]({
            "type": "standard__component",
            "attributes": {
                "componentName": componentName,
                "componentAttributes": params
            }
        }).then(() => {
            this.dispatchEvent(new RefreshEvent());
        });
    },    
    redirectToCustomTab(cmp,customTabName){
        cmp[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: customTabName
            },
        }).then(() => {
            this.dispatchEvent(new RefreshEvent());
        });
    },
    redirectToRecord(cmp, recordId) {
        // Force a full page reload to destroy the current component instance
        window.location.href = '/' + recordId;
    },
    navigateToRecord(cmp,recordId){
        cmp[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view',
                },
            }).then((url) => {
                window.location.href = url;
                this.dispatchEvent(new RefreshEvent());
            });
    },
    getDateInUTC(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    leapYear(year) {
        return (year % 100 === 0) ? (year % 400 === 0) : (year % 4 === 0);
    },
    /** -------------functions extracted from genericUtilities.js(Aura)  END ----------------*/
    showToast(cmp, title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title || getTitle(variant),
            message: message,
            variant: variant,
            mode: mode ? mode : variant == "error" ? "sticky" : "dismissible",
        });
        cmp.dispatchEvent(event);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function (x) { return primer(x[field]) } :
            function (x) { return x[field] };
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
}
function getTitle(type) {
    switch (type) {
        case 'error':
            return 'Error!';
            break;
        case 'success':
            return 'Success!';
            break;
        case 'warning':
            return 'Warning!';
    }
}