import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import LightningModal from 'lightning/modal';
import { label } from 'c/labelUtility';
import { getQuestionByKey as Q_CP_ByKey, getSectionsByCategory as S_CP_ByCategory, evaluateFormulaByApiName as formula_CP } from 'c/countyPlanQuestionsUtility';
import { getQuestionByKey as Q_CRP_ByKey, getSectionsByCategory as S_CRP_ByCategory, evaluateFormulaByApiName as formula_CRP } from 'c/countyRateQuestionsUtility';


const columns = [
    { label: 'Section', fieldName: 'sectionTitle', type: 'text', 'wrapText': true, hideDefaultActions: true },
    { label: 'Questions', fieldName: 'QLabel', type: 'text', 'wrapText': true, hideDefaultActions: true },
    { label: 'Submitted Answer', fieldName: 'subAnswer', type: 'text', 'wrapText': true, hideDefaultActions: true },
    { label: 'Feedback', fieldName: 'Feedback__c', type: 'text', 'wrapText': true, hideDefaultActions: true }
];
const rateColumns = [
    { label: 'Section', fieldName: 'sectionTitle', type: 'text', 'wrapText': true, hideDefaultActions: true },
    { label: 'Rate Type + Age Group', fieldName: 'QLabel', type: 'text', 'wrapText': true, hideDefaultActions: true },
    { label: 'Feedback', fieldName: 'Feedback__c', type: 'text', 'wrapText': true, hideDefaultActions: true }
]
export default class FeedbackModal extends LightningModal {

    @api
    recordId
    @api
    isCPFlow = false;
    isReadonly;
    @track
    feedbacks;
    @api
    buttons
    showSpinner;
    columns = columns;
    rateColumns = rateColumns;
    submitted_crp;
    isSupervisor = true;
    @api
    showHeader;
    @api
    header;
    @track
    showPopup;
    @track myLabel = label;
    connectedCallback() {
        this.fetchFeedbacks();
    }
    get rateFeedbacks() {
        return (this.feedbacks || []).filter(feedback => feedback.feedback_type__c == 'CRP_Rate');
    }
    get normalFeedbacks() {
        return (this.feedbacks || []).filter(feedback => feedback.feedback_type__c != 'CRP_Rate');
    }
    showFeedback() {
        this.showPopup = true;
    }

    disconnectedCallback() {
        this.close({ 'evtType': 'close', 'payload': this.evtPayload });
        window.removeEventListener("popstate", () => { }, false);
    }
    handleClick(e) {
        const id = e.target.dataset.id;
        if (id) {
            if (id == 'close' || id == 'cancel') {
                this.close({ 'evtType': 'close', 'payload': '' });
            } else if (id == 'save') {
                //handleSave
                this.close({ 'evtType': 'close', 'payload': '' });
            }
        }
    }
    fetchFeedbacks() {
        let params = { 'recordId': this.recordId, 'isCPFlow': this.isCPFlow };
        helper.callServer(this, 'CompareCP_CRP_lwc', 'getFeedbacks', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    this.submitted_crp = result.objectData.lastSubmittedFeedback||{};
                    try {
                        if (this.isCPFlow) {
                            this.feedbacks = this.process_CP_Feedbacks(result);
                        } else {
                            this.feedbacks = this.process_CRP_Feedbacks(result);
                        }
                    } catch (err) {
                        console.log('e3e' + err.message);
                    }
                }
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }
    process_CP_Feedbacks(result) {
        let existingFeedbacks = JSON.parse(JSON.stringify(result.objectData.existingFeedbacks));
        let feedbacks = []
        existingFeedbacks.forEach(feed => {
            let sectionTitles = S_CP_ByCategory(feed.feedback_type__c);
            feed['sectionTitle'] = sectionTitles[feed.Section__c];
            let row = Q_CP_ByKey(feed.Identifier__c);
            if (row) {
                feed['QLabel'] = row.Qlabel;
                if (row.isComposite) {
                    feed['subAnswer'] = formula_CP(this.submitted_crp, feed.Identifier__c);
                } else {
                    feed['subAnswer'] = this.submitted_crp[feed.Identifier__c];
                }
                feedbacks.push(feed);
            }
        })
        return feedbacks;

    }
    process_CRP_Feedbacks(result) {
        let existingFeedbacks = JSON.parse(JSON.stringify(result.objectData.existingFeedbacks));
        let feedbacks = []
        existingFeedbacks.forEach(feed => {
            let sectionTitles = S_CRP_ByCategory(feed.feedback_type__c);
            feed['sectionTitle'] = sectionTitles[feed.Section__c];
            if (feed.feedback_type__c == 'CRP_Rate') {
                let age = feed.Identifier__c.split('@@')[1];
                if (feed.Section__c == 'Exempt') {
                    age = age == '36 - School Age' ? this.myLabel.X5_Years : this.myLabel.X5_Years_Less;
                }
                feed['QLabel'] = feed.Identifier__c.split('@@')[0] + '\n' + age;
            } else {
                let row = Q_CRP_ByKey(feed.Identifier__c);
                if (row) {
                    feed['QLabel'] = row.Qlabel;
                    if (row.isComposite) {
                        feed['subAnswer'] = formula_CRP(this.submitted_crp, feed.Identifier__c);
                    } else {
                        feed['subAnswer'] = this.submitted_crp[feed.Identifier__c];
                    }
                }
            }
            feedbacks.push(feed);
        });
        return feedbacks;
    }

}