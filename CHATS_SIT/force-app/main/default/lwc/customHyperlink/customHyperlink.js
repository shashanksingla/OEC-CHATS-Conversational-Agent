import { LightningElement, api } from 'lwc';

export default class CustomHyperlink extends LightningElement {
    @api value;
    @api recordId;
    @api rowId;

    handleClick(event) {
        event.preventDefault();
        // Dispatch a custom event that will be handled by the parent component
        const clickEvent = new CustomEvent('hyperlinkclick', {
            composed: true,
            bubbles: true,
            detail: {
                recordId: this.recordId,
                rowId: this.rowId,
                value: this.value
            }
        });

        this.dispatchEvent(clickEvent);
    }
}