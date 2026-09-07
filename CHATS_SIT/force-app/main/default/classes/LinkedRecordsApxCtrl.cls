/*
 * Generic Apex controller for the linkedRecords_lwc component.
 * Handles fetching, creating, and deleting junction object records.
 */
public with sharing class LinkedRecordsApxCtrl implements IRequest {

    private static Map<String, Object> requestObj;

    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;

        if (String.isNotBlank(jsonParam)) {
            requestObj = (Map<String, Object>) JSON.deserializeUntyped(jsonParam);
        }

        if (methodName == 'getLinkedRecords') {
            response = getLinkedRecords(
                getParam('junctionObjectApiName'),
                getParam('sourceField'),
                getParam('relatedField'),
                getParam('recordId'),
                getParam('relatedRecordNameField')
            );

        } else if (methodName == 'createLinkedRecord') {
            response = createLinkedRecord(
                getParam('junctionObjectApiName'),
                getParam('sourceField'),
                getParam('relatedField'),
                getParam('recordId'),
                getParam('relatedRecordId')
            );

        } else if (methodName == 'deleteLinkedRecord') {
            response = deleteLinkedRecord(getParam('junctionRecordId'));

        } else if (methodName == 'checkIsAdmin') {
            response = checkIsAdmin();
        }

        return response;
    }

    private static String getParam(String key) {
        if (requestObj == null) return null;
        Object val = requestObj.get(key);
        return val != null ? String.valueOf(val) : null;
    }

    private static LightningServerResponse getLinkedRecords(
        String junctionObjectApiName,
        String sourceField,
        String relatedField,
        String recordIdStr,
        String relatedRecordNameField
    ) {
        try {
            if (String.isBlank(junctionObjectApiName) || String.isBlank(sourceField)
                    || String.isBlank(relatedField)   || String.isBlank(recordIdStr)) {
                return new LightningServerResponse(false, 'Missing required parameters.', null);
            }

            Id recordId = (Id) recordIdStr;

            // Validate object and fields exist before building dynamic SOQL
            Schema.SObjectType junctionSobjectType = Schema.getGlobalDescribe().get(junctionObjectApiName);
            if (junctionSobjectType == null) {
                return new LightningServerResponse(false, 'Object not found: ' + junctionObjectApiName, null);
            }

            String nameField = String.isNotBlank(relatedRecordNameField) ? relatedRecordNameField : 'Name';

            // Build SOQL: select both lookup fields so we can resolve the "other side"
            String soql =
                'SELECT Id, ' + sourceField + ', ' + relatedField + ' '
              + 'FROM ' + junctionObjectApiName + ' '
              + 'WHERE ' + sourceField + ' = :recordId '
              + 'OR ' + relatedField + ' = :recordId '
              + 'WITH SECURITY_ENFORCED '
              + 'ORDER BY CreatedDate DESC';

            List<SObject> junctionRows = Database.query(soql);

            // Collect all "other side" IDs so we can bulk-query their names
            Set<Id>    relatedIds     = new Set<Id>();
            Map<Id, Boolean> isSourceMap = new Map<Id, Boolean>();

            for (SObject row : junctionRows) {
                Id sourceId  = (Id) row.get(sourceField);
                Id relatedId = (Id) row.get(relatedField);
                Boolean isSource = (sourceId == recordId);
                isSourceMap.put(row.Id, isSource);
                Id otherId = isSource ? relatedId : sourceId;
                if (otherId != null) relatedIds.add(otherId);
            }

            // Determine the related object API name from the first row's "other side" ID
            Map<Id, String> nameByRelatedId = new Map<Id, String>();
            if (!relatedIds.isEmpty()) {
                // Derive SObject type from one of the IDs
                Id sampleId            = new List<Id>(relatedIds)[0];
                String relatedObjName  = sampleId.getSObjectType().getDescribe().getName();

                String nameSoql =
                    'SELECT Id, ' + nameField + ' '
                  + 'FROM ' + relatedObjName + ' '
                  + 'WHERE Id IN :relatedIds '
                  + 'WITH SECURITY_ENFORCED';

                for (SObject rec : Database.query(nameSoql)) {
                    Object nameVal = rec.get(nameField);
                    nameByRelatedId.put(rec.Id, nameVal != null ? String.valueOf(nameVal) : '—');
                }
            }

            // Build response rows
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject row : junctionRows) {
                Id sourceId  = (Id) row.get(sourceField);
                Id relatedId = (Id) row.get(relatedField);
                Boolean isSource = isSourceMap.get(row.Id);
                Id otherId   = isSource ? relatedId : sourceId;

                rows.add(new Map<String, Object>{
                    'junctionId'        => row.Id,
                    'relatedRecordId'   => otherId,
                    'relatedRecordName' => nameByRelatedId.containsKey(otherId)
                                            ? nameByRelatedId.get(otherId)
                                            : String.valueOf(otherId),
                    'isSourceSide'      => isSource
                });
            }

            return new LightningServerResponse(true, '',
                new Map<String, Object>{ 'records' => rows });

        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    private static LightningServerResponse createLinkedRecord(
        String junctionObjectApiName,
        String sourceField,
        String relatedField,
        String recordIdStr,
        String relatedRecordIdStr
    ) {
        try {
            if (String.isBlank(junctionObjectApiName) || String.isBlank(sourceField)
                    || String.isBlank(relatedField)   || String.isBlank(recordIdStr)
                    || String.isBlank(relatedRecordIdStr)) {
                return new LightningServerResponse(false, 'Missing required parameters.', null);
            }

            Id recordId        = (Id) recordIdStr;
            Id relatedRecordId = (Id) relatedRecordIdStr;

            if (recordId == relatedRecordId) {
                return new LightningServerResponse(false, 'A record cannot be linked to itself.', null);
            }

            // Duplicate check — check both orientations
            String dupCheckSoql =
                'SELECT Id FROM ' + junctionObjectApiName + ' '
              + 'WHERE ('  + sourceField + ' = :recordId AND ' + relatedField + ' = :relatedRecordId) '
              + 'OR ('    + sourceField + ' = :relatedRecordId AND ' + relatedField + ' = :recordId) '
              + 'WITH SECURITY_ENFORCED '
              + 'LIMIT 1';

            List<SObject> existing = Database.query(dupCheckSoql);
            if (!existing.isEmpty()) {
                return new LightningServerResponse(false, 'These records are already linked.', null);
            }

            // CRUD check on the junction object
            Schema.SObjectType junctionSobjectType = Schema.getGlobalDescribe().get(junctionObjectApiName);
            if (junctionSobjectType == null || !junctionSobjectType.getDescribe().isCreateable()) {
                return new LightningServerResponse(false, 'Insufficient access to create ' + junctionObjectApiName + '.', null);
            }

            SObject junctionRecord = junctionSobjectType.newSObject();
            junctionRecord.put(sourceField, recordId);
            junctionRecord.put(relatedField, relatedRecordId);

            insert junctionRecord;

            return new LightningServerResponse(true, 'Record linked successfully.',
                new Map<String, Object>{ 'junctionId' => junctionRecord.Id });

        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    private static LightningServerResponse checkIsAdmin() {
        Boolean isAdmin = FeatureManagement.checkPermission('System_Administrator');
        return new LightningServerResponse(true, '', new Map<String, Object>{ 'isAdmin' => isAdmin });
    }

    private static LightningServerResponse deleteLinkedRecord(String junctionRecordIdStr) {
        try {
            if (String.isBlank(junctionRecordIdStr)) {
                return new LightningServerResponse(false, 'Missing junction record Id.', null);
            }

            Id junctionRecordId = (Id) junctionRecordIdStr;

            // Determine the SObject type dynamically from the ID prefix
            Schema.SObjectType junctionSobjectType = junctionRecordId.getSObjectType();
            if (!junctionSobjectType.getDescribe().isDeletable()) {
                return new LightningServerResponse(false, 'Insufficient access to delete this record.', null);
            }

            SObject toDelete = junctionSobjectType.newSObject(junctionRecordId);
            delete toDelete;

            return new LightningServerResponse(true, 'Link removed successfully.', null);

        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }
}