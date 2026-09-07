import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import fetchRelatedObjectdata from '@salesforce/apex/DynamicExternalDetailPageController.fetchRelatedObjectdata';

export default class CustomRelatedListExternalObjLwc extends NavigationMixin(LightningElement) {
    @track showMore = false;    
    @track listRecordsToDisplay = [];
    @track recCount = 0;
    @track isLoading = false;

    @api recordId;
    @api componentAttributes;
    @api componentAttributesValues;
    @api componentAttributesTypes;
    @api parentObjIdentifier;
    @api pickListTypeFields = '';
    @api relatedListHeader = '';
    @api childApiName = '';
    @api indivArtFees = 'batchsit_t_indiv_rat_fees__x';
    @api showTable = false;
    @api orderByField = ' ';
    @api recordsLimit = '365';
    @api sortAscDsc = 'ASC';
    @api isNavigateToCmp = false;
    @api returnBackToCaseCommentsList = false;
    @api navigationKey = '';
    @api timezones;

    connectedCallback() {
        this.showTable = true;
        if (!this.isNavigateToCmp) {
            const urlStr = window.location.origin + window.location.pathname;
            this.showMore = urlStr.endsWith('view');
        }

        if (this.returnBackToCaseCommentsList === 'true') {
            this.pickListTypeFields = 'cde_type_note_cmt__c,R00700__c,Field_Utility__c;cde_type_cmt__c,R00838__c,Field_Utility__c';
            this.componentAttributesTypes = 'ExternalId;cde_type_cmt__c;txt_subj__c;cde_type_note_cmt__c;createddate__c';
            this.orderByField = 'createddate__c';
            this.sortAscDsc = 'DESC';
            this.childApiName = 'batchsit_t_sbsd_case_cmt__x';
            this.parentObjIdentifier = 'IDN_EXTNL__c';
            this.recordsLimit = '365';
            this.relatedListHeader = 'Case Comment';
        }

        // Check if we have navigation data in sessionStorage
        if (this.navigationKey && this.isNavigateToCmp) {
            this.loadNavigationData();
        } else {
            this.retrieveExtObjData();
        }

        if (this.returnBackToCaseCommentsList === true) {
            this.navigateToChildComponent();
        }
    }

    get displayRecords() {
        if (this.showMore) {
            return this.listRecordsToDisplay.slice(0, 5);
        }
        return this.listRecordsToDisplay;
    }


    get tableHeaders() {
        if (this.listRecordsToDisplay.length > 0) {
            return this.listRecordsToDisplay[0].fldDefList.map(field => ({
                ...field,
                showAscIcon: this.sortAscDsc === 'ASC' && field.fieldAPIName === this.orderByField,
                showDescIcon: this.sortAscDsc === 'DESC' && field.fieldAPIName === this.orderByField
            }));
        }
        return [];
    }

    get showViewAllFooter() {
        return this.recCount > 0 && this.showMore;
    }

    get timezone() {
        return this.timezones?this.timezones:'America/Denver';
    }

    loadNavigationData() {
        try {
            const navigationData = sessionStorage.getItem(this.navigationKey);
            if (navigationData) {
                const parsedData = JSON.parse(navigationData);
                // CCCAP-15208 - Sanitize data from sessionStorage to prevent XSS attacks
                this.listRecordsToDisplay = this.sanitizeRecords(parsedData.listRecordsToDisplay || []);
                this.recCount = typeof parsedData.recCount === 'number' ? parsedData.recCount : 0;
                
                // Clean up sessionStorage after loading
                sessionStorage.removeItem(this.navigationKey);
            } else {
                // Fallback to retrieving data if sessionStorage is empty
                this.retrieveExtObjData();
            }
        } catch (error) {
            console.error('Error loading navigation data:', error);
            // Fallback to retrieving data if there's an error
            this.retrieveExtObjData();
        }
    }

    //Sanitizes records array retrieved from sessionStorage
    sanitizeRecords(records) {
        if (!Array.isArray(records)) {
            return [];
        }        
        return records.map((record, index) => ({
            id: index,
            fldDefList: Array.isArray(record.fldDefList) 
                ? record.fldDefList.map(field => this.sanitizeField(field))
                : []
        }));
    }

    // Sanitizes individual field object
    sanitizeField(field) {
        if (!field || typeof field !== 'object') {
            return {};
        }

        const sanitized = {};
        
        // sanitize string values
        const stringFields = ['fieldValue', 'fieldLabel', 'fieldAPIName', 'dataType', 'childRecordId', 'parentRecordId'];
        stringFields.forEach(key => {
            if (field[key] !== undefined && field[key] !== null) {
                sanitized[key] = typeof field[key] === 'string' ? this.escapeHtml(field[key]) : field[key];
            }
        });

        // date/datetime values
        if (field.fieldValueDate !== undefined) {
            sanitized.fieldValueDate = field.fieldValueDate;
        }
        if (field.fieldValueDateTime !== undefined) {
            sanitized.fieldValueDateTime = field.fieldValueDateTime;
        }

        // boolean flags
        const booleanFields = ['isDate', 'isDateTime', 'isDouble', 'isExternalId', 'isReference', 'isText', 'isIndivArtFees', 'isUserReference'];
        booleanFields.forEach(key => {
            if (field[key] !== undefined) {
                sanitized[key] = Boolean(field[key]);
            }
        });

        // sanitize URLs
        if (field.recordUrl && this.isValidRecordUrl(field.recordUrl)) {
            sanitized.recordUrl = field.recordUrl;
        }
        if (field.parentRecordUrl && this.isValidRecordUrl(field.parentRecordUrl)) {
            sanitized.parentRecordUrl = field.parentRecordUrl;
        }
        
        return sanitized;
    }

    // Escapes HTML entities in a string to prevent XSS attacks
    escapeHtml(str) {
        if (typeof str !== 'string') {
            return str;
        }
        const htmlEscapes = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#x27;',
            '/': '&#x2F;'
        };
        return str.replace(/[&<>"'/]/g, char => htmlEscapes[char]);
    }

    // Validates that a URL is a safe Salesforce record URL
    isValidRecordUrl(url) {
        if (typeof url !== 'string') {
            return false;
        }
        // Only allow Salesforce record URLs: /lightning/r/{recordId}/view
        return /^\/lightning\/r\/[a-zA-Z0-9]{15,18}\/view$/.test(url);
    }


    retrieveExtObjData() {
        this.isLoading = true;
        
        let pickListTypeFieldsArray;
        if (this.pickListTypeFields) {
            pickListTypeFieldsArray = this.pickListTypeFields.split(';');
        }

        fetchRelatedObjectdata({
            recordId: this.recordId,
            FieldsApiNames: this.componentAttributesTypes,
            pickListTypeFields: pickListTypeFieldsArray,
            childApiName: this.childApiName,
            parentObjIdentifier: this.parentObjIdentifier,
            orderByField: this.orderByField,
            recordsLimit: this.recordsLimit,
            sortAscDsc: this.sortAscDsc
        })
        .then(result => {
            if (result && result.length > 0) {
                this.processRecords(result);
                this.listRecordsToDisplay = result;
                this.recCount = result.length;
            } else {
                this.listRecordsToDisplay = [];
                this.recCount = 0;
            }
        })
        .catch(error => {
            this.listRecordsToDisplay = [];
            this.recCount = 0;
            let errorMessage = 'An error occurred while fetching data.';
            if (error && error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error && error.message) {
                errorMessage = error.message;
            }
            this.showErrorToast(errorMessage, 'ERROR: ' + this.relatedListHeader, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    processRecords(records) {
        records.forEach((record, recordIndex) => {
            record.id = recordIndex;
            if (record.fldDefList) {
                record.fldDefList.forEach(field => {
                    // Set field type flags
                    field.isDate = field.dataType === 'DATE';
                    field.isDateTime = field.dataType === 'DATETIME';
                    field.isDouble = field.dataType === 'DOUBLE';
                    field.isExternalId = field.fieldAPIName === 'ExternalId';
                    field.isReference = field.dataType === 'REFERENCE';
                    field.isText = !field.isDate && !field.isDateTime && !field.isDouble && 
                                  !field.isExternalId && !field.isReference;

                    // Set URLs for links
                    if (field.isExternalId && field.childRecordId) {
                        field.recordUrl = `/lightning/r/${field.childRecordId}/view`;
                    }

                    if (field.isReference) {
                        field.isIndivArtFees = this.childApiName === this.indivArtFees;
                        field.isUserReference = field.fieldAPIName === 'createdbyid__c' || 
                                              field.fieldAPIName === 'lastmodifiedbyid__c';
                        if (field.isIndivArtFees && field.parentRecordId) {
                            field.parentRecordUrl = `/lightning/r/${field.parentRecordId}/view`;
                        }
                    }
                });
            }
        });
    }


    navigateToChildComponent() {
        if (this.showMore) {
            // Store large data in sessionStorage to avoid URL length limits
            const navigationKey = 'customRelatedList_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            const navigationData = {
                listRecordsToDisplay: this.listRecordsToDisplay,
                recCount: this.recCount
            };
            sessionStorage.setItem(navigationKey, JSON.stringify(navigationData));
            
            // Use Aura wrapper component for proper navigation with browser history
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__component',
                attributes: {
                    componentName: 'c__customRelatedListExternalObj_lwc_wrapper'
                },
                state: {
                    c__sortAscDsc: this.sortAscDsc,
                    c__orderByField: this.orderByField,
                    c__relatedListHeader: this.relatedListHeader,
                    c__parentObjIdentifier: this.parentObjIdentifier,
                    c__childApiName: this.childApiName,
                    c__pickListTypeFields: this.pickListTypeFields,
                    c__componentAttributesValues: this.componentAttributesValues,
                    c__componentAttributes: this.componentAttributes,
                    c__componentAttributesTypes: this.componentAttributesTypes,
                    c__recordId: this.recordId,
                    c__isNavigateToCmp: true,
                    c__showMore: false,
                    c__navigationKey: navigationKey,
                    c__returnBackToCaseCommentsList: this.returnBackToCaseCommentsList
                }
            }).then(url => {
                window.open(url, '_self');
            }).catch(error => {
                console.error('Error details:', JSON.stringify(error));
            });
        } else {
            window.history.back();
        }
    }


    sortColumn(event) {
        if (!this.showMore) {
            const fieldName = event.currentTarget.dataset.field;
            this.orderByField = fieldName;
            this.sortAscDsc = (!this.sortAscDsc || this.sortAscDsc === 'ASC') ? 'DESC' : 'ASC';
            this.retrieveExtObjData();
        }
    }

    showErrorToast(message, title, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }
}