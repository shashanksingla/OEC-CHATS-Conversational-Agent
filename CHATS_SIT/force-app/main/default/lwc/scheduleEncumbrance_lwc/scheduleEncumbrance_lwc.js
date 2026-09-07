import { LightningElement, api, track } from 'lwc';
import { abs_helper } from 'c/abstract_Component';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';

export default class ScheduleEncumbranceLwc extends LightningElement {
    @track timezone = '';
    @track isModalOpen = true;
    @track isHardDelete = false;
    @track hardDeleteVal = false;
    @track showSpinner = false;
    @track weekcheck = false;
    @track selectedJobType = 'All';
    @track filterCondition = '';
    @track jobFrequency = '';
    @track objectName = '';
    @track recycleBinStorageRemaining = 0;
    @track cronExpression = '';
    @track errorMessage = '';
    @track isAuthUpdatedInCreateFlow = false;
    @track isEncumbrnceCreated = false;
    @track _scheduleRecurrObj = {
        sobjectType: 'Auth_Schedule_Recurrence__c',
        Recur_Type__c: '',
        RecurDay__c: '',
        DTE_Begin_Date__c: '',
        DTE_End_Date__c: '',
        Sun__c: '',
        Mon__c: '',
        Tue__c: '',
        Wed__c: '',
        Thur__c: '',
        Fri__c: '',
        Sat__c: '',
        WeekDays__c: '',
        DaysOfMonth__c: ''
    };
    @track time = '';
    @track minute = 0;
    @track second = 0;
    @track hours = 0;
    @track selectedRecordIds = [];
    @track isSelectedRecords = false;
    @track isModifiedAfterChange = false;
    @track columns = [];
    @track counter = 0;
    @track startDate;
    @track startMonth = '';
    @track startDateOfMonth = '';
    @track startYear = '';
    @track startday = '';
    @track endday = '';
    @track EndDate;
    @track endMonth = '';
    @track endDayOfMonth = '';
    @track endYear = '';
    @track validity = {};
    @track valid = false;
    @track showEditModal = false;
    @track recurrenceRecordId = '';
    @track selectWeek = '';
    @track dayNamesSelected = [];

    frequency = [
        { label: '-- None --', value: '', selected: true },
        { label: 'Monthly', value: 'Monthly' },
        { label: 'Daily/Weekly', value: 'Daily/Weekly' },
        { label: 'Every Other Week', value: 'Every Other Week' }
    ];

    weekDays = [
        { label: 'Sunday', value: '1' },
        { label: 'Monday', value: '2' },
        { label: 'Tuesday', value: '3' },
        { label: 'Wednesday', value: '4' },
        { label: 'Thursday', value: '5' },
        { label: 'Friday', value: '6' },
        { label: 'Saturday', value: '7' }
    ];

    dateToSelect = [
        { label: '1', value: '1' }, { label: '2', value: '2' }, { label: '3', value: '3' },
        { label: '4', value: '4' }, { label: '5', value: '5' }, { label: '6', value: '6' },
        { label: '7', value: '7' }, { label: '8', value: '8' }, { label: '9', value: '9' },
        { label: '10', value: '10' }, { label: '11', value: '11' }, { label: '12', value: '12' },
        { label: '13', value: '13' }, { label: '14', value: '14' }, { label: '15', value: '15' },
        { label: '16', value: '16' }, { label: '17', value: '17' }, { label: '18', value: '18' },
        { label: '19', value: '19' }, { label: '20', value: '20' }, { label: '21', value: '21' },
        { label: '22', value: '22' }, { label: '23', value: '23' }, { label: '24', value: '24' },
        { label: '25', value: '25' }, { label: '26', value: '26' }, { label: '27', value: '27' },
        { label: '28', value: '28' }, { label: '29', value: '29' }, { label: '30', value: '30' },
        { label: '31', value: '31' }
    ];

    @api recordId;    
    @api isCreate = false;
    @api isAuthFlowFirstTime = false;
    @api scheduleRecurr = [];
    @api authEndDate;
    @api enterRecurrence = false;
    @api isReadOnly = false;
    @api authBeginDate;

    @api
    get scheduleRecurrObj() {
        return this._scheduleRecurrObj;
    }
    set scheduleRecurrObj(value) {
        this._scheduleRecurrObj = { ...value };
    }

    connectedCallback() {
        this.doInit();
    }

    get isDailyWeeklyOrEveryOtherWeek() {
        return this.jobFrequency === 'Daily/Weekly' || this.jobFrequency === 'Every Other Week';
    }

    get isMonthly() {
        return this.jobFrequency === 'Monthly';
    }

    doInit() {
        this.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
        
        let finalCount = 0;
        for (let i = 0; i < 31; i++) {
            finalCount++;
        }
        this.counter = finalCount;

        if (!this.isReadOnly) {
            this.columns = [
                { label: 'Frequency', fieldName: 'Recur_Type__c', type: 'text' },
                { label: 'Recurrence Day', fieldName: 'DaysOfMonth__c', type: 'text', wrapText: true },
                { label: 'Days in Week', fieldName: 'WeekDays__c', type: 'text', wrapText: true },
                { label: 'Start Date', fieldName: 'DTE_Begin_Date__c', type: 'date-local', typeAttributes: { timezone: this.timezone } },
                { label: 'End Date', fieldName: 'DTE_End_Date__c', type: 'date-local', typeAttributes: { timezone: this.timezone } },
                { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }
            ];
        } else {
            this.columns = [
                { label: 'Frequency', fieldName: 'Recur_Type__c', type: 'text' },
                { label: 'Recurrence Day', fieldName: 'DaysOfMonth__c', type: 'text', wrapText: true },
                { label: 'Days in Week', fieldName: 'WeekDays__c', type: 'text', wrapText: true },
                { label: 'Start Date', fieldName: 'DTE_Begin_Date__c', type: 'date-local', typeAttributes: { timezone: this.timezone } },
                { label: 'End Date', fieldName: 'DTE_End_Date__c', type: 'date-local', typeAttributes: { timezone: this.timezone } }
            ];
        }
    }

     // CCCAP-15442
    getRowActions(row, doneCallback) {
        let actions = [];
        
        // Always allow delete
        actions.push({ label: 'Delete', name: 'delete' });
        
        let showEdit = false;
        
        if (this.isCreate) {
            if (this.isAuthFlowFirstTime) {
                showEdit = false;
            } else if (this.isAuthUpdatedInCreateFlow) {
                showEdit = false;
            } else if (!this.isAuthFlowFirstTime) {
                showEdit = row.Id ? true : false;
            }
        } else {
            showEdit = row.Id ? true : false;
        }
        
        if (showEdit) {
            actions.push({ label: 'Edit', name: 'edit' });
        }
        
        doneCallback(actions);
    }

    fireEvent() {
        this.dispatchEvent(new CustomEvent('sendrecurrence',
       { detail:{value:false}}
        ));
    }
    closeModel(){
        this.fireEvent();
    }
    doCancel() {
        this.fireEvent();
    }
    handleclose(event){
        let scheduleRecurr = [...this.scheduleRecurr]; 
        const Pg1 = this.template.querySelector('c-edit-recurrence-pattern-flow_lwc');

        if (scheduleRecurr && scheduleRecurr.length > 0) {
            for (let i = 0; i < scheduleRecurr.length; i++) {
                let obj = scheduleRecurr[i];
                if (obj.Id === this.recurrenceRecordId) {                
                    if (Pg1 && Pg1.authSchRecurrObj&&event.detail.wasSuccessful) {    
                        scheduleRecurr[i] = {
                            ...obj,
                            DTE_End_Date__c: Pg1.authSchRecurrObj.DTE_End_Date__c
                        };                    
                    }
                    break; // Exit loop once we find and update the correct record
                }
                }
            }       
        // Update the reactive property
        this.scheduleRecurr = scheduleRecurr;
        this.showEditModal = event.detail.value;       
    }

    handleInputChange(event) {
        event.stopPropagation();
        try {
            const field = event.target.dataset.field;
            const value = event.detail.value;
            if (field && value !== undefined) {
                if (field === 'Recur_Type__c') {
                    this.jobFrequency = value;
                }
                this._scheduleRecurrObj = { 
                    ...this._scheduleRecurrObj, 
                    [field]: value 
                };
                const inputField = this.template.querySelector(`[data-field="${field}"]`);
                if(inputField){
                    inputField.setCustomValidity('');
                    inputField.reportValidity();
                }
            }
        } catch (error) {
            console.error('Error in handleInputChange:', error);
            this.showToast('Error', 'An error occurred while updating the field: ' + error.message, 'error');
        }
    }

    selectWeeks(event) {
        const selectedValue = event.target.value;
        const isChecked = event.target.checked;
        
        if (isChecked) {
            if (!this.dayNamesSelected.includes(selectedValue)) {
                this.dayNamesSelected.push(selectedValue);
            }
        } else {
            this.dayNamesSelected = this.dayNamesSelected.filter(day => day !== selectedValue);
        }
    }

    selectDaysOfMonth(event) {
        const raw = event.detail?.payload?.value ?? event.target?.value ?? '';
        this._scheduleRecurrObj = {
            ...this._scheduleRecurrObj,
            DaysOfMonth__c: String(raw).replace(/^;+/, '')
        };
    }

    handleRowAction(event) {
        const rows = [...this.scheduleRecurr];
        const action = event.detail.action;
        const row = event.detail.row;
        const recId = row.Id;

        switch (action.name) {
            case 'edit':
                if (recId) {
                    this.recurrenceRecordId = recId;
                    this.showEditModal = true;
                }
                break;
            case 'delete':
                //const rowIndex = rows.indexOf(row);
                //rows.splice(rowIndex, 1);
            //CCCAP-15442    
                const rowIndex = rows.findIndex(r => r.Id === row.Id);  
                if (rowIndex !== -1) {
                    rows.splice(rowIndex, 1);
                }
                if (recId) {
                    this.deleteRecurrence(recId);
                } else {
                    this.showToast('Success!', 'Authorization Recurrence has been deleted successfully.', 'success');
                }
                this.scheduleRecurr = [...rows];
                break;
        }
    }

    deleteRecurrence(recId) {
        const params = {
            recordId: recId
        };

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'deleteSchedule', (function (response) {
            if (response && response.isSuccessful) {
                this.showToast('Success!', 'Authorization Recurrence has been deleted successfully.', 'success');
            } else {
                console.error('Error deleting recurrence:', response);
                this.showToast('Error!', 'Error deleting recurrence.', 'error');
            }
        }).bind(this), JSON.stringify(params));
    }

    doSchedule() {
        const frequencyInput = this.template.querySelector('[data-field="Recur_Type__c"]');
        if (!frequencyInput.checkValidity()) {
            frequencyInput.reportValidity();
            return;
        }        
        const dayNamesSelected = this.dayNamesSelected;
        const scheduleRecurrObj = { ...this.scheduleRecurrObj };
        if (scheduleRecurrObj.Recur_Type__c === 'Daily/Weekly' || scheduleRecurrObj.Recur_Type__c === 'Every Other Week') {
            const isValid = this.checkCustomValidations();
            const pageValid = abs_helper.validateCurrentPage(this);
            if (isValid && pageValid) {
                if (dayNamesSelected && dayNamesSelected.length > 0) {
                    let isFirstDay = false;
                    let daysString = '';

                    for (let i = 0; i < dayNamesSelected.length; i++) {
                        if (dayNamesSelected[i] === '1') {
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Sun';
                            } else {
                                daysString = daysString + ',Sun';
                            }
                            scheduleRecurrObj.Sun__c = true;
                        } else if (dayNamesSelected[i] === '2') {
                            scheduleRecurrObj.Mon__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Mon';
                            } else {
                                daysString = daysString + ',Mon';
                            }
                        } else if (dayNamesSelected[i] === '3') {
                            scheduleRecurrObj.Tue__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Tue';
                            } else {
                                daysString = daysString + ',Tue';
                            }
                        } else if (dayNamesSelected[i] === '4') {
                            scheduleRecurrObj.Wed__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Wed';
                            } else {
                                daysString = daysString + ',Wed';
                            }
                        } else if (dayNamesSelected[i] === '5') {
                            scheduleRecurrObj.Thur__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Thu';
                            } else {
                                daysString = daysString + ',Thu';
                            }
                        } else if (dayNamesSelected[i] === '6') {
                            scheduleRecurrObj.Fri__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Fri';
                            } else {
                                daysString = daysString + ',Fri';
                            }
                        } else if (dayNamesSelected[i] === '7') {
                            scheduleRecurrObj.Sat__c = true;
                            if (!isFirstDay) {
                                isFirstDay = true;
                                daysString = daysString + 'Sat';
                            } else {
                                daysString = daysString + ',Sat';
                            }
                        }
                    }

                    scheduleRecurrObj.WeekDays__c = daysString;
                    this.scheduleRecurrObj = { ...scheduleRecurrObj };
                    this.finish(scheduleRecurrObj);
                } else {
                    this.showToast('Error!', 'Please select at least one day of week.', 'error');
                }
            }
        } else if (scheduleRecurrObj.Recur_Type__c === 'Monthly') {
            const validity = this.checkCustomValidations();
            const pageValid = abs_helper.validateCurrentPage(this);
            if (validity && pageValid) {
                this.finish(scheduleRecurrObj);
            }
        }
    }

    checkForDuplicateSchedule() {
        let isDuplicate = false;
        const scheduleRecurr = this.scheduleRecurr;
        const scheduleRecurrObj = this.scheduleRecurrObj;

        if (scheduleRecurr && scheduleRecurr.length > 0) {
            for (let obj of scheduleRecurr) {
                if (
                    (obj.DTE_Begin_Date__c === scheduleRecurrObj.DTE_Begin_Date__c) ||
                    (obj.DTE_End_Date__c === scheduleRecurrObj.DTE_End_Date__c) ||
                    (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_Begin_Date__c) ||
                    (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_End_Date__c) ||
                    (scheduleRecurrObj.DTE_Begin_Date__c >= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_End_Date__c) ||
                    (scheduleRecurrObj.DTE_Begin_Date__c >= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c <= obj.DTE_End_Date__c) ||
                    (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_End_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_End_Date__c)
                ) {
                    isDuplicate = true;
                    break;
                }
            }
        }
        return isDuplicate;
    }

    checkCustomValidations() {
        const inputDateField = this.template.querySelector('[data-field="DTE_Begin_Date__c"]');
        const endDateField = this.template.querySelector('[data-field="DTE_End_Date__c"]');

        const cmpBeginDate = inputDateField ? inputDateField.value : null;
        const endDate = endDateField ? endDateField.value : null;

        let isValid = false;
        const todayDate = new Date();
        const todayDateUTC = this.getDateInUTC(todayDate);
        let todayDateMinus9Days = this.getDateInUTC(todayDate);
        todayDateMinus9Days.setDate(todayDateMinus9Days.getDate() - 9);

        const validityBeginDate = this.checkValidity(cmpBeginDate);
        const validityEndDate = this.checkValidity(endDate);

        if (validityBeginDate && validityEndDate) {
            const beginDate = this.getDateInUTC(new Date(cmpBeginDate));
            const endDate1 = this.getDateInUTC(new Date(endDate));
            const authBeginDate = this.getDateInUTC(new Date(this.authBeginDate));
            const authEndDate = new Date(this.authEndDate);

            if (beginDate > endDate1) {
                inputDateField.setCustomValidity('Begin Date cannot be greater than End Date.');
                inputDateField.reportValidity();
                return false;
            } else if (beginDate < authBeginDate) {
                const formattedAuthBeginDate = this.padNumber(authBeginDate.getMonth() + 1) + '/' +
                    this.padNumber(authBeginDate.getDate()) + '/' +
                    authBeginDate.getFullYear();
                inputDateField.setCustomValidity(`Begin date cannot be less than authorization begin date, ${formattedAuthBeginDate}`);
                inputDateField.reportValidity();
                return false;
            } else if (endDate1 > authEndDate) {
                const formattedAuthEndDate = this.padNumber(authEndDate.getMonth() + 1) + '/' +
                    this.padNumber(authEndDate.getDate()) + '/' +
                    authEndDate.getFullYear();
                endDateField.setCustomValidity(`End date cannot be greater than authorization end date, ${formattedAuthEndDate}`);
                endDateField.reportValidity();
                return false;
            }else{
                inputDateField.setCustomValidity('');
                inputDateField.reportValidity();
                endDateField.setCustomValidity('');
                endDateField.reportValidity();
            }

            if (beginDate < todayDateMinus9Days) {
                inputDateField.setCustomValidity('Begin Date cannot be prior to today + 9 days in past.');
                inputDateField.reportValidity();
                return false;
            } else if (beginDate < todayDateUTC && !this.isCreate) {
                inputDateField.setCustomValidity('Begin date should be in future');
                inputDateField.reportValidity();
                return false;
            }
        }

        if (this.scheduleRecurrObj.Recur_Type__c === 'Monthly') {
            isValid = validityBeginDate && validityEndDate;
        } else {
            isValid = validityBeginDate && validityEndDate;
        }

        return isValid;
    }

    checkValidity(dateStr) {
        if (!dateStr) {
            return false;
        }

        let valid = true;
        const date = this.getDateInUTC(new Date(dateStr));

        const month = date.getMonth();
        const day = date.getDate();
        const year = date.getFullYear();

        if (
            isNaN(month) || isNaN(day) || isNaN(year) ||
            month < 0 || month > 11 ||
            day < 1 || day > 31 ||
            year < 1000 || year > 9999
        ) {
            valid = false;
        }

        return valid;
    }

    getDateInUTC(date) {
        return new Date(Date.UTC(
            date.getFullYear(),
            date.getMonth(),
            date.getDate()
        ));
    }

    finish(scheduleRecurrObj) {
        const isDuplicate = this.checkForDuplicateSchedule();
        if (isDuplicate) {
            this.showToast('Error!', 'A recurrence pattern already exists for the date/s entered.', 'error');
            return;
        }

        this.scheduleRecurr = [...this.scheduleRecurr, scheduleRecurrObj];
        this.isModifiedAfterChange = true;
        this.showSpinner = false;
        // Reset schedule recurrence object
        this._scheduleRecurrObj = {
            sobjectType: 'Auth_Schedule_Recurrence__c',
            Recur_Type__c: '',
            RecurDay__c: '',
            DTE_Begin_Date__c: '',
            DTE_End_Date__c: '',
            Sun__c: '',
            Mon__c: '',
            Tue__c: '',
            Wed__c: '',
            Thur__c: '',
            Fri__c: '',
            Sat__c: '',
            WeekDays__c: '',
            DaysOfMonth__c: ''
        };
        this.dayNamesSelected = [];
        this.jobFrequency = '';
    }

    padNumber(number) {
        return number.toString().padStart(2, '0');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

}