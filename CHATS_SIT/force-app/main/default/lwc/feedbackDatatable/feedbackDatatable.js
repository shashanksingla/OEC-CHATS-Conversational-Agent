import { LightningElement, api, track } from 'lwc';

export default class FeedbackDatatable extends LightningElement {
    @api tableData;
    @api columns
    @api sectionFeedback = {};
    @api sectionTitle
    @api screenMode;
    get processedData() {
        return (this.tableData || []).map((row) => {
            return {
                fieldName: row.fieldName, // Unique key for the row
                Qlabel: row.Qlabel,
                feedback: row.feedback,
                feedbackDisabled: row.feedbackDisabled,
                values: this.columns
                    .filter(val => val.fieldName !== 'feedback' && val.fieldName !== 'Qlabel')
                    .map((col, index, arr) => {
                        // Exclude the first value (index 0)
                        if (index === 0) {
                            return { value: row[col.fieldName] || '', cls: 'slds-text-color_default' };
                        }
                        // Compare the current value with the previous one
                        const prevValue = row[arr[index - 1].fieldName] || '';
                        const currentValue = row[col.fieldName] || '';
                        const cls = currentValue !== prevValue ? 'slds-text-color_error' : 'slds-text-color_default';
                        return { value: currentValue, cls };
                    })
            };
        });
    }
    get isViewOnly() {
        return this.screenMode === 'readonly';
    }
    handleFeedback(evt) {
        let identifer = evt.detail.identifier;
        let feedbackVal = evt.detail.feedback;
        let sectionFeedback = JSON.parse(JSON.stringify(this.sectionFeedback));
        let tableData = JSON.parse(JSON.stringify(this.tableData));
        let indice = tableData.findIndex(val => val.fieldName == identifer);
        if (indice > -1) {
            tableData[indice].feedback = feedbackVal;
            this.tableData = tableData;
        }
        if (sectionFeedback.hasOwnProperty(identifer)) {
            sectionFeedback[identifer].feedback = feedbackVal;
        } else {
            sectionFeedback[identifer] = { 'feedback': feedbackVal, 'section': this.sectionTitle };
        }
        this.sectionFeedback = sectionFeedback;
    }
}