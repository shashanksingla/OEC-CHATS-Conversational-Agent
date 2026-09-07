import { LightningElement, api, track } from 'lwc';
export default class ConfirmationModal_LWC extends LightningElement {
    @api title = 'CONFIRM';
    @api confirmMsg;
    @api confirmMsgLst = [];
    @api showYesButton;
    showYesButton = true;
    @api showNoButton ;
    showNoButton = true;
    @api showCloseButton;
    showCloseButton = true;
    @api yesLabel = 'Yes';
    @api noLabel = 'No';
    @api disableYesButton = false;
    closeModal(){
        this.handleNoClick();
    }
    handleYesClick() {
        const yesEvent = new CustomEvent('yes');
        this.dispatchEvent(yesEvent);
    }
    handleNoClick() {
        const noEvent = new CustomEvent('no');
        this.dispatchEvent(noEvent);
    }
}