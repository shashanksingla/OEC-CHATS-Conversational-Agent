import { LightningElement, api, track, wire } from 'lwc';
import { helper } from 'c/generic_Utilities';

export default class Calendar_lwc extends LightningElement {
    @track months = [];
    @track weeksInAMonth = [];
    @track selectedMonth = '';
    @track selectedYear = '';
    @track provClosDteOptions = {};
    @track mapDateToEncumbranceUpdate = {};
    @track lstEncumbranceToBeUpdated = [];
    @track showSpinner = false;

    @api mapDateToRecordId = {};
    @api rateTypeOptions = [];
    @api isEncumbrnceCreated = false;
    @api authTerminated = false;
    @api provIdValtwo = '';
    @api countySFId = '';
    @api isReadOnly = false;
    @api isChildDisable = false;
    @api authRec = {};
    
    @api
    handleUnsavedChanges() {
        const cells = this.template.querySelectorAll('c-auth-encmbr-edit-lwc');
        let isInvalid = false;        
        cells.forEach(cell => {
            if (cell.isDirty === 'true' || cell.recordError!= '') {
                isInvalid = true;
            }
        });        
        return isInvalid;
    }

    connectedCallback() {
        this.initializeComponent();
    }

    get hasWeeksInMonth() {
        return this.weeksInAMonth && this.weeksInAMonth.length > 0;
    }

    initializeComponent() {
        const today = new Date();
        const month = today.getMonth();
        const year = today.getFullYear();        
        this.selectedMonth = month.toString();
        this.selectedYear = year.toString();
        this.isEncumbrnceCreated = true;
        this.months = [
            { value: "0", label: "January" },
            { value: "1", label: "February" },
            { value: "2", label: "March" },
            { value: "3", label: "April" },
            { value: "4", label: "May" },
            { value: "5", label: "June" },
            { value: "6", label: "July" },
            { value: "7", label: "August" },
            { value: "8", label: "September" },
            { value: "9", label: "October" },
            { value: "10", label: "November" },
            { value: "11", label: "December" }
        ];
        this.fetchProviderClosureData();
    }

    fetchProviderClosureData() {
        let params = {
            provRecId: this.provIdValtwo,
            countyId: this.countySFId
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'fetchProviderClosureRecs', (function (response) {
            if (response && response.isSuccessful && response.objectData.provClosDates) {
                this.provClosDteOptions = response.objectData.provClosDates;
            } else {
                console.error('Error fetching provider closure records:', response);
            }
        }).bind(this), JSON.stringify(params));
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
    }

    viewCalendar() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let allValid = true;        
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                allValid = false;
            }
        });
        if (allValid) {
            this.getDaysInAMonth(this.selectedMonth, this.selectedYear);
        }
    }

    getDaysInAMonth(selectedMonth, selectedYear) {
        const weeksOfAMonth = [];
        const nextMonth = parseInt(selectedMonth) + 1;
        const noOfDaysInAMonth = new Date(selectedYear, nextMonth, 0).getDate();
        let daysInCurrentWeek = [];
        let emptyDatesAdded = false;
        let dayCounter = 0;
        let weekCounter = 0;        
        for (let day = 1; day <= noOfDaysInAMonth; day++) {
            const currentDay = new Date(selectedYear, selectedMonth, day);
            if (!emptyDatesAdded) {
                const dayOfWeek = currentDay.getDay();
                const emptyDaysToAdd = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Convert to Monday-based week
                for (let i = 0; i < emptyDaysToAdd; i++) {
                    daysInCurrentWeek.push({
                        id: `${selectedYear}_${selectedMonth}_empty_${dayCounter}`,
                        Day: null
                    });
                    dayCounter++;
                }
                emptyDatesAdded = true;
            }            
            daysInCurrentWeek.push({
                id: `${selectedYear}_${selectedMonth}_day_${day}`,
                Day: currentDay
            });
            dayCounter++;            
            // If a week is formed then add that week to month
            if (daysInCurrentWeek.length === 7 || day === noOfDaysInAMonth) {
                if (day === noOfDaysInAMonth) {
                    const remainingDays = 7 - daysInCurrentWeek.length;
                    for (let i = 0; i < remainingDays; i++) {
                        daysInCurrentWeek.push({
                            id: `${selectedYear}_${selectedMonth}_empty_${dayCounter}`,
                            Day: null
                        });
                        dayCounter++;
                    }
                }
                weeksOfAMonth.push({
                    id: `${selectedYear}_${selectedMonth}_week_${weekCounter}`,
                    DaysInAWeek: daysInCurrentWeek
                });
                weekCounter++;
                daysInCurrentWeek = [];
            }
        }
        
        this.weeksInAMonth = weeksOfAMonth;
    }

    validateAndSaveChanges(){
        this.showSpinner = true;
        const lstEncumbranceToBeUpdated = [];        
        for (const key in this.mapDateToEncumbranceUpdate) {
            const encumbranceRec = { ...this.mapDateToEncumbranceUpdate[key] };
            encumbranceRec.sobjectType = 'batchsit_t_auth_encmbr__x';
            lstEncumbranceToBeUpdated.push(encumbranceRec);
        }        
        this.lstEncumbranceToBeUpdated = lstEncumbranceToBeUpdated;
        if (lstEncumbranceToBeUpdated.length > 0) {
            this.updateAuthEncmbrCalendarCell();
        } else {
            this.showSpinner = false;
            const message= 'You must edit at least one day to save changes to the schedule.';
            helper.showToast(this, 'Error', message, 'error', 'dismissable');
        }
    }

    updateAuthEncmbrCalendarCell() {
        let params = {
            lstAuthEncumbRec: this.lstEncumbranceToBeUpdated
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'callUpdate', (function (response) {
            const cells = this.template.querySelectorAll('c-auth-encmbr-edit-lwc');
            if (response && response.isSuccessful === true) {
                cells.forEach(cell => {
                    const isDirty = cell.isDirty;
                    const cellDate = cell.cellDate;
                    const isDateInUpdateList = this.lstEncumbranceToBeUpdated.some(
                        encmbr => encmbr.dte_care__c === cellDate
                    );
                    if (isDirty === 'true' && isDateInUpdateList) {
                        cell.updatedSuccessfully = 'true';
                        cell.isDirty = false;
                        const authEncmbr = cell.anAuthEncmbr;
                        cell.originalHours = authEncmbr.cnt_hour_care__c;
                        cell.originalRateType = authEncmbr.cde_type_unit_care__c;
                        // Update the source map with saved values
                        const [year, month, day] = cellDate.split('-'); // Convert cellDate '2026-07-03' to '2026-7-3' format to match mapDateToRecordId keys
                        const mapKey = `${year}-${parseInt(month, 10)}-${parseInt(day, 10)}`;
                        if (this.mapDateToRecordId && this.mapDateToRecordId[mapKey]) {
                            // Deep clone to break proxy, update values, then reassign
                            const clonedMap = JSON.parse(JSON.stringify(this.mapDateToRecordId));
                            clonedMap[mapKey].cnt_hour_care__c = authEncmbr.cnt_hour_care__c;
                            clonedMap[mapKey].cde_type_unit_care__c = authEncmbr.cde_type_unit_care__c;
                            this.mapDateToRecordId = clonedMap;
                        }
                    }
                });
                this.mapDateToRecordId = { ...this.mapDateToRecordId };
                this.mapDateToEncumbranceUpdate = {};
                this.showSpinner = false;
            } else {
                cells.forEach(cell => {
                    const isDirty = cell.isDirty;
                    if (isDirty === 'true') {
                        cell.updatedSuccessfully = 'false';
                        cell.recordError = 'Problem saving record, error: ' + (response ? response.message : 'Unknown error');
                    }
                });
                this.showSpinner = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    handleCreateEncumbranceEvent(event) {
        const encumbranceRec = event.detail.encumbranceRec;
        const isDelete = event.detail.isDelete;
        const key = encumbranceRec.dte_care__c;
        
        if (!isDelete) {
            this.mapDateToEncumbranceUpdate[key] = encumbranceRec;
        } else {
            delete this.mapDateToEncumbranceUpdate[key];
        }
        
        this.mapDateToEncumbranceUpdate = { ...this.mapDateToEncumbranceUpdate };
    }

}