import { LightningElement, api, track } from 'lwc';

export default class RecurrencePattenPg1_lwc extends LightningElement {
    @track _authSchRecurrObj = {
        sobjectType: 'Auth_Schedule_Recurrence__c',
        IDN_AUTH__c: '',
        DTE_Begin_Date__c: '',
        DTE_End_Date__c: '',
        Fri__c: '',
        Mon__c: '',
        RecurDay__c: '',
        RecurDays__c: '',
        Recur_Type__c: '',
        Sat__c: '',
        Sun__c: '',
        Thur__c: '',
        Wed__c: '',
        WeekDays__c: '',
        Name: '',
        Tue__c: '',
        DaysOfMonth__c: ''
    };
    @track selectedLookUpRecord = {};
    @track loggedInUserId = '';
    @track message = '';
    @track recordError = [];
    @track sObjectName = '';
    @track loggedUserName = '';
    @track oneTimeDateLoadValidatity = true;
    @track options = [];
    @track fieldValue = '';
    @track initDataLoaded = false;

    @api recordId;
    @api authEndDate;
    @api fieldValidationErrors = [];
    @api isCurrentPageValid = false;
    @api isValid = false;

    @api
    get authSchRecurrObj() {
        return this._authSchRecurrObj;
    }

    set authSchRecurrObj(value) {
        this._authSchRecurrObj = { ...value };
    }

    @api
    get authSchRecurrObjProp() {
        return this._authSchRecurrObj;
    }

    set authSchRecurrObjProp(value) {
        this._authSchRecurrObj = { ...value };
    }

    @api
    callValidateCurrentPage() {
        const isValid = this.checkCustomValidations();
        this.dispatchEvent(new CustomEvent('validatepage', {
            detail: { isValid: isValid }
        }));
        return isValid;
    }

    connectedCallback() {
    }

    handleEndDateChange(event) {
        const endDateInput = this.template.querySelector('[data-field="endDate"]');
                if (endDateInput) {
                    endDateInput.setCustomValidity('');
                    endDateInput.reportValidity();
                }
        const endDate = event.target.value;
        this.authSchRecurrObj = {
            ...this.authSchRecurrObj,
            DTE_End_Date__c: endDate
        };
        this.dispatchEvent(new CustomEvent('recorderror', {
            detail: {
                recordError: this.recordError,
                message: this.message
            },
        }));
    }

    checkCustomValidations() {
        const scheduleRecurrObj = this.authSchRecurrObj;
        let isValid = false;
        
        const todayDate = new Date();
        const todayDateUTC = this.getDateInUTC(todayDate);
        const todayDateMinus9Days = new Date(todayDateUTC);
        todayDateMinus9Days.setDate(todayDateMinus9Days.getDate() - 9);
        
        const endDateInput = this.template.querySelector('[data-field="endDate"]');
        const endDate = endDateInput ? endDateInput.value : null;
                
        if (endDate) {
            const endDate1 = this.getDateInUTC(new Date(endDate));
            const authEndDate = new Date(this.authEndDate);
            if (endDate1 > authEndDate) {
                const formattedAuthEndDate = this.padNumber(authEndDate.getMonth() + 1) + '/' + 
                                           this.padNumber(authEndDate.getDate()) + '/' + 
                                           authEndDate.getFullYear();
                const endMsg = "End date cannot be greater than authorization end date, " + formattedAuthEndDate;
                
                if (endDateInput) {
                    endDateInput.setCustomValidity(endMsg);
                    endDateInput.reportValidity();
                }
                isValid = false;
            } else {
                if (endDateInput) {
                    endDateInput.setCustomValidity('');
                    endDateInput.reportValidity();
                }
                isValid = true;
            }
        }else{
            isValid = false;
        }
        
        this.isValid = isValid;
        return isValid;
    }

    getDateInUTC(date) {
        const dateObj = new Date(date);
        return new Date(dateObj.getUTCFullYear(), dateObj.getUTCMonth(), dateObj.getUTCDate());
    }

    padNumber(number) {
        let string = '' + number;
        string = string.length < 2 ? '0' + string : string;
        return string;
    }

    handleFieldLevelValidation() {
        // Handle field level validation if needed
    }
}