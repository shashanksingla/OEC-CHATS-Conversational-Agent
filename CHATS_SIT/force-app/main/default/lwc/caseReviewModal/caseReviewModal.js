import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';


export default class CaseReviewModal extends LightningModal {
    @api modalContent;
    @api modalHeader;
    @api lwcToImport;
    @api childProps;
    @api showHeader;
    @api buttons;
    @api initialTaskComment;
    showModal;
    @track _taskComment;
    @track evtPayload = {};
    revieweeId;
    valid;

    get taskComment() {
        return this._taskComment;
    }

    async connectedCallback() {
        window.addEventListener('popstate', () => {
            this.close({ 'evtType': 'close', 'payload': this.evtPayload });
            window.removeEventListener("popstate", () => { }, false);
        });
        this._taskComment = this.initialTaskComment;
        this.showModal = true;
        this.setPayload();
    }

    disconnectedCallback() {
        this.close({ 'evtType': 'close', 'payload': this.evtPayload });
        window.removeEventListener("popstate", () => { }, false);
    }

    handleClick(e) {
        const id = e.target.dataset.id;
        console.log('id' + id);
        if (this.submitToReviewee) {
            let comp = this.template.querySelector('.revieweeLookup');
            if (comp) {
                comp.enableError = true;
                comp.reportValidity();
            }
        }
        if (id) {
            if (!this.lwcToImport || (this.lwcToImport && this.valid)) {
                this.close({ 'evtType': id, 'payload': this.evtPayload });
            }
        }
    }

    get stateReviewee() {
        return this.lwcToImport === 'c/stateReversalPopup';
    }

    get submitToReviewee() {
        return this.lwcToImport === 'c/submitToRevieweePopup';
    }

    handleUpdate(evt) {
        evt.preventDefault();
        this._taskComment = evt.detail.value;
        this.setPayload();
    }

    handleValueSelectedOnAccount(evt) {
        let detail = evt.detail;
        this.revieweeId = '';
        if (detail.objName && detail.fieldName) {
            switch (detail.objName + '-' + detail.fieldName) {
                case 'User-Name':
                    this.revieweeId = detail.record.Id;
                    break;
                default:
            }
        }
        this.setPayload();
    }

    setPayload() {
        if (this.submitToReviewee) {
            this.valid = this.revieweeId != undefined && this.revieweeId.length > 0;
            this.evtPayload = { 'revieweeId': this.revieweeId };
        } else if (this.stateReviewee) {
            this.valid = this.taskComment != undefined && this.taskComment.length > 0;
            this.evtPayload = { 'taskComment': this.taskComment };
        }
        this.evtPayload.valid = this.valid;
    }
}