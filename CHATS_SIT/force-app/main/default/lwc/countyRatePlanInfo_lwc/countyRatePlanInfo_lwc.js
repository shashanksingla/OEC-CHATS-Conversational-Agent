import { LightningElement, api, track } from 'lwc';
import { getQuestionByKey, getSectionsByCategory, getHeaderTitleByKey, evaluateFormulaByApiName } from 'c/countyRateQuestionsUtility';

export default class CountyRatePlanInfo_lwc extends LightningElement {
    @api compareList;
    @api hasPriorSubmissions;
    @api overAllFeedback = {};
    @track
    columns = [{
        'label': 'Questions', 'type': 'text', 'fieldName': 'Qlabel', 'wrapText': true, 'hideDefaultActions': true
    }, {
        'label': "Feedback", 'type': "customFeedback", 'fieldName': 'feedback', 'hideDefaultActions': true
    }];
    @track
    rows = [];
    showTable = false;
    @api screenMode;
    @api isSupervisor;

    @api
    getAllSubChilds() {
        return this.template.querySelectorAll('c-feedback-datatable');
    }
    connectedCallback() {
        let columns = this.columns;
        let rows = [];
        this.compareList.forEach((val, index) => {
            let dateToShow;
            let statusLabel = 'Submitted';
            if (val.Status__c == 'Conditionally Approved') {
                statusLabel = 'Conditionally Approved';
                dateToShow = this.formatDateToMMDDYYYY(val.Action_Date__c || val.DTE_BEGIN_EFFV_RATE__c);
            } else if (val.Status__c == 'Approved') {
                statusLabel = 'Approved';
                dateToShow = this.formatDateToMMDDYYYY(val.DTE_BEGIN_EFFV_RATE__c);
            } else {
                dateToShow = this.formatDateToMMDDYYYY(val.Action_Date__c);
            }
            let label = statusLabel;
            if (this.hasPriorSubmissions) {
                label += ' ' + dateToShow;
                if (val.DTE_BEGIN_EFFV_RATE__c && index > 0) {
                    label += '\n' + val.Status__c + ' (' + this.formatDateToMMDDYYYY(val.DTE_BEGIN_EFFV_RATE__c) + ')';
                }
            }
            columns.push({
                'label': label, 'type': 'text', 'fieldName': index,
                'hideDefaultActions': true, wrapText: true
            });
        });

        this.columns = columns;
        const allQues = getQuestionByKey();
        Object.keys(allQues).forEach(fieldKey => {
            let row = allQues[fieldKey];
            let fieldValue = row.isPreDefaulted ? row.defaultValue : '';
            this.compareList.forEach((val, index) => {
                if (row.isComposite) {
                    fieldValue = evaluateFormulaByApiName(val, fieldKey);
                } else if (!row.isPreDefaulted) {
                    fieldValue = val[fieldKey];
                }
                row['fieldName'] = fieldKey;
                row[index] = '' + (fieldValue || ' ');
                row['feedback'] = (this.overAllFeedback[fieldKey] || {}).feedback;
            })
            rows.push(row);
        });
        this.rows = rows;
        this.showTable = true;

    }
    formatDateToMMDDYYYY(dateString) {
        if (!dateString) {
            return '';
        }

        // Salesforce Date fields are commonly YYYY-MM-DD. Parse as a plain date,
        // not a timestamp, to avoid timezone day shifts (e.g. GMT-6 -> previous day).
        if (typeof dateString === 'string') {
            const trimmedDate = dateString.trim();
            const dateOnlyMatch = trimmedDate.match(/^(\d{4})-(\d{2})-(\d{2})$/);
            if (dateOnlyMatch) {
                const [, year, month, day] = dateOnlyMatch;
                return `${month}/${day}/${year}`;
            }
        }

        const date = new Date(dateString);
        if (Number.isNaN(date.getTime())) {
            return '';
        }

        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        const year = date.getFullYear();
        console.log('date'+dateString+'converted'+ `${month}/${day}/${year}`);
        return `${month}/${day}/${year}`;
    }
    get tables() {
        let tableData = [];
        let categories = getSectionsByCategory('CRP');
        Object.keys(categories).forEach(section => {
            tableData.push({ 'data': this.tableSpecificRows(section), 'section': section, 'sectionTitle': categories[section], 'headerTitle': getHeaderTitleByKey(section) });
        });
        return tableData
    }
    tableSpecificRows(section) {
        return this.rows.filter(val => val.section == section);
    }

}