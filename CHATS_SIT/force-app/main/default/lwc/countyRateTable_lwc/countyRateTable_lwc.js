import { LightningElement, api, track } from 'lwc';
export default class CountyRateTable_lwc extends LightningElement {
    columns;
    @api
    recordId;
    @api
    rates;
    @track
    formattedRates;
    @api
    isApproved
    @api isExempt
    @api
    sectionFeedback = {};
    @api overAllFeedback = {};
    @api compareRates;
    @api sectionTitle;
    @api screenMode
    connectedCallback() {
        if (this.isExempt) {
            this.columns = [{ 'colspan': '0', 'label': 'Not Rated: PT' }, { 'colspan': '0', 'label': 'Not Rated: FT' }, { 'colspan': '0', 'label': 'Not Rated: FT/PT' }, { 'colspan': '0', 'label': 'Not Rated: FT/FT' }]
        } else {
            this.columns = [{ 'colspan': '2', 'label': 'Tier 1' }, { 'colspan': '2', 'label': 'Tier 2' }, { 'colspan': '2', 'label': 'Tier 3' }, { 'colspan': '2', 'label': 'Tier 4' }, { 'colspan': '2', 'label': 'Tier 5' }]
        }
        this.setTableValues();
    }
    get isViewOnly() {
        return this.screenMode === 'readonly';
    }
    setTableValues() {
        try {
            let rates = JSON.parse(JSON.stringify(this.rates));
            let compareRates = JSON.parse(JSON.stringify(this.compareRates));
            let units = ['PT', 'FT', 'FTPT', 'FTFT'];
            let tiers = ['1', '2', '3', '4', '5'];
            if (rates.length > 0) {
                rates.sort(function (a, b) {
                    if (a.key < b.key) { return -1; }
                    if (a.key > b.key) { return 1; }
                    return 0;
                });
                rates.forEach((val, index) => {
                    if (!this.isApproved && this.overAllFeedback[val.key]) {
                        val.feedback = (this.overAllFeedback[val.key] || {}).feedback;
                        this.sectionFeedback[val.key] = { 'feedback': this.overAllFeedback[val.key].feedback, 'section': this.sectionTitle, 'Id': this.overAllFeedback[val.key].Id };
                    }
                    let compIndex = compareRates.findIndex(com => com.key === val.key);
                    val.diffCatClass = (compIndex > -1) ? 'slds-text-color_default' : 'slds-text-color_error';
                    if (this.isExempt) {
                        units.forEach(unit => {
                            val['unit' + unit + 'cls'] = (compIndex > -1 && compareRates[compIndex]['unit' + unit + 'Amt'] != val['unit' + unit + 'Amt']) ? 'slds-text-color_error' : 'slds-text-color_default'
                        });
                    } else {
                        val.isGroupKey = index % 4 === 0;
                        tiers.forEach(tier => {
                            val['tier' + tier + 'cls'] = (compIndex > -1 && compareRates[compIndex]['tier' + tier + 'Amt'] != val['tier' + tier + 'Amt']) ? 'slds-text-color_error' : 'slds-text-color_default'
                        });
                    }
                });
                this.formattedRates = rates;
            }
        } catch (err) {
            console.log('err.message' + err.message + '-' + err.stack);
        }
    }
    handleFeedback(evt) {

        let sectionFeedback = JSON.parse(JSON.stringify(this.sectionFeedback));
        let identifer = evt.detail.identifier;
        let feedbackVal = evt.detail.feedback;
        let formattedRates = this.formattedRates;
        let indice = formattedRates.findIndex(val => val.key == identifer && (val.isGroupKey == true || this.isExempt));
        if (indice > -1) {
            formattedRates[indice].feedback = feedbackVal;
            this.formattedRates = formattedRates;
        }
        if (sectionFeedback.hasOwnProperty(identifer)) {
            sectionFeedback[identifer].feedback = feedbackVal;
        } else {
            sectionFeedback[identifer] = { 'feedback': feedbackVal, 'section': this.sectionTitle };
        }
        this.sectionFeedback = sectionFeedback;
    }
}