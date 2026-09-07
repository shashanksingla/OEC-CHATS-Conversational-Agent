import { LightningElement, api } from 'lwc';

export default class CP_CRP_FeedbackBox extends LightningElement {
    @api feedback;
    @api identifier;
    @api screenMode;
    connectedCallback() {
    }
    handleFeedback(evt) {
        this.feedback = evt.target.value;
        const passUpdate = new CustomEvent('passfeedback', {
            detail: {
                'identifier': this.identifier,
                'feedback': evt.target.value
            }, bubbles: true,
            composed: true
        });
        this.dispatchEvent(passUpdate);
    }
    get isReadonly() {
        return this.screenMode == 'readonly' ? true : false;
    }
}