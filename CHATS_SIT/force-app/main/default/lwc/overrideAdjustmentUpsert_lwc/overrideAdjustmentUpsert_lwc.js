import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_COUNTY_FIELD from '@salesforce/schema/T_SBSD_CASE__c.CDE_COUNTY__c';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';

export default class OverrideAdjustmentUpsert_lwc extends NavigationMixin(LightningElement) {

    // ─── Public API Properties ───────────────────────────────────────────────
    @api recordId;
    @api sObjectName;

    // ─── Tracked (Reactive) Properties ───────────────────────────────────────
    @track currentTabNumber = 1;
    @track pageMessages = [];
    @track messageType = null;
    @track fieldValidationErrors = [];
    @track adjustment = { sobjectType: 'T_ADJMT__c', attributes: { type: 'T_ADJMT__c' } };
    @track parentId;
    @track fieldDefinition = [];
    @track initDataLoaded = false;

    // ─── Tracked: active case ID driving the single county wire ──────────────
    // Populated from one of two sources:
    //   1. On load  — when sObjectName === 'T_SBSD_CASE__c', set to recordId (connectedCallback)
    //   2. At runtime — when user picks / changes IDN_CASE__c in the form (handleSObjectUpdate)
    // Cleared when user removes the case from the form, which unlocks county.
    @track _activeCaseId;

    // ─── Non-Reactive Properties ──────────────────────────────────────────────
    showSpinner = false;
    errorComponentIds = [];

    // ─── Component Configuration (mirrors Aura default attribute values) ──────
    objectName = 'T_ADJMT__c';

    fieldNames = [
        'T_ADJMT__c.CDE_STATUS_ADJMT__c',
        'T_ADJMT__c.CDE_COUNTY__c',
        'T_ADJMT__c.IDN_CASE__c',
        'T_ADJMT__c.IDN_PROVR__c',
        'T_ADJMT__c.CDE_AGNST_ADJMT__c',
        'T_ADJMT__c.CDE_TYPE_ADJMT__c',
        'T_ADJMT__c.DTE_START_ADJMT__c',
        'T_ADJMT__c.DTE_END_ADJMT__c',
        'T_ADJMT__c.DTE_DISCV_ADJMT_ORIG__c'
    ];

    sectionInformation = {
        'CDE_STATUS_ADJMT__c': 'Information'
    };

    requiredFields = [
        'T_ADJMT__c.CDE_STATUS_ADJMT__c',
        'T_ADJMT__c.CDE_COUNTY__c',
        'T_ADJMT__c.CDE_AGNST_ADJMT__c',
        'T_ADJMT__c.CDE_TYPE_ADJMT__c',
        'T_ADJMT__c.DTE_END_ADJMT__c',
        'T_ADJMT__c.DTE_START_ADJMT__c'
    ];

    // ─── Wire: Single county fetch — reacts to _activeCaseId ─────────────────
    // Fires automatically whenever _activeCaseId changes (on load for case page,
    // or at runtime when the user picks / changes IDN_CASE__c in the form).
    // When _activeCaseId is null/undefined the wire does not fire.
    @wire(getRecord, { recordId: '$_activeCaseId', fields: [CASE_COUNTY_FIELD] })
    handleWiredCaseCounty({ data, error }) {
        if (data && this._activeCaseId) {
            const countyValue = getFieldValue(data, CASE_COUNTY_FIELD);
            // Stamp county and lock the field
            this.adjustment = { ...this.adjustment, CDE_COUNTY__c: countyValue || null };
            this._setCountyReadOnly(true);
        } else if (error) {
            console.error('Error fetching case county:', JSON.stringify(error));
        }
    }

    // ─── Computed Getters ─────────────────────────────────────────────────────

    /**
     * Returns 'CREATE NEW' when no parentId exists (insert mode), 'EDIT' otherwise.
     */
    get cardTitle() {
        return this.parentId ? 'EDIT' : 'CREATE NEW';
    }

    /**
     * Controls visibility of the tab-1 content section.
     */
    get isCurrentTab() {
        return this.currentTabNumber === 1 && this.fieldDefinition && this.fieldDefinition.length > 0;
    }

    /**
     * Indicates whether page-level messages are present.
     */
    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }

    /**
     * True when the component is hosted on a T_SBSD_CASE__c record page.
     */
    get isCaseContext() {
        return this.sObjectName === 'T_SBSD_CASE__c';
    }

    // ─── Lifecycle Hooks ──────────────────────────────────────────────────────

    /**
     * Mirrors Aura doInit:
     *   - Sets parentId when objectName matches sObjectName (edit mode)
     *   - Seeds _activeCaseId when on a Case page so the wire fires immediately on load
     *   - Kicks off getInitData
     */
    connectedCallback() {
        if (this.objectName === this.sObjectName) {
            this.parentId = this.recordId;
        }
        // Seed the case ID so the single county wire fires on load for case pages
        if (this.isCaseContext && this.recordId) {
            this._activeCaseId = this.recordId;
        }
        this.getInitData();
    }

    // ─── Initialisation / Data Loading ───────────────────────────────────────

    /**
     * Mirrors Aura helper.getInitData:
     *   1. Calls DynamicFormGenerationController.getFieldDefinition
     *   2. Processes field definitions (preSectionName, fieldUtilityPicklistFieldName,
     *      referenced-object pre-population, context-based disabled fields)
     *   3. Marks required fields
     *   4. If parentId exists, calls getDataOnLoadInCHATS to load existing record data
     */
    getInitData() {
        this.showSpinner = true;

        helper.callServer(
            this,
            'DynamicFormGenerationController',
            'getFieldDefinition',
            (function (response) {
                if (response) {
                    this.processFieldDefinitions(response);
                    this.includeRequiredFieldInFieldDefinition();

                    if (this.parentId) {
                        const dataString = JSON.stringify(response);
                        helper.callServer(
                            this,
                            'DynamicFormGenerationController',
                            'getDataOnLoadInCHATS',
                            (function (dataResponse) {
                                this.showSpinner = false;
                                console.log('Data response from getDataOnLoadInCHATS:', JSON.stringify(dataResponse));
                                if (dataResponse) {
                                    this.adjustment = dataResponse;
                                }
                                this.initDataLoaded = true;
                            }).bind(this),
                            JSON.stringify({ fieldList: dataString, sObjectId: this.parentId })
                        );
                    } else {
                        this.showSpinner = false;
                        this.initDataLoaded = true;
                    }
                }
            }).bind(this),
            JSON.stringify({ lstObjectToField: this.fieldNames })
        );
    }

    /**
     * Processes raw field definitions returned from getFieldDefinition:
     *   - Assigns preSectionName and sectionBreakerPoint from sectionInformation map
     *   - Sets fieldUtilityPicklistFieldName for CDE_STATUS_ADJMT__c and CDE_TYPE_ADJMT__c
     *   - Pre-populates and disables the lookup field whose referenecedObjectName matches
     *     the current sObjectName (e.g. IDN_CASE__c on a Case page, IDN_PROVR__c on a Provider page)
     *   - On a Case page: marks CDE_COUNTY__c as read-only up front (value stamped by wire)
     */
    processFieldDefinitions(fieldDefinitions) {
        let sectionBreakerPoint = 0;

        fieldDefinitions.forEach((fieldDefinition, index) => {
            // ── Section header injection ──────────────────────────────────────
            if (this.sectionInformation[fieldDefinition.fieldAPIName]) {
                fieldDefinition.preSectionName = this.sectionInformation[fieldDefinition.fieldAPIName];
                if (index !== 0 && sectionBreakerPoint % 2 === 0) {
                    fieldDefinition.sectionBreakerPoint = true;
                    sectionBreakerPoint = 0;
                } else {
                    sectionBreakerPoint++;
                }
            }

            // ── Field Utility picklist overrides ──────────────────────────────
            if (fieldDefinition.fieldAPIName === 'CDE_STATUS_ADJMT__c') {
                fieldDefinition.fieldUtilityPicklistFieldName = 'Restricted_Adjustment_Status__c';
            } else if (fieldDefinition.fieldAPIName === 'CDE_TYPE_ADJMT__c') {
                fieldDefinition.fieldUtilityPicklistFieldName = 'Restricted_Adjustment_Type__c';
            }

            // ── Pre-populate and disable the context lookup field ─────────────
            // When launched from a record page (Case or Provider), pre-populate the
            // corresponding lookup field with recordId and disable it so it cannot be changed.
            if (
                fieldDefinition.referenecedObjectName &&
                this.sObjectName === fieldDefinition.referenecedObjectName
            ) {
                this.adjustment = {
                    ...this.adjustment,
                    [fieldDefinition.fieldAPIName]: this.recordId
                };
                fieldDefinition.readOnly = true;
            }

            // ── Sibling lookup: disable the cross-context lookup ─────────────
            // On a Case page     → IDN_PROVR__c disabled (provider not relevant to case context)
            // On a Provider page → IDN_CASE__c  disabled (case not relevant to provider context)
            if (this.isCaseContext && fieldDefinition.fieldAPIName === 'IDN_PROVR__c') {
                fieldDefinition.readOnly = true;
            }
            if (this.sObjectName === 'T_CHATS_PROVR_STATUS__c' && fieldDefinition.fieldAPIName === 'IDN_CASE__c') {
                fieldDefinition.readOnly = true;
            }

            // ── Case context: mark CDE_COUNTY__c read-only up front ───────────
            // The county value itself is stamped by the wire handler (handleWiredCaseCounty).
            // We only need to flag it here so the field renders as read-only from the start.
            if (fieldDefinition.fieldAPIName === 'CDE_COUNTY__c' && this.isCaseContext) {
                fieldDefinition.readOnly = true;
            }
        });

        fieldDefinitions.forEach(fieldDefinition => {
            fieldDefinition.errorKey = `${fieldDefinition.objectName}-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.errorMessage = null;
            fieldDefinition.sectionBreakKey = `break-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.sectionHeaderKey = `header-${fieldDefinition.fieldAPIName}`;
        });

        this.fieldDefinition = fieldDefinitions;
    }

    /**
     * Marks each field definition as required/not-required based on the
     * requiredFields configuration array.
     */
    includeRequiredFieldInFieldDefinition() {
        this.fieldDefinition.forEach(fieldDefinition => {
            const fieldKey = `${fieldDefinition.objectName}.${fieldDefinition.fieldAPIName}`;
            fieldDefinition.required = this.requiredFields.includes(fieldKey);
        });
    }

    // ─── Event Handlers ───────────────────────────────────────────────────────

    /**
     * Mirrors Aura doFinish:
     *   1. Validates all c-dynamic-form-generator_lwc child components
     *   2. On valid: calls checkCountyWithUserCounty
     *      - County matched  → calls upsertRecordsFinal then navigates to saved record
     *      - County mismatch → sets page error message
     *   3. On invalid: sets ERRORS_ON_THIS_PAGE message
     */
    handleFinish() {
        const dynamicFormGenerators = this.template.querySelectorAll('c-dynamic-form-generator_lwc');
        let isValid = true;

        dynamicFormGenerators.forEach(generator => {
            const result = generator.validateAndSetData();
            isValid = isValid && result;
        });

        if (isValid) {
            abs_helper.callServerAndHandleError(
                this,
                'DynamicFormGenerationController',
                'checkCountyWithUserCounty',
                (function (response) {
                    if (response.objectData && response.objectData.countyMatched === true) {
                        this.upsertAdjustmentRecord();
                    } else {
                        const countyName = (response.objectData && response.objectData.countyName)
                            ? response.objectData.countyName
                            : '';
                        this.pageMessages = [{
                            id: 'error-county',
                            message: `The adjustment that you are trying to create is with ${countyName} county. This does not match your assigned county(ies).`
                        }];
                        this.messageType = 'error';
                    }
                }).bind(this),
                JSON.stringify({ countyId: this.adjustment.CDE_COUNTY__c }),
                null
            );
        } else {
            this.pageMessages = [{ id: 'error-validation', message: label.ERRORS_ON_THIS_PAGE }];
            this.messageType = 'error';
        }
    }

    /**
     * Mirrors Aura doCancel: navigates back in browser history.
     */
    handleCancel() {
        window.history.back();
    }

    /**
     * Handles the sObjectUpdate event fired by c-dynamic-form-generator_lwc
     * when a field value changes. Clears page messages and field errors,
     * then updates the adjustment record with the new field value.
     *
     * IDN_CASE__c change logic (skipped on Case record pages — county always locked there):
     *   - Case selected / changed → _activeCaseId updated → wire fires → county stamped + locked
     *   - Case cleared            → _activeCaseId nulled  → county unlocked + cleared
     */
    handleSObjectUpdate(event) {
        this.pageMessages = [];
        this.fieldValidationErrors = [];
        this.handleFieldValidationErrors();

        if (event && event.detail && event.detail.record) {
            const newRecord = event.detail.record;
            // LOOP PREVENTION: Only update if data actually changed
            const currentKey = this.adjustment ? JSON.stringify(this.adjustment) : '';
            const newKey = JSON.stringify(newRecord);
            if (currentKey === newKey) return;

            const previousCaseId = this.adjustment ? this.adjustment.IDN_CASE__c : null;
            this.adjustment = newRecord;

            // County is always locked on a Case page — skip dynamic logic there
            if (!this.isCaseContext) {
                const newCaseId = newRecord.IDN_CASE__c;

                if (newCaseId && newCaseId !== previousCaseId) {
                    // Case selected or swapped — update active ID, wire re-fires automatically
                    this._activeCaseId = newCaseId;
                } else if (!newCaseId && previousCaseId) {
                    // Case cleared — null out active ID, unlock and clear county
                    this._activeCaseId = null;
                    this._setCountyReadOnly(false);
                    this.adjustment = { ...this.adjustment, CDE_COUNTY__c: null };
                }
            }
        }
        event.stopPropagation();
    }

    /**
     * Mirrors Aura doHandleFieldValidationErrors.
     * Maps server-side field validation errors to c-field-level-message_lwc
     * child components by errorKey. Clears stale error messages.
     */
    handleFieldValidationErrors() {
        const fieldValidationErrors = this.fieldValidationErrors;
        const newErrorComponentIds = [];
        const errorComponentIds = this.errorComponentIds;
        const errorMessageComps = this.template.querySelectorAll('c-field-level-message_lwc');

        if (fieldValidationErrors && fieldValidationErrors.length > 0) {
            for (let i = 0; i < fieldValidationErrors.length; i++) {
                const errorKey = `${fieldValidationErrors[i].sObjectName}-${fieldValidationErrors[i].fieldName}`;

                for (let j = 0; j < errorMessageComps.length; j++) {
                    const errorMessageComp = errorMessageComps[j];
                    const componentErrorKey = errorMessageComp.errorKey;

                    if (componentErrorKey === errorKey) {
                        errorMessageComp.message = fieldValidationErrors[i].errorMessage;
                        newErrorComponentIds.push(errorKey);
                        break;
                    }
                }
            }
        }

        // Clear messages for components that are no longer in error
        for (let i = 0; i < errorComponentIds.length; i++) {
            if (newErrorComponentIds.indexOf(errorComponentIds[i]) < 0) {
                errorMessageComps.forEach(errorMessageComp => {
                    if (errorMessageComp.errorKey === errorComponentIds[i]) {
                        errorMessageComp.message = null;
                    }
                });
            }
        }

        this.errorComponentIds = newErrorComponentIds;
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    /**
     * Toggles the readOnly flag on CDE_COUNTY__c in the fieldDefinition array.
     * Replaces the array reference to trigger LWC reactivity.
     * Called by the wire handler (lock) and when the case is cleared (unlock).
     */
    _setCountyReadOnly(isReadOnly) {
        this.fieldDefinition = this.fieldDefinition.map(fd => {
            if (fd.fieldAPIName === 'CDE_COUNTY__c') {
                return { ...fd, readOnly: isReadOnly };
            }
            return fd;
        });
    }

    /**
     * Calls GenericDataSaverApxCtrl.upsertRecordsFinal with the current
     * adjustment record. On success, navigates to the upserted record.
     */
    upsertAdjustmentRecord() {
        const record = { ...this.adjustment, attributes: { type: this.objectName } };

        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecordsFinal',
            (function (response) {
                if (
                    response.objectData &&
                    response.objectData.upsertedRecords &&
                    response.objectData.upsertedRecords.length > 0
                ) {
                    const savedRecordId = response.objectData.upsertedRecords[0].Id;
                    helper.redirectToRecord(this, savedRecordId);
                }
            }).bind(this),
            JSON.stringify({ lstSObject: [record], isFinalStep: true }),
            'Record has been successfully saved.'
        );
    }
}