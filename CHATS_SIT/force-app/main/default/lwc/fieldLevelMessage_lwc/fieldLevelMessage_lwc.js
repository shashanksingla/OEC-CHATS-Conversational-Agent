import { LightningElement, api } from 'lwc';

export default class FieldLevelMessage_lwc extends LightningElement {
    @api message;
    @api errorKey;
}