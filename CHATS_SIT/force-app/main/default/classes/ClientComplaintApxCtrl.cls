public with sharing class ClientComplaintApxCtrl implements IRequest {

    private static Map<String, Object> requestObj;

    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        if (String.isNotBlank(jsonParam)) {
            requestObj = (Map<String, Object>) JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'saveComplaint') {
            response = saveComplaint(
                (Map<String, Object>) requestObj.get('complaintData'),
                getParam('noteText')
            );
        } else if (methodName == 'getComplaintForEdit') {
            response = getComplaintForEdit(getParam('recordId'));
        } else if (methodName == 'getUserCounties') {
            response = getUserCounties();
        } else if (methodName == 'searchComplaints') {
            response = searchComplaints((Map<String, Object>) requestObj.get('filters'));
        } else if (methodName == 'countyTransfer') {
            response = initiateCountyTransfer(
                getParam('oldComplaintId'),
                getParam('countyId'),
                getParam('notes'),
                getParam('assigneeId')
            );
        }
        return response;
    }

    private static String getParam(String key) {
        if (requestObj == null) return null;
        Object val = requestObj.get(key);
        return val != null ? String.valueOf(val) : null;
    }

    @AuraEnabled
    public static LightningServerResponse saveComplaint(Map<String, Object> complaintData, String noteText) {
        Savepoint sp = Database.setSavepoint();
        try {
            String existingId = complaintData.get('recordId') != null
                ? String.valueOf(complaintData.get('recordId')) : null;
            Boolean isUpdate = String.isNotBlank(existingId);

            Client_Complaint__c complaint;

            if (isUpdate) {
                // Capture old Assignee__c before update to detect a change
                Id newAssigneeId = toId(complaintData.get('Assignee__c'));
                Id oldAssigneeId = null;
                List<Client_Complaint__c> existingRec = [
                    SELECT Assignee__c FROM Client_Complaint__c WHERE Id = :(Id) existingId LIMIT 1
                ];
                if (!existingRec.isEmpty()) {
                    oldAssigneeId = existingRec[0].Assignee__c;
                }

                complaint = new Client_Complaint__c(Id = (Id) existingId);
                complaint.Assignee__c                      = newAssigneeId;
                complaint.Person_who_Provided_Complaint__c = toStr(complaintData.get('Person_who_Provided_Complaint__c'));
                complaint.Complaint_Types__c               = toStr(complaintData.get('Complaint_Types__c'));
                complaint.Complaint_Status__c              = toStr(complaintData.get('Complaint_Status__c'));
                complaint.Method_of_Contact__c             = toStr(complaintData.get('Method_of_Contact__c'));
                complaint.Subject__c                       = toStr(complaintData.get('Subject__c'));
                if (complaintData.get('DTE_County_Response__c') != null) {
                    complaint.DTE_County_Response__c = toDate(complaintData.get('DTE_County_Response__c'));
                }
                if (complaintData.get('DTE_Complaint_Resolved__c') != null) {
                    complaint.DTE_Complaint_Resolved__c = toDate(complaintData.get('DTE_Complaint_Resolved__c'));
                }
                GenericDMLHandler.updateRecords(
                    new List<SObject>{ complaint },
                    new Map<String, Object>{ 'Method__c' => 'saveComplaint', 'Class__c' => 'ClientComplaintApxCtrl' },
                    new List<String>{
                        'Assignee__c', 'Person_who_Provided_Complaint__c', 'Complaint_Types__c',
                        'Complaint_Status__c', 'Method_of_Contact__c', 'Subject__c',
                        'DTE_County_Response__c', 'DTE_Complaint_Resolved__c'
                    }
                );

                // Reassign open tasks to new assignee if Assignee__c changed
                if (newAssigneeId != null && newAssigneeId != oldAssigneeId) {
                    ClientComplaintTriggerHandler.reassignOpenTasks((Id) existingId, newAssigneeId);
                }
            } else {
                complaint = new Client_Complaint__c();
                complaint.IDN_CASE__c                      = toId(complaintData.get('IDN_CASE__c'));
                complaint.IDN_PROVR__c                     = toId(complaintData.get('IDN_PROVR__c'));
                complaint.IDN_COUNTY__c                    = toId(complaintData.get('IDN_COUNTY__c'));
                complaint.Assignee__c                      = toId(complaintData.get('Assignee__c'));
                complaint.Person_who_Provided_Complaint__c = toStr(complaintData.get('Person_who_Provided_Complaint__c'));
                complaint.Complaint_Types__c               = toStr(complaintData.get('Complaint_Types__c'));
                complaint.Complaint_Status__c              = toStr(complaintData.get('Complaint_Status__c'));
                complaint.Method_of_Contact__c             = toStr(complaintData.get('Method_of_Contact__c'));
                complaint.Subject__c                       = toStr(complaintData.get('Subject__c'));
                complaint.Complaint_Body__c                = toStr(complaintData.get('Complaint_Body__c'));
                complaint.DTE_Initial_Complaint__c         = toDate(complaintData.get('DTE_Initial_Complaint__c'));
                complaint.DTE_County_Response__c           = toDate(complaintData.get('DTE_County_Response__c'));
                complaint.DTE_Complaint_Resolved__c        = toDate(complaintData.get('DTE_Complaint_Resolved__c'));
                GenericDMLHandler.insertRecords(
                    new List<SObject>{ complaint },
                    false,
                    new Map<String, Object>{ 'Method__c' => 'saveComplaint', 'Class__c' => 'ClientComplaintApxCtrl' },
                    new List<String>{
                        'IDN_CASE__c', 'IDN_PROVR__c', 'IDN_COUNTY__c', 'Assignee__c',
                        'Person_who_Provided_Complaint__c', 'Complaint_Types__c',
                        'Complaint_Status__c', 'Method_of_Contact__c', 'Subject__c',
                        'Complaint_Body__c', 'DTE_Initial_Complaint__c',
                        'DTE_County_Response__c', 'DTE_Complaint_Resolved__c'
                    }
                );
            }

            if (String.isNotBlank(noteText)) {
                Client_Complaint_Note__c noteRec = new Client_Complaint_Note__c(
                    Client_Complaint__c = complaint.Id,
                    Description__c      = noteText
                );
                GenericDMLHandler.insertRecords(
                    new List<SObject>{ noteRec },
                    false,
                    new Map<String, Object>{ 'Method__c' => 'saveComplaint', 'Class__c' => 'ClientComplaintApxCtrl' },
                    new List<String>{ 'Client_Complaint__c', 'Description__c' }
                );
            }

            return new LightningServerResponse(
                true,
                'Complaint saved successfully.',
                new Map<String, Object>{ 'recordId' => complaint.Id }
            );

        } catch (Exception e) {
            Database.rollback(sp);
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static LightningServerResponse getComplaintForEdit(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                return new LightningServerResponse(false, 'Record ID is required.', null);
            }

            List<Client_Complaint__c> complaints = [
                SELECT Id,
                       IDN_CASE__c, IDN_PROVR__c, IDN_COUNTY__c, Assignee__c,
                       Person_who_Provided_Complaint__c,
                       Complaint_Types__c, Complaint_Status__c, Method_of_Contact__c,
                       Subject__c, Complaint_Body__c,
                       DTE_Initial_Complaint__c, DTE_County_Response__c,
                       DTE_Complaint_Resolved__c, DTE_County_Transfer__c
                FROM   Client_Complaint__c
                WHERE  Id = :recordId
                LIMIT  1
            ];

            if (complaints.isEmpty()) {
                return new LightningServerResponse(false, 'Record not found.', null);
            }

            List<Client_Complaint_Note__c> notes = [
                SELECT Id, Description__c, CreatedDate, CreatedBy.Name
                FROM   Client_Complaint_Note__c
                WHERE  Client_Complaint__c = :recordId
                ORDER BY CreatedDate DESC
            ];

            return new LightningServerResponse(
                true,
                '',
                new Map<String, Object>{ 'complaint' => complaints[0], 'notes' => notes }
            );

        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static LightningServerResponse getUserCounties() {
        try {
            List<User> users = [
                SELECT Owner_County__c, Common_County__c
                FROM   User
                WHERE  Id = :UserInfo.getUserId()
                LIMIT  1
            ];

            List<String> countyCodes = new List<String>();
            if (!users.isEmpty()) {
                User u = users[0];
                String rawCounty = String.isNotBlank(u.Owner_County__c)
                    ? u.Owner_County__c
                    : (String.isNotBlank(u.Common_County__c) ? u.Common_County__c : '');
                if (String.isNotBlank(rawCounty)) {
                    for (String c : rawCounty.split(';')) {
                        String trimmed = c.trim();
                        if (String.isNotBlank(trimmed)) {
                            countyCodes.add(trimmed);
                        }
                    }
                }
            }

            List<Map<String, Object>> countyOptions = new List<Map<String, Object>>();
            for (T_COUNTY__c county : [
                SELECT Id, Name, CDE_COUNTY__c
                FROM   T_COUNTY__c
                ORDER BY Name ASC
            ]) {
                String codeStr = county.CDE_COUNTY__c != null
                    ? String.valueOf(county.CDE_COUNTY__c.intValue()) : '';
                countyOptions.add(new Map<String, Object>{ 'label' => county.Name, 'value' => codeStr });
            }

            return new LightningServerResponse(true, '', new Map<String, Object>{
                'countyCodes'   => countyCodes,
                'countyOptions' => countyOptions
            });
        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static LightningServerResponse searchComplaints(Map<String, Object> filters) {
        try {
            List<String>        whereClauses = new List<String>();
            Map<String, Object> bindVars     = new Map<String, Object>();

            Object countyRaw = filters.get('countyIds');
            if (countyRaw != null) {
                List<String> countyIds = (List<String>) JSON.deserialize(JSON.serialize(countyRaw), List<String>.class);
                Boolean includesAllState = false;
                for (String c : countyIds) {
                    if ('66'.equals(c != null ? c.trim() : '')) { includesAllState = true; break; }
                }
                if (!includesAllState && !countyIds.isEmpty()) {
                    List<Decimal> realCodes = new List<Decimal>();
                    for (String c : countyIds) {
                        if (String.isNotBlank(c)) {
                            try { realCodes.add(Decimal.valueOf(c.trim())); } catch (Exception ex) { /* skip */ }
                        }
                    }
                    if (!realCodes.isEmpty()) {
                        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c WHERE CDE_COUNTY__c IN :realCodes];
                        List<Id> countyRecIds = new List<Id>();
                        for (T_COUNTY__c c : counties) countyRecIds.add(c.Id);
                        if (!countyRecIds.isEmpty()) {
                            bindVars.put('countyRecordIds', countyRecIds);
                            whereClauses.add('IDN_COUNTY__c IN :countyRecordIds');
                        }
                    }
                }
            }

            Object statusRaw = filters.get('statuses');
            if (statusRaw != null) {
                List<String> statuses = (List<String>) JSON.deserialize(JSON.serialize(statusRaw), List<String>.class);
                if (!statuses.isEmpty()) {
                    bindVars.put('statuses', statuses);
                    whereClauses.add('Complaint_Status__c IN :statuses');
                }
            }

            Object providerRaw = filters.get('providerIds');
            if (providerRaw != null) {
                List<String> providerIds = (List<String>) JSON.deserialize(JSON.serialize(providerRaw), List<String>.class);
                if (!providerIds.isEmpty()) {
                    bindVars.put('providerIds', providerIds);
                    whereClauses.add('IDN_PROVR__c IN :providerIds');
                }
            }

            Object caseRaw = filters.get('caseIds');
            if (caseRaw != null) {
                List<String> caseIds = (List<String>) JSON.deserialize(JSON.serialize(caseRaw), List<String>.class);
                if (!caseIds.isEmpty()) {
                    bindVars.put('caseIds', caseIds);
                    whereClauses.add('IDN_CASE__c IN :caseIds');
                }
            }

            Object typesRaw = filters.get('complaintTypes');
            if (typesRaw != null) {
                List<String> types = (List<String>) JSON.deserialize(JSON.serialize(typesRaw), List<String>.class);
                if (!types.isEmpty()) {
                    List<String> typeClauses = new List<String>();
                    for (String t : types) {
                        typeClauses.add('Complaint_Types__c INCLUDES (\'' + String.escapeSingleQuotes(t) + '\')');
                    }
                    whereClauses.add('(' + String.join(typeClauses, ' OR ') + ')');
                }
            }

            Object methodsRaw = filters.get('methodsOfContact');
            if (methodsRaw != null) {
                List<String> methods = (List<String>) JSON.deserialize(JSON.serialize(methodsRaw), List<String>.class);
                if (!methods.isEmpty()) {
                    bindVars.put('methodsOfContact', methods);
                    whereClauses.add('Method_of_Contact__c IN :methodsOfContact');
                }
            }

            String recipientType = filters.get('recipientType') != null ? String.valueOf(filters.get('recipientType')) : null;
            if (String.isNotBlank(recipientType)) {
                if (recipientType.equalsIgnoreCase('Case')) {
                    whereClauses.add('IDN_CASE__c != null');
                } else if (recipientType.equalsIgnoreCase('Provider')) {
                    whereClauses.add('IDN_PROVR__c != null');
                }
            }

            String assigneeIdStr = filters.get('assigneeId') != null ? String.valueOf(filters.get('assigneeId')) : null;
            if (String.isNotBlank(assigneeIdStr)) {
                Id assigneeIdVal = (Id) assigneeIdStr;
                bindVars.put('assigneeId', assigneeIdVal);
                whereClauses.add('Assignee__c = :assigneeId');
            }

            String createdByIdStr = filters.get('createdById') != null ? String.valueOf(filters.get('createdById')) : null;
            if (String.isNotBlank(createdByIdStr)) {
                Id createdByIdVal = (Id) createdByIdStr;
                bindVars.put('createdById', createdByIdVal);
                whereClauses.add('CreatedById = :createdById');
            }

            String initBegin = filters.get('initialDateBegin') != null ? String.valueOf(filters.get('initialDateBegin')) : null;
            if (String.isNotBlank(initBegin)) {
                bindVars.put('initBeginDate', Date.valueOf(initBegin));
                whereClauses.add('DTE_Initial_Complaint__c >= :initBeginDate');
            }
            String initEnd = filters.get('initialDateEnd') != null ? String.valueOf(filters.get('initialDateEnd')) : null;
            if (String.isNotBlank(initEnd)) {
                bindVars.put('initEndDate', Date.valueOf(initEnd));
                whereClauses.add('DTE_Initial_Complaint__c <= :initEndDate');
            }

            String respBegin = filters.get('countyResponseBegin') != null ? String.valueOf(filters.get('countyResponseBegin')) : null;
            if (String.isNotBlank(respBegin)) {
                bindVars.put('respBeginDate', Date.valueOf(respBegin));
                whereClauses.add('DTE_County_Response__c >= :respBeginDate');
            }
            String respEnd = filters.get('countyResponseEnd') != null ? String.valueOf(filters.get('countyResponseEnd')) : null;
            if (String.isNotBlank(respEnd)) {
                bindVars.put('respEndDate', Date.valueOf(respEnd));
                whereClauses.add('DTE_County_Response__c <= :respEndDate');
            }

            String soql =
                'SELECT Id, Name, '
                + 'IDN_CASE__c, IDN_CASE__r.Name, '
                + 'IDN_PROVR__c, IDN_PROVR__r.Name, '
                + 'Complaint_Types__c, Complaint_Status__c, '
                + 'Method_of_Contact__c, '
                + 'DTE_Initial_Complaint__c, DTE_County_Response__c, DTE_Complaint_Resolved__c '
                + 'FROM Client_Complaint__c';

            if (!whereClauses.isEmpty()) {
                soql += ' WHERE ' + String.join(whereClauses, ' AND ');
            }
            soql += ' ORDER BY DTE_Initial_Complaint__c DESC NULLS LAST LIMIT 2000';

            List<Client_Complaint__c> records = Database.queryWithBinds(soql, bindVars, AccessLevel.USER_MODE);

            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (Client_Complaint__c r : records) {
                results.add(new Map<String, Object>{
                    'id'                     => r.Id,
                    'name'                   => r.Name,
                    'complaintUrl'           => '/lightning/r/Client_Complaint__c/' + r.Id + '/view',
                    'caseName'               => r.IDN_CASE__r  != null ? r.IDN_CASE__r.Name  : '',
                    'providerName'           => r.IDN_PROVR__r != null ? r.IDN_PROVR__r.Name : '',
                    'complaintTypes'         => r.Complaint_Types__c,
                    'complaintStatus'        => r.Complaint_Status__c,
                    'methodOfContact'        => r.Method_of_Contact__c,
                    'initialDateOfComplaint' => r.DTE_Initial_Complaint__c,
                    'countyResponseDate'     => r.DTE_County_Response__c,
                    'dateComplaintResolved'  => r.DTE_Complaint_Resolved__c
                });
            }

            return new LightningServerResponse(true, '', new Map<String, Object>{ 'complaints' => results });

        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    private static User resolveComplaintOwner(String countyCode) {
        if (String.isBlank(countyCode)) {
            return null;
        }

        List<String> permissionSetNames = new List<String>{
            'Eligibility_Worker_Supervisor_PS',
            'Eligibility_Worker_PS',
            'Universal_User_PS',
            'Provider_Worker_Supervisor_PS',
            'Provider_Worker_PS',
            'Fiscal_Worker_Supervisor_PS',
            'Fiscal_Worker_PS',
            'Business_Office_Supervisor_PS',
            'Business_Office_Worker_PS',
            'Read_Only_User_PS'
        };

        Map<Id, Set<String>> userIdToPermSetNames = new Map<Id, Set<String>>();
        Map<Id, User>        userIdToUserMap      = new Map<Id, User>();

        for (PermissionSetAssignment psa : [
            SELECT AssigneeId, PermissionSet.Name,
                   Assignee.Id, Assignee.Name, Assignee.IsActive, Assignee.Owner_County__c
            FROM   PermissionSetAssignment
            WHERE  PermissionSet.Name IN :permissionSetNames
            AND    Assignee.IsActive = true
            AND    Assignee.Owner_County__c = :countyCode
        ]) {
            if (!userIdToPermSetNames.containsKey(psa.AssigneeId)) {
                userIdToPermSetNames.put(psa.AssigneeId, new Set<String>());
                userIdToUserMap.put(psa.AssigneeId, psa.Assignee);
            }
            userIdToPermSetNames.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }

        List<User> allActiveUsers = userIdToUserMap.values();
        if (Test.isRunningTest()) {
            allActiveUsers = new List<User>();
            for (User u : userIdToUserMap.values()) {
                if (u.Name != null && u.Name.startsWith('UserUpdateBatchTest')) {
                    allActiveUsers.add(u);
                }
            }
        }

        List<User> ewSupervisorUsers       = new List<User>();
        List<User> ewUsers                 = new List<User>();
        List<User> universalUsers          = new List<User>();
        List<User> providerSupervisorUsers = new List<User>();
        List<User> providerWorkerUsers     = new List<User>();
        List<User> fiscalSupervisorUsers   = new List<User>();
        List<User> fiscalWorkerUsers       = new List<User>();
        List<User> boSupervisorUsers       = new List<User>();
        List<User> boWorkerUsers           = new List<User>();
        List<User> readOnlyUsers           = new List<User>();

        for (User activeUser : allActiveUsers) {
            Set<String> userPermSets = userIdToPermSetNames.get(activeUser.Id);
            if (userPermSets == null) { continue; }

            if (userPermSets.contains('Eligibility_Worker_Supervisor_PS')) { ewSupervisorUsers.add(activeUser); }
            if (userPermSets.contains('Eligibility_Worker_PS'))            { ewUsers.add(activeUser); }
            if (userPermSets.contains('Universal_User_PS'))                { universalUsers.add(activeUser); }
            if (userPermSets.contains('Provider_Worker_Supervisor_PS'))    { providerSupervisorUsers.add(activeUser); }
            if (userPermSets.contains('Provider_Worker_PS'))               { providerWorkerUsers.add(activeUser); }
            if (userPermSets.contains('Fiscal_Worker_Supervisor_PS'))      { fiscalSupervisorUsers.add(activeUser); }
            if (userPermSets.contains('Fiscal_Worker_PS'))                 { fiscalWorkerUsers.add(activeUser); }
            if (userPermSets.contains('Business_Office_Supervisor_PS'))    { boSupervisorUsers.add(activeUser); }
            if (userPermSets.contains('Business_Office_Worker_PS'))        { boWorkerUsers.add(activeUser); }
            if (userPermSets.contains('Read_Only_User_PS'))                { readOnlyUsers.add(activeUser); }
        }

        // Walk levels 1–10 in priority order; return first non-empty level's random pick
        List<List<User>> hierarchy = new List<List<User>>{
            ewSupervisorUsers,       // Level 1  — Eligibility Worker Supervisor
            ewUsers,                 // Level 2  — Eligibility Worker
            universalUsers,          // Level 3  — Universal User
            providerSupervisorUsers, // Level 4  — Provider Worker Supervisor
            providerWorkerUsers,     // Level 5  — Provider Worker
            fiscalSupervisorUsers,   // Level 6  — Fiscal Supervisor
            fiscalWorkerUsers,       // Level 7  — Fiscal Worker
            boSupervisorUsers,       // Level 8  — BO Supervisor
            boWorkerUsers,           // Level 9  — BO Worker
            readOnlyUsers            // Level 10 — Read Only
        };

        for (List<User> levelUsers : hierarchy) {
            if (!levelUsers.isEmpty()) {
                Integer randomIndex = Integer.valueOf(Math.random() * levelUsers.size());
                return levelUsers[randomIndex];
            }
        }

        return null; // No eligible user found at any level
    }

    @AuraEnabled
    public static LightningServerResponse initiateCountyTransfer(
        String oldComplaintId,
        String countyId,
        String notes,
        String assigneeId
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (String.isBlank(oldComplaintId)) {
                return new LightningServerResponse(false, 'Complaint ID is required.', null);
            }
            if (String.isBlank(countyId)) {
                return new LightningServerResponse(false, 'County is required.', null);
            }
            if (String.isBlank(notes)) {
                return new LightningServerResponse(false, 'County Transfer Notes are required.', null);
            }

            Id oldId = (Id) oldComplaintId;

            // ── Step 1: Query old complaint ──────────────────────────────────
            List<Client_Complaint__c> oldList = [
                SELECT Id, IDN_CASE__c, IDN_PROVR__c, IDN_COUNTY__c, Assignee__c,
                       Person_who_Provided_Complaint__c, Complaint_Types__c,
                       Complaint_Status__c, Method_of_Contact__c,
                       Subject__c, Complaint_Body__c,
                       DTE_Initial_Complaint__c, DTE_County_Response__c,
                       DTE_Complaint_Resolved__c, DTE_County_Transfer__c
                FROM   Client_Complaint__c
                WHERE  Id = :oldId
                LIMIT  1
            ];
            if (oldList.isEmpty()) {
                return new LightningServerResponse(false, 'Complaint record not found.', null);
            }
            Client_Complaint__c oldComplaint = oldList[0];

            // ── Step 2: Update old complaint ─────────────────────────────────
            Client_Complaint__c oldUpdate = new Client_Complaint__c(Id = oldId);
            oldUpdate.Complaint_Status__c    = 'Transferred To';
            oldUpdate.DTE_County_Transfer__c = Date.today();
            oldUpdate.DTE_Complaint_Resolved__c = Date.today();
            oldUpdate.DTE_County_Response__c    = Date.today();
            GenericDMLHandler.updateRecords(
                new List<SObject>{ oldUpdate },
                new Map<String, Object>{ 'Method__c' => 'initiateCountyTransfer', 'Class__c' => 'ClientComplaintApxCtrl' },
                new List<String>{
                    'Complaint_Status__c', 'DTE_County_Transfer__c',
                    'DTE_Complaint_Resolved__c', 'DTE_County_Response__c'
                }
            );

            // ── Step 2b: Complete all open tasks on the old complaint ────────
            ClientComplaintTriggerHandler.completeOpenTasks(oldId);

            // ── Step 3: Add transfer note to old complaint ───────────────────
            Client_Complaint_Note__c oldNote = new Client_Complaint_Note__c(
                Client_Complaint__c = oldId,
                Description__c      = notes
            );
            GenericDMLHandler.insertRecords(
                new List<SObject>{ oldNote },
                false,
                new Map<String, Object>{ 'Method__c' => 'initiateCountyTransfer', 'Class__c' => 'ClientComplaintApxCtrl' },
                new List<String>{ 'Client_Complaint__c', 'Description__c' }
            );

            // ── Step 4: Clone complaint to new record ────────────────────────
            Id resolvedAssigneeId = String.isNotBlank(assigneeId) ? (Id) assigneeId : null;

            // Use assignee if provided, otherwise fall back to the county-priority user returned by resolveComplaintOwner for the target county
            Id taskOwnerId = resolvedAssigneeId;
            if (taskOwnerId == null) {
                List<T_COUNTY__c> countyRec = [
                    SELECT CDE_COUNTY__c FROM T_COUNTY__c WHERE Id = :(Id) countyId LIMIT 1
                ];
                if (!countyRec.isEmpty() && countyRec[0].CDE_COUNTY__c != null) {
                    String countyCode = String.valueOf(countyRec[0].CDE_COUNTY__c.intValue());
                    User countyOwner  = resolveComplaintOwner(countyCode);
                    if (countyOwner != null) {
                        taskOwnerId = countyOwner.Id;
                    }
                }
            }
            Client_Complaint__c newComplaint = new Client_Complaint__c();
            newComplaint.IDN_CASE__c                      = oldComplaint.IDN_CASE__c;
            newComplaint.IDN_PROVR__c                     = oldComplaint.IDN_PROVR__c;
            newComplaint.IDN_COUNTY__c                    = (Id) countyId;
            newComplaint.Person_who_Provided_Complaint__c = oldComplaint.Person_who_Provided_Complaint__c;
            newComplaint.Assignee__c                      = taskOwnerId;
            newComplaint.Complaint_Types__c               = oldComplaint.Complaint_Types__c;
            newComplaint.Complaint_Status__c              = 'New';
            newComplaint.Method_of_Contact__c             = oldComplaint.Method_of_Contact__c;
            newComplaint.DTE_Initial_Complaint__c         = Date.today();
            newComplaint.DTE_County_Response__c           = null;
            newComplaint.DTE_Complaint_Resolved__c        = null;
            newComplaint.DTE_County_Transfer__c           = null;
            newComplaint.Subject__c                       = oldComplaint.Subject__c;
            newComplaint.Complaint_Body__c                = oldComplaint.Complaint_Body__c;
            // Suppress T236 trigger — T237 is created explicitly below
            ClientComplaintTriggerHandler.skipT236ForCountyTransfer = true;
            try {
                GenericDMLHandler.insertRecords(
                    new List<SObject>{ newComplaint },
                    false,
                    new Map<String, Object>{ 'Method__c' => 'initiateCountyTransfer', 'Class__c' => 'ClientComplaintApxCtrl' },
                    new List<String>{
                        'IDN_CASE__c', 'IDN_PROVR__c', 'IDN_COUNTY__c', 'Assignee__c',
                        'Person_who_Provided_Complaint__c', 'Complaint_Types__c',
                        'Complaint_Status__c', 'Method_of_Contact__c', 'Subject__c',
                        'Complaint_Body__c', 'DTE_Initial_Complaint__c',
                        'DTE_County_Response__c', 'DTE_Complaint_Resolved__c', 'DTE_County_Transfer__c'
                    }
                );
            } finally {
                ClientComplaintTriggerHandler.skipT236ForCountyTransfer = false;
            }
            Id newId = newComplaint.Id;

            // ── Step 5: Clone old notes to new complaint ─────────────────────
            List<Client_Complaint_Note__c> existingNotes = [
                SELECT Id, Description__c
                FROM   Client_Complaint_Note__c
                WHERE  Client_Complaint__c = :oldId
                ORDER BY CreatedDate ASC
            ];
            if (!existingNotes.isEmpty()) {
                List<SObject> clonedNotes = new List<SObject>();
                for (Client_Complaint_Note__c n : existingNotes) {
                    clonedNotes.add(new Client_Complaint_Note__c(
                        Client_Complaint__c = newId,
                        Description__c      = n.Description__c
                    ));
                }
                GenericDMLHandler.insertRecords(
                    clonedNotes,
                    false,
                    new Map<String, Object>{ 'Method__c' => 'initiateCountyTransfer', 'Class__c' => 'ClientComplaintApxCtrl' },
                    new List<String>{ 'Client_Complaint__c', 'Description__c' }
                );
            }

            // ── Step 7: Re-link linked complaints + create old to new link ─────
            List<Linked_Client_Complaint__c> existingLinks = [
                SELECT Id, Client_Complaint_1__c, Client_Complaint_2__c
                FROM   Linked_Client_Complaint__c
                WHERE  Client_Complaint_1__c = :oldId
            ];
            List<SObject> newLinks = new List<SObject>();
            for (Linked_Client_Complaint__c lnk : existingLinks) {
                newLinks.add(new Linked_Client_Complaint__c(
                    Client_Complaint_1__c = newId,
                    Client_Complaint_2__c = lnk.Client_Complaint_2__c
                ));
            }
            // Always create old to new link
            newLinks.add(new Linked_Client_Complaint__c(
                Client_Complaint_1__c = oldId,
                Client_Complaint_2__c = newId
            ));
            GenericDMLHandler.insertRecords(
                newLinks,
                false,
                new Map<String, Object>{ 'Method__c' => 'initiateCountyTransfer', 'Class__c' => 'ClientComplaintApxCtrl' },
                new List<String>{ 'Client_Complaint_1__c', 'Client_Complaint_2__c' }
            );

            // ── Steps 8 & 9: Create T237 Task + send email notification ────────
            ClientComplaintTriggerHandler.createT237Task(newComplaint, resolvedAssigneeId, taskOwnerId);

            return new LightningServerResponse(
                true,
                'County transfer completed successfully.',
                new Map<String, Object>{ 'newComplaintId' => newId }
            );

        } catch (Exception e) {
            Database.rollback(sp);
            return new LightningServerResponse(false, e.getMessage(), null);
        }
    }

    private static Id toId(Object val) {
        if (val == null) return null;
        String s = String.valueOf(val);
        return String.isNotBlank(s) ? (Id) s : null;
    }

    private static String toStr(Object val) {
        if (val == null) return null;
        String s = String.valueOf(val);
        return String.isNotBlank(s) ? s : null;
    }

    private static Date toDate(Object val) {
        if (val == null) return null;
        String s = String.valueOf(val);
        if (String.isBlank(s)) return null;
        s = s.substringBefore('T');
        return Date.valueOf(s);
    }
}