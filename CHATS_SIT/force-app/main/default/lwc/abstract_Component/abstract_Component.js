import { helper } from 'c/generic_Utilities';

export const abs_helper = {
    /** -------------functions extracted from AbstractSection.js and AbstractComponent.js(Aura)  START ----------------*/
    callServerAndHandleError(cmp, className, method, callback, params, successMessage) {
        cmp.pageMessages = [];
        cmp.fieldValidationErrors = [];
        cmp.messageType = null;
        helper.callServer(cmp, className, method, function (response) {
            // pass returned value to callback function
            if (response.isSuccessful == true) {
                callback.call(this, response);
                if (successMessage) {
                    cmp.pageMessages = [{ 'id': 'success', 'message': successMessage }];
                    cmp.messageType = "success";
                }
            } else {
                var pageMessages = [{ 'id': 'error', 'message': response.errorMessage }];
                var messageType = response.messageType || 'error';
                var lstAPXFieldValidationError = response.lstAPXFieldValidationError;
                if (lstAPXFieldValidationError) {
                    var lstOnlyAPXFieldValidationError = [];
                    for (var i = 0; i < lstAPXFieldValidationError.length; i++) {
                        if (lstAPXFieldValidationError[i].isTopOfPageError == true) {
                            pageMessages.push({ 'id': 'error', 'message': lstAPXFieldValidationError[i].errorMessage });
                        } else {
                            lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                        }
                    }
                    cmp.fieldValidationErrors = [...cmp.fieldValidationErrors, ...lstOnlyAPXFieldValidationError];
                    if (cmp.handleFieldValidationErrors && typeof cmp.handleFieldValidationErrors === 'function') {
                        cmp.handleFieldValidationErrors();
                    }
                }
                var missingPageMessages = [];
                if (response.objectData != undefined) {
                    var dmlErrMessages = response.objectData.dmlErrorMessages;
                    if (dmlErrMessages && dmlErrMessages.length > 0) {
                        for (var i = 0; i < dmlErrMessages.length; i++) {
                            missingPageMessages.push(dmlErrMessages[i]);
                        }
                    }
                }
                cmp.missingPageMessages = missingPageMessages;
                cmp.pageMessages = pageMessages;
                cmp.messageType = messageType;
                cmp.showSpinner = false;
            }
        }, params);
    },
    callServerAndDeleteRecordsByIds(cmp, callback, recordIdsToBeDeleted) {
        const params = { 'idsToBeDeleted': recordIdsToBeDeleted };
        abs_helper.callServerAndHandleError(cmp, 'GenericDataSaverApxCtrl', 'deleteJunkRecordsByIds', function (response) {
            callback.call(this, response);
        }, JSON.stringify(params), null);
    },
    callServerAndDeleteRecords(cmp, callback, recordsToBeDeleted) {
        var onlyRecordsToBeDeleted = [];
        recordsToBeDeleted.forEach(rec => {
            if (rec.Id != undefined && rec.Id != null && rec.Id != '') {
                onlyRecordsToBeDeleted.push(rec);
            }
        });
        const params = { 'recordsToBeDeleted': onlyRecordsToBeDeleted };
        abs_helper.callServerAndHandleError(cmp, 'GenericDataSaverApxCtrl', 'deleteJunkRecords', function (response) {
            callback.call(this, response);
        }, JSON.stringify(params), null);
    },

    callServerForExternalObjAndHandleError: function (cmp, method, callback, params, successMessage) {
        cmp.pageMessages = [];
        cmp.fieldValidationErrors = [];
        cmp.messageType = null;

        helper.callServer(cmp, 'GenericDataSaverApxCtrl', method, function (response) {
            // pass returned value to callback function
            if (response.isSuccessful == true) {
                callback.call(this, response);
                if (successMessage && successMessage != null) {
                    cmp.pageMessages = [{ 'id': 'success', 'message': successMessage }];
                    cmp.messageType = "success";
                }
            } else {
                var pageMessages = [{ 'id': 'error', 'message': response.errorMessage }];
                var lstAPXFieldValidationError = response.lstAPXFieldValidationError;
                if (lstAPXFieldValidationError) {
                    var lstOnlyAPXFieldValidationError = [];
                    for (var i = 0; i < lstAPXFieldValidationError.length; i++) {
                        if (lstAPXFieldValidationError[i].isTopOfPageError == true) {
                            pageMessages.push({ 'id': 'error', 'message': lstAPXFieldValidationError[i].errorMessage });
                        } else {
                            lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                        }
                    }
                    cmp.fieldValidationErrors = lstOnlyAPXFieldValidationError;
                }
                cmp.pageMessages = pageMessages;
                cmp.messageType = "error"
            }
        }, params);

    },

    handleFieldLevelValidationfunction(cmp) {
        var lstAPXFieldValidationError = cmp.fieldValidationErrors;
        var index = cmp.index;
        var errorComponentIds = cmp.errorComponentIds;
        var newErrorComponentIds = [];
        if (!lstAPXFieldValidationError) {
            for (var i = 0; i < lstAPXFieldValidationError.length; i++) {
                if (!index || index == lstAPXFieldValidationError[i].index) {
                    var errorComponent = cmp.template.querySelector('[data-id="' + lstAPXFieldValidationError[i].sObjectName + "-" + lstAPXFieldValidationError[i].fieldName + '"]')
                    if (errorComponent) {
                        errorComponent.message = lstAPXFieldValidationError[i].errorMessage;
                        newErrorComponentIds.push(lstAPXFieldValidationError[i].sObjectName + "-" + lstAPXFieldValidationError[i].fieldName);
                    }
                }
            }
        }
        for (var i = 0; i < errorComponentIds.length; i++) {
            if (newErrorComponentIds.indexOf(errorComponentIds[i]) < 0) {
                var errorComponent = cmp.template.querySelector('[data-id="' + errorComponentIds[i] + '"]');
                if (errorComponent) {
                    errorComponent.message = null;
                }
            }
        }
        cmp.errorComponentIds = newErrorComponentIds;
    },
    validateCurrentPage(cmp) {
        var inputComponents = cmp.template.querySelectorAll('[data-id="input-field"]'); //cmp.find('input-field');
        var areAllFieldsValid = true;
        if (inputComponents && inputComponents.length > 0) {
            areAllFieldsValid = [...inputComponents]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
        }
        var isRecordValid = typeof cmp.checkCustomValidations === 'function' ? cmp.checkCustomValidations() : this.checkCustomValidations();
        var overallResult = areAllFieldsValid && isRecordValid;
        cmp.isCurrentPageValid = overallResult;
        return overallResult;
    },
    checkCustomValidations() {
        //should be implemented in child component if there are any custom validations.
        return true;
    },
    setFieldValueForReport(cmp) {
        var dataValue = cmp.initData;
        if (dataValue[cmp.associatedObjName]) {
            if (cmp.fieldType == 'REFERENCE') {
                dataValue[cmp.associatedObjName][0][cmp.fieldAPIName] = cmp.lookupFieldValue;
            } else {
                dataValue[cmp.associatedObjName][0][cmp.fieldAPIName] = cmp.fieldValue;
            }
        } else {
            if (cmp.fieldType == 'REFERENCE') {
                dataValue[cmp.associatedObjName] = [{}];
                dataValue[cmp.associatedObjName][0][cmp.fieldAPIName] = cmp.lookupFieldValue;
            } else {
                dataValue[cmp.associatedObjName] = [{}];
                dataValue[cmp.associatedObjName][0][cmp.fieldAPIName] = cmp.fieldValue;
            }
        }

        if (cmp.isControllingField) {
            cmp.isControllingFieldUpdated = true;
        } else {
            cmp.isControllingFieldUpdated = false;
        }
        cmp.initData = dataValue;
    }
    /** -------------functions extracted from AbstractSection.js and AbstractComponent.js(Aura)  END ----------------*/
}