import { LightningElement, api, track } from 'lwc';

export default class PageMessages_lwc extends LightningElement {
    @track _messageType;
    @track _pageMessages;
    
    @api
    get messageType() {
        return this._messageType;
    }
    
    set messageType(value) {
        const oldValue = this._messageType;
        this._messageType = value;
        
        // Fire event when messageType changes
        if (oldValue !== value) {
            this.dispatchEvent(new CustomEvent('messagetypechange', {
                detail: {
                    value: value
                }
            }));
        }
    }
    
    @api
    get pageMessages() {
        return this._pageMessages;
    }
    
    set pageMessages(value) {
        this._pageMessages = value;
    }
    
    get errorClass() {
        return 'slds-notify slds-notify_alert slds-theme_' + this.messageType;
    }

    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }
}