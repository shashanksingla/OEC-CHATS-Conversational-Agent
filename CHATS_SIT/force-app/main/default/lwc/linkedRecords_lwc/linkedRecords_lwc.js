import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';

const APEX_CLASS = 'LinkedRecordsApxCtrl';

export default class LinkedRecords_lwc extends LightningElement {
    @api recordId;
    @api junctionObjectApiName;
    @api sourceField;
    @api relatedField;
    @api relatedObjectApiName;
    @api componentTitle = 'Linked Records';
    @api iconName = 'standard:record';
    @api relatedObjectLabel = 'Record';
    @api relatedRecordNameField = 'Name';

    @track linkedRecords = [];

    showSpinner    = false;
    showModal      = false;
    showDeleteModal = false;
    isSaving       = false;
    isDeleting     = false;
    isAdmin        = false;
    error          = null;

    modalError         = '';
    selectedRecordId   = null;   // lookup selection inside the modal
    deleteTargetId     = null;   // junction record Id to delete
    deleteTargetName   = '';     // display name for the confirmation modal

    connectedCallback() {
        this.checkAdminAccess();
        this.loadLinkedRecords();
    }

    get hasRecords() {
        return this.linkedRecords && this.linkedRecords.length > 0;
    }

    get isEmpty() {
        return !this.showSpinner && (!this.linkedRecords || this.linkedRecords.length === 0);
    }

    checkAdminAccess() {
        helper.callServer(this, APEX_CLASS, 'checkIsAdmin', (response) => {
            if (response.isSuccessful) {
                this.isAdmin = response.objectData?.isAdmin === true;
            }
        }, null);
    }

    loadLinkedRecords() {
        if (!this.recordId || !this.junctionObjectApiName || !this.sourceField || !this.relatedField) {
            return;
        }

        const params = JSON.stringify({
            junctionObjectApiName  : this.junctionObjectApiName,
            sourceField            : this.sourceField,
            relatedField           : this.relatedField,
            recordId               : this.recordId,
            relatedRecordNameField : this.relatedRecordNameField
        });

        helper.callServer(this, APEX_CLASS, 'getLinkedRecords', (response) => {
            if (response.isSuccessful) {
                const rows = response.objectData?.records || [];
                this.linkedRecords = rows.map(r => ({
                    ...r,
                    recordUrl: '/' + r.relatedRecordId
                }));
            } else {
                helper.showToast(this, 'Error', response.errorMessage || 'Failed to load linked records.', 'error');
            }
        }, params);
    }

    handleOpenModal() {
        this.selectedRecordId = null;
        this.modalError       = '';
        this.showModal        = true;
    }

    handleCloseModal() {
        this.showModal        = false;
        this.selectedRecordId = null;
        this.modalError       = '';
        // Clear the lookup inside the modal
        const lookup = this.template.querySelector('c-custom-lookup_lwc');
        if (lookup) lookup.clearSelectedValue();
    }


    handleLookupSelect(event) {
        this.selectedRecordId = event.detail?.record?.Id || null;
        if (this.selectedRecordId) {
            this.modalError = '';
        }
    }

    handleSaveLink() {
        if (!this.selectedRecordId) {
            this.modalError = 'Please select a record to link.';
            return;
        }

        this.isSaving  = true;
        this.modalError = '';

        const params = JSON.stringify({
            junctionObjectApiName : this.junctionObjectApiName,
            sourceField           : this.sourceField,
            relatedField          : this.relatedField,
            recordId              : this.recordId,
            relatedRecordId       : this.selectedRecordId
        });

        helper.callServer(this, APEX_CLASS, 'createLinkedRecord', (response) => {
            this.isSaving = false;
            if (response.isSuccessful) {
                this.showModal = false;
                helper.showToast(this, 'Success', 'Record linked successfully.', 'success');
                this.loadLinkedRecords();
            } else {
                this.modalError = response.errorMessage || 'Failed to create link.';
            }
        }, params);
    }

    handleDeleteClick(event) {
        this.deleteTargetId   = event.currentTarget.dataset.junctionId;
        this.deleteTargetName = event.currentTarget.dataset.recordName;
        this.showDeleteModal  = true;
    }

    handleCancelDelete() {
        this.showDeleteModal  = false;
        this.deleteTargetId   = null;
        this.deleteTargetName = '';
    }

    handleConfirmDelete() {
        if (!this.deleteTargetId) return;

        this.isDeleting = true;

        const params = JSON.stringify({
            junctionRecordId : this.deleteTargetId
        });

        helper.callServer(this, APEX_CLASS, 'deleteLinkedRecord', (response) => {
            this.isDeleting      = false;
            this.showDeleteModal = false;
            this.deleteTargetId  = null;
            if (response.isSuccessful) {
                helper.showToast(this, 'Success', 'Link removed successfully.', 'success');
                this.loadLinkedRecords();
            } else {
                helper.showToast(this, 'Error', response.errorMessage || 'Failed to remove link.', 'error');
            }
        }, params);
    }
}