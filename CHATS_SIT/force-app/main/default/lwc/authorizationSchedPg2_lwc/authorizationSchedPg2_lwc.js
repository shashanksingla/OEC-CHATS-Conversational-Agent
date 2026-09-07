import { LightningElement, api, track } from 'lwc';

export default class AuthorizationSchedPg2_lwc extends LightningElement {
    @api careDateToAuthEncmbr = {};
    @api rateTypeOptions = [];
    @api isEncumbrnceCreated = false;
    @api authTerminated = false;
    @api provIdValtwo = '';
    @api countySFId = '';
    @api isReadOnly = false;
    @api authRec = {};
    @api isChildDisable = false;

    @api
    handleUnsavedChanges() {
        const calendarComponent = this.template.querySelector('c-calendar_lwc');
        if (calendarComponent) {
            return calendarComponent.handleUnsavedChanges();
        }
        return false;
    }

    @api
    getIsEncumbrnceCreated() {
        const calendarComponent = this.template.querySelector('c-calendar_lwc');
        if (calendarComponent) {
            return calendarComponent.isEncumbrnceCreated;
        }
        return this.isEncumbrnceCreated;
    }
}