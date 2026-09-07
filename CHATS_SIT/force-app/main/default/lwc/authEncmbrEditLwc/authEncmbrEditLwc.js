import { LightningElement, api, track } from 'lwc';

export default class AuthEncmbrEditLwc extends LightningElement {
    @track key = '';
    @track _originalHours = 0;
    @track _originalRateType = '';
    @track dayInCalendar = '';
    @track _isDirty = 'false';
    @track isRateTypeReadOnly = false;
    @track isCntHrReadOnly = false;
    @track _updatedSuccessfully = '';
    @track authEncmbrId = '';
    @track _anAuthEncmbr = { sobjectType: 'batchsit_t_auth_encmbr__x' };
    @track _recordError = '';

    @api map = {};
    @api day = {};
    @api provClosDteOptions = {};
    @api rateTypeOptions = [];
    @api authTerminated = false;
    @api isReadOnly = false;    

    @api
    get anAuthEncmbr() {
        return this._anAuthEncmbr;
    }
    set anAuthEncmbr(value) {
        this._anAuthEncmbr = value;
    }

    @api
    get isDirty() {
        return this._isDirty;
    }
    set isDirty(value) {
        this._isDirty = value;
    }

    @api
    get updatedSuccessfully() {
        return this._updatedSuccessfully;
    }
    set updatedSuccessfully(value) {
        this._updatedSuccessfully = value;
    }

    @api
    get recordError() {
        return this._recordError;
    }
    set recordError(value) {
        this._recordError = value;
    }

    @api
    get originalHours() {
        return this._originalHours;
    }
    set originalHours(value) {
        this._originalHours = value;
    }

    @api
    get originalRateType() {
        return this._originalRateType;
    }
    set originalRateType(value) {
        this._originalRateType = value;
    }

    @api
    get cellDate() {
        return this.anAuthEncmbr?.dte_care__c;
    }

    @api
    get selectedRateType() {
        return this.anAuthEncmbr?.cde_type_unit_care__c;
    }
    
    connectedCallback() {
        this.initializeComponent();
    }

    get unitDisplay() {
        const hours = this.anAuthEncmbr.cnt_hour_care__c;
        if (hours < 0.1) return '';
        if (hours <= 5) return 'PT';
        if (hours <= 12) return 'FT';
        if (hours <= 17) return 'FT/PT';
        if (hours <= 24) return 'FT/FT';
        return '';
    }

    get cellClass() {
        if (this.updatedSuccessfully === 'true') return 'day successCell';
        if (this.updatedSuccessfully === 'false') return 'dayFailure errorCell';
        if (this._isDirty === 'true') return 'day dirtyCell';
        return 'day';
    }

    get hasDay() {
        return this.dayInCalendar && this.dayInCalendar !== '';
    }

    get hoursRequired() {
        return this.anAuthEncmbr.cnt_hour_care__c ? 'true' : 'false';
    }

    initializeComponent() {
        if (this.day && this.day.Day) {
            const dt = this.day.Day;
            let key = dt.getFullYear() + '-' + (dt.getMonth() + 1) + '-' + dt.getDate();
            key = key.replace(/-0+/g, '-');
            this.key = key;
            if (key in this.map) {
                const authEncmbr = this.map[key];
                this.anAuthEncmbr = { ...authEncmbr };
                this.isRateTypeReadOnly = false;
                this.isCntHrReadOnly = false;
                this.originalHours = authEncmbr.cnt_hour_care__c;
                this.originalRateType = authEncmbr.cde_type_unit_care__c;
                if (authEncmbr.dte_care__c < this.getPriorDate(9)) {
                    this.isRateTypeReadOnly = true;
                    this.isCntHrReadOnly = true;
                }
            } else {
                this.isRateTypeReadOnly = true;
                this.isCntHrReadOnly = true;
            }
            if (this.isReadOnly) {
                this.isRateTypeReadOnly = true;
                this.isCntHrReadOnly = true;
            }
            this.dayInCalendar = dt.getDate().toString();
            const closureDates = this.provClosDteOptions;
            if (closureDates != undefined && closureDates != null) {
                for (let i = 0; i < closureDates.length; i++) {
                    if (closureDates[i] === key) {
                        this.isRateTypeReadOnly = true;
                        this.isCntHrReadOnly = true;
                        const rec = { ...this.anAuthEncmbr };
                        rec.cnt_hour_care__c = 0;
                        this.anAuthEncmbr = rec;
                    }
                }
            }
        }
    }

    handleHoursChange(event) {
        const newValue = event.target.value;
        this.anAuthEncmbr = {
            ...this.anAuthEncmbr,
            cnt_hour_care__c: newValue
        };
        this.markItDirty();
    }

    handleRateTypeChange(event) {
        const newValue = event.detail.value;
        this.anAuthEncmbr = {
            ...this.anAuthEncmbr,
            cde_type_unit_care__c: newValue
        };
        this.markItDirty();
    }

    markItDirty() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-select');
        let allValid = true;

        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                allValid = false;
            }
        });
        this.fireCreateEncumbranceEvent(this.anAuthEncmbr, true);

        const originalHours = parseInt(this.originalHours);
        const enteredHours = parseInt(this.anAuthEncmbr.cnt_hour_care__c);
        const originalRateType = this.originalRateType;
        const enteredRateType = this.anAuthEncmbr.cde_type_unit_care__c;

        if (enteredHours.toString() === 'NaN') {
            this.updatedSuccessfully = 'false';
            this.recordError = 'Value Cannot Be Blank';
        } else if (originalHours < enteredHours && this.anAuthEncmbr.dte_care__c < this.getPriorDate(9)) {
            this.updatedSuccessfully = 'false';
            this.recordError = 'You can increase the value only for records today minus 9 days in the past through the end of the authorization';
        } else if (originalHours > enteredHours && this.anAuthEncmbr.dte_care__c <= this.getCurrentSystemDate()) {
            this.updatedSuccessfully = 'false';
            this.recordError = 'Cannot decrease hours for past or current date';
        } else {
            if (allValid) {
                this.updatedSuccessfully = '';
                this._isDirty = 'true';
                this.recordError = '';
                this.fireCreateEncumbranceEvent(this.anAuthEncmbr, false);
            }
        }

        if (originalRateType !== enteredRateType) {
            if (originalHours > enteredHours && this.anAuthEncmbr.dte_care__c <= this.getCurrentSystemDate()) {
                this.updatedSuccessfully = 'false';
                this.recordError = 'Cannot decrease hours for past or current date';
            } else {
                this.updatedSuccessfully = '';
                this._isDirty = 'true';
                this.recordError = '';
                if (allValid) {
                    this.fireCreateEncumbranceEvent(this.anAuthEncmbr, false);
                }
            }
        }

        if (originalRateType === enteredRateType && originalHours === enteredHours) {
            this.updatedSuccessfully = '';
            this._isDirty = 'false';
            this.recordError = '';
            this.fireCreateEncumbranceEvent(this.anAuthEncmbr, true);
        }

        if (enteredRateType === '' || enteredRateType === null) {
            this.updatedSuccessfully = 'false';
            this.recordError = 'Rate Type Cannot be None';
        }

        if (!allValid) {
            this.updatedSuccessfully = 'false';
        }
    }

    fireCreateEncumbranceEvent(encumbranceRec, isDelete) {
        const event = new CustomEvent('createencumbranceevent', {
            detail: {
                encumbranceRec: encumbranceRec,
                isDelete: isDelete
            }
        });
        this.dispatchEvent(event);
    }

    getPriorDate(daysPrior) {
        const date = new Date();
        const last = new Date(date.getTime() - (daysPrior * 24 * 60 * 60 * 1000));
        const day = last.getUTCDate().toString().padStart(2, '0');
        const month = (last.getMonth() + 1).toString().padStart(2, '0');
        const year = last.getFullYear();
        return year + '-' + month + '-' + day;
    }

    getCurrentSystemDate() {
        const date = new Date();
        const day = date.getUTCDate().toString().padStart(2, '0');
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const year = date.getFullYear();
        return year + '-' + month + '-' + day;
    }

}