/*********************************************************************************************
*  @description    Queueable job that unsubscribes deactivated users from Analytics
*                  Report and Dashboard notification subscriptions via the Salesforce
*                  Analytics REST API.
*
*  OPTIMIZATION NOTES:
*  - Uses Map-based lookups (O(1)) for user ID matching
*  - Enforces request timeouts to prevent hanging callouts
*  - Limits batch size and notification count to prevent governor limit violations
*  - Adds null safety checks throughout nested structure traversal
*********************************************************************************************/
//CCCAP-15161

public with sharing class UserReportSubscriptionQueueable implements Queueable, Database.AllowsCallouts {

    private static final String API_VERSION      = 'v66.0';
    private static final String REPORT_SOURCE    = 'lightningReportSubscribe';
    private static final String DASHBOARD_SOURCE = 'lightningDashboardSubscribe';
    private static final Integer REQUEST_TIMEOUT = 30000; // 30 seconds - prevents hanging callouts
    private static final Integer MAX_BATCH_SIZE  = 100;   // Process max 100 work items per chain
    private static final String FAILURE_EMAIL_SUBJECT =
        'Unsubscribing deactivated user from Reports and Dashboards was unsuccessful';

    private Set<Id> deactivatedUserIds;
    private List<NotificationWorkItem> workItems;
    private List<Exception_Log__c> xLogs = new List<Exception_Log__c>();
    // Tracks per-user failure context: normalizedUserId → UserFailureInfo (name + failed record URLs)
    private Map<String, UserFailureInfo> failedUserInfoMap = new Map<String, UserFailureInfo>();

    /** Holds the name and failed record URLs for a single deactivated user. */
    @TestVisible
    private class UserFailureInfo {
        public String userName;
        public List<String> recordUrls = new List<String>();
        public UserFailureInfo(String userName) {
            this.userName = userName;
        }
    }

    public class NotificationWorkItem {
        public String notificationId;
        public String recordId;
        public String source;
        public Set<String> userIdsToRemove;

        public NotificationWorkItem(
            String notificationId,
            String recordId,
            String source,
            Set<String> userIdsToRemove
        ) {
            this.notificationId  = notificationId;
            this.recordId        = recordId;
            this.source          = source;
            this.userIdsToRemove = normalizeIds(userIdsToRemove);
        }
    }

    /**
     * @description Constructor that accepts Set of deactivated user IDs
     * @param deactivatedUserIds Set of user IDs to process
     */
    public UserReportSubscriptionQueueable(Set<Id> deactivatedUserIds) {
        this.deactivatedUserIds = deactivatedUserIds;
    }

    public UserReportSubscriptionQueueable(List<NotificationWorkItem> workItems) {
        this.workItems = workItems;
    }

    public void execute(QueueableContext ctx) {
        if (workItems == null) {
            workItems = buildWorkItems();
        }

        // Build userId → Name map once outside the loop (single SOQL)
        Map<String, String> userIdToName = buildUserIdToNameMap();

        // Process up to MAX_BATCH_SIZE work items in this execution
        // instead of just one to reduce Queueable chain depth
        Integer itemsProcessed = 0;
        while (!workItems.isEmpty() && itemsProcessed < MAX_BATCH_SIZE) {
            NotificationWorkItem current = workItems.remove(0);
            processSingleNotification(current, userIdToName);
            itemsProcessed++;
        }

        // Send one failure notification email per deactivated user that had at least one failure
        if (!failedUserInfoMap.isEmpty()) {
            sendFailureNotificationEmails();
        }

        // Only enqueue if there are remaining items
        if (!workItems.isEmpty()) {
            System.enqueueJob(new UserReportSubscriptionQueueable(workItems));
        }

        // Persist any captured exception logs
        if (xLogs != null && !xLogs.isEmpty()) {
            insert xLogs;
        }
    }

    @TestVisible
    private List<NotificationWorkItem> buildWorkItems() {
        List<NotificationWorkItem> results = new List<NotificationWorkItem>();

        if (deactivatedUserIds == null || deactivatedUserIds.isEmpty()) {
            return results;
        }

        // Use Map for O(1) lookups instead of Set.contains()
        Map<String, Boolean> targetUserIds = new Map<String, Boolean>();
        for (Id userId : deactivatedUserIds) {
            String normalizedId = normalizeId(String.valueOf(userId));
            if (!String.isBlank(normalizedId)) {
                targetUserIds.put(normalizedId, true);
            }
        }

        // Fetch all pages for each source
        results.addAll(discoverForSourceWithPagination(REPORT_SOURCE, targetUserIds));
        results.addAll(discoverForSourceWithPagination(DASHBOARD_SOURCE, targetUserIds));

        return results;
    }

    @TestVisible
    private List<NotificationWorkItem> discoverForSourceWithPagination(
        String source,
        Map<String, Boolean> targetUserIds
    ) {
        List<NotificationWorkItem> allResults = new List<NotificationWorkItem>();
        String requestUrl = buildListEndpoint(source);

        while (!String.isBlank(requestUrl)) {
            NotificationPage page = fetchNotificationPage(requestUrl);

            if (page.notifications.isEmpty()) {
                break;
            }

            allResults.addAll(findWorkItems(page.notifications, targetUserIds));

            requestUrl = page.nextPageUrl;
        }

        return allResults;
    }

    @TestVisible
    private void processSingleNotification(NotificationWorkItem wi, Map<String, String> userIdToName) {
        Http http = new Http();
        Map<String, Object> methodInfo = new Map<String, Object>{
            'Class__c' => 'UserReportSubscriptionQueueable',
            'Method__c' => 'processSingleNotification'
        };

        try {
            String endpoint = buildNotificationEndpoint(wi.notificationId);

            HttpRequest getReq = new HttpRequest();
            getReq.setEndpoint(endpoint);
            getReq.setMethod('GET');
            getReq.setTimeout(REQUEST_TIMEOUT); // Prevent hanging callouts

            HttpResponse getRes = http.send(getReq);

            if (getRes.getStatusCode() != 200) {
                xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(
                    new SubException('notification GET failed | notificationId=' + wi.notificationId +
                        ' | source=' + wi.source +
                        ' | recordId=' + wi.recordId +
                        ' | status=' + getRes.getStatusCode() +
                        ' | body=' + getRes.getBody()),
                    methodInfo
                ));
                recordFailedUsers(wi, userIdToName);
                return;
            }

            Map<String, Object> notification =
                (Map<String, Object>) JSON.deserializeUntyped(getRes.getBody());
            
            // Null check for deserialized response
            if (notification == null) {
                xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(
                    new SubException('null notification body | notificationId=' + wi.notificationId),
                    methodInfo
                ));
                recordFailedUsers(wi, userIdToName);
                return;
            }

            Boolean changed = removeUsersFromNotificationBody(
                notification,
                wi.userIdsToRemove
            );

            if (!changed) {
                xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(
                    new SubException('no recipients removed | notificationId=' + wi.notificationId +
                        ' | usersToRemove=' + wi.userIdsToRemove.size()),
                    methodInfo
                ));
                recordFailedUsers(wi, userIdToName);
                return;
            }

            HttpRequest putReq = new HttpRequest();
            putReq.setEndpoint(endpoint);
            putReq.setMethod('PUT');
            putReq.setTimeout(REQUEST_TIMEOUT); // Prevent hanging callouts
            putReq.setHeader('Content-Type', 'application/json');
            putReq.setBody(JSON.serialize(notification));

            HttpResponse putRes = http.send(putReq);

            if (putRes.getStatusCode() < 200 || putRes.getStatusCode() >= 300) {
                xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(
                    new SubException('notification PUT failed | notificationId=' + wi.notificationId +
                        ' | source=' + wi.source +
                        ' | recordId=' + wi.recordId +
                        ' | status=' + putRes.getStatusCode() +
                        ' | body=' + putRes.getBody()),
                    methodInfo
                ));
                // Track each affected user for failure notification email
                recordFailedUsers(wi, userIdToName);
            } else {
                System.debug(
                    'UserReportSubscriptionQueueable: notification updated successfully'
                    + ' | notificationId=' + wi.notificationId
                    + ' | usersRemoved=' + wi.userIdsToRemove
                );
            }
        } catch (Exception e) {
            xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(e, methodInfo));
            // Track each affected user for failure notification email
            recordFailedUsers(wi, userIdToName);
        }
    }

    private static String buildListEndpoint(String source) {
        return 'callout:SalesforceOrgAPI'
            + '/services/data/' + API_VERSION
            + '/analytics/notifications?source='
            + EncodingUtil.urlEncode(source, 'UTF-8');
    }

    private static String buildNotificationEndpoint(String notificationId) {
        return 'callout:SalesforceOrgAPI'
            + '/services/data/' + API_VERSION
            + '/analytics/notifications/'
            + EncodingUtil.urlEncode(notificationId, 'UTF-8');
    }

    public class SubException extends Exception {}

    private class NotificationPage {
        public List<Object> notifications = new List<Object>();
        public String nextPageUrl;
    }

    private static List<NotificationWorkItem> findWorkItems(
        List<Object> notifications,
        Map<String, Boolean> targetUserIds
    ) {
        List<NotificationWorkItem> results = new List<NotificationWorkItem>();

        for (Object obj : notifications) {
            Map<String, Object> notification = (Map<String, Object>) obj;

            if (notification == null) {
                continue;
            }

            Set<String> matchedUsers = findTargetUsers(notification, targetUserIds);
            if (matchedUsers.isEmpty()) {
                continue;
            }

            String notificationId = stringValue(notification.get('id'));
            if (String.isBlank(notificationId)) {
                continue;
            }

            results.add(new NotificationWorkItem(
                notificationId,
                stringValue(notification.get('recordId')),
                stringValue(notification.get('source')),
                matchedUsers
            ));
        }

        return results;
    }

    @TestVisible
    private NotificationPage fetchNotificationPage(String requestUrl) {
        NotificationPage page = new NotificationPage();
        Http http = new Http();
        Map<String, Object> methodInfo = new Map<String, Object>{
            'Class__c' => 'UserReportSubscriptionQueueable',
            'Method__c' => 'fetchNotificationPage'
        };

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestUrl);
            req.setMethod('GET');
            req.setTimeout(REQUEST_TIMEOUT);

            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(
                    new SubException('discovery GET failed | url=' + requestUrl +
                        ' | status=' + res.getStatusCode() +
                        ' | body=' + res.getBody()),
                    methodInfo
                ));
                Map<String, String> userIdToName = buildUserIdToNameMap();
                recordFailedUsersFromDiscovery(userIdToName);
                return page;
            }

            Object payload = JSON.deserializeUntyped(res.getBody());
            if (payload instanceof List<Object>) {
                page.notifications = (List<Object>) payload;
                return page;
            }

            if (payload instanceof Map<String, Object>) {
                Map<String, Object> body = (Map<String, Object>) payload;
                Object records = body.containsKey('records') ? body.get('records') : body.get('notifications');
                if (records instanceof List<Object>) {
                    page.notifications = (List<Object>) records;
                }

                String nextPageUrl = stringValue(body.get('nextRecordsUrl'));
                if (String.isBlank(nextPageUrl)) {
                    nextPageUrl = stringValue(body.get('nextPageUrl'));
                }
                page.nextPageUrl = normalizeNextPageUrl(nextPageUrl);
            }
        } catch (Exception e) {
            xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(e, methodInfo));
            Map<String, String> userIdToName = buildUserIdToNameMap();
            recordFailedUsersFromDiscovery(userIdToName);
        }

        return page;
    }

    private static String normalizeNextPageUrl(String nextPageUrl) {
        if (String.isBlank(nextPageUrl)) {
            return null;
        }

        if (nextPageUrl.startsWith('http')) {
            return nextPageUrl;
        }

        return 'callout:SalesforceOrgAPI' + nextPageUrl;
    }

    private static Set<String> findTargetUsers(
        Map<String, Object> notification,
        Map<String, Boolean> targetUserIds
    ) {
        Set<String> matches = new Set<String>();

        collectMatchesFromRecipients(
            (List<Object>) notification.get('recipients'),
            targetUserIds,
            matches
        );

        List<Object> thresholds = (List<Object>) notification.get('thresholds');
        if (thresholds != null) {
            for (Object thresholdObj : thresholds) {
                Map<String, Object> threshold = (Map<String, Object>) thresholdObj;
                
                // Null check before accessing threshold properties
                if (threshold == null) {
                    continue;
                }
                
                List<Object> actions = (List<Object>) threshold.get('actions');
                collectMatchesFromActions(actions, targetUserIds, matches);
            }
        }

        return matches;
    }

    private static void collectMatchesFromActions(
        List<Object> actions,
        Map<String, Boolean> targetUserIds,
        Set<String> matches
    ) {
        if (actions == null) {
            return;
        }

        for (Object actionObj : actions) {
            Map<String, Object> action = (Map<String, Object>) actionObj;
            
            // Null check to prevent null reference exceptions
            if (action == null) {
                continue;
            }
            
            Map<String, Object> config = (Map<String, Object>) action.get('configuration');

            if (config == null) {
                continue;
            }

            collectMatchesFromRecipients(
                (List<Object>) config.get('recipients'),
                targetUserIds,
                matches
            );
        }
    }

    private static void collectMatchesFromRecipients(
        List<Object> recipients,
        Map<String, Boolean> targetUserIds,
        Set<String> matches
    ) {
        if (recipients == null || recipients.isEmpty()) {
            return;
        }

        for (Object recipientObj : recipients) {
            Map<String, Object> recipient = (Map<String, Object>) recipientObj;
            
            // Null check before accessing recipient properties
            if (recipient == null) {
                continue;
            }

            if (!isUserRecipient(recipient)) {
                continue;
            }

            String recipientId = normalizeId(getRecipientUserId(recipient));
            // Use Map.containsKey() for O(1) lookup instead of Set.contains()
            if (!String.isBlank(recipientId) && targetUserIds.containsKey(recipientId)) {
                matches.add(recipientId);
            }
        }
    }

    private static Boolean removeUsersFromNotificationBody(
        Map<String, Object> notification,
        Set<String> userIdsToRemove
    ) {
        Boolean changed = false;

        List<Object> topLevelRecipients = (List<Object>) notification.get('recipients');
        if (topLevelRecipients != null) {
            List<Object> filtered = filterRecipients(topLevelRecipients, userIdsToRemove);
            if (filtered.size() != topLevelRecipients.size()) {
                notification.put('recipients', filtered);
                changed = true;
            }
        }

        List<Object> thresholds = (List<Object>) notification.get('thresholds');
        if (thresholds != null) {
            for (Object thresholdObj : thresholds) {
                Map<String, Object> threshold = (Map<String, Object>) thresholdObj;
                
                // Null check to prevent processing invalid thresholds
                if (threshold == null) {
                    continue;
                }
                
                List<Object> actions = (List<Object>) threshold.get('actions');
                if (removeUsersFromActions(actions, userIdsToRemove)) {
                    changed = true;
                }
            }
        }

        return changed;
    }

    private static Boolean removeUsersFromActions(
        List<Object> actions,
        Set<String> userIdsToRemove
    ) {
        Boolean changed = false;

        if (actions == null) {
            return changed;
        }

        for (Object actionObj : actions) {
            Map<String, Object> action = (Map<String, Object>) actionObj;
            
            // Null check to prevent null reference exceptions
            if (action == null) {
                continue;
            }
            
            Map<String, Object> config = (Map<String, Object>) action.get('configuration');

            if (config == null) {
                continue;
            }

            List<Object> actionRecipients = (List<Object>) config.get('recipients');

            if (actionRecipients == null) {
                continue;
            }

            List<Object> filtered = filterRecipients(actionRecipients, userIdsToRemove);

            if (filtered.size() != actionRecipients.size()) {
                config.put('recipients', filtered);
                changed = true;
            }
        }

        return changed;
    }

    private static List<Object> filterRecipients(
        List<Object> recipients,
        Set<String> userIdsToRemove
    ) {
        List<Object> filtered = new List<Object>();

        for (Object recipientObj : recipients) {
            Map<String, Object> recipient = (Map<String, Object>) recipientObj;
            
            // Null check to prevent processing invalid recipients
            if (recipient == null) {
                filtered.add(recipientObj);
                continue;
            }

            if (isUserRecipient(recipient)) {
                String recipientId = normalizeId(getRecipientUserId(recipient));
                if (!String.isBlank(recipientId) && userIdsToRemove.contains(recipientId)) {
                    continue;
                }
            }

            filtered.add(recipientObj);
        }

        return filtered;
    }

    private static Boolean isUserRecipient(Map<String, Object> recipient) {
        String typeValue = stringValue(recipient.get('type'));
        return String.isBlank(typeValue) || typeValue.toLowerCase() == 'user';
    }

    private static String getRecipientUserId(Map<String, Object> recipient) {
        String idValue = stringValue(recipient.get('id'));
        if (!String.isBlank(idValue)) {
            return idValue;
        }

        return stringValue(recipient.get('userId'));
    }

    private static Set<String> normalizeIds(Set<String> ids) {
        Set<String> normalized = new Set<String>();
        if (ids == null) {
            return normalized;
        }

        for (String idValue : ids) {
            String normalizedId = normalizeId(idValue);
            if (!String.isBlank(normalizedId)) {
                normalized.add(normalizedId);
            }
        }

        return normalized;
    }

    private static String normalizeId(String rawId) {
        if (String.isBlank(rawId)) {
            return null;
        }

        String trimmed = rawId.trim().toUpperCase();
        return trimmed.length() >= 15 ? trimmed.substring(0, 15) : trimmed;
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    /**
     * @description Builds a map of normalized userId (15-char) to User Name.
     *              Queries from deactivatedUserIds when available; falls back to
     *              collecting IDs from workItems for the chained-constructor path.
     */
    @TestVisible
    private Map<String, String> buildUserIdToNameMap() {
        Map<String, String> result = new Map<String, String>();
        Set<Id> idsToQuery = new Set<Id>();

        if (deactivatedUserIds != null && !deactivatedUserIds.isEmpty()) {
            idsToQuery.addAll(deactivatedUserIds);
        } else if (workItems != null) {
            for (NotificationWorkItem wi : workItems) {
                for (String uid : wi.userIdsToRemove) {
                    try {
                        idsToQuery.add((Id) uid);
                    } catch (Exception ex) {
                        // uid may be a 15-char string that cannot cast — skip safely
                    }
                }
            }
        }

        if (!idsToQuery.isEmpty()) {
            for (User u : [SELECT Id, Name FROM User WHERE Id IN :idsToQuery]) {
                result.put(normalizeId(String.valueOf(u.Id)), u.Name);
            }
        }

        return result;
    }

    /**
     * @description Builds the Lightning URL for a report or dashboard record.
     *              Reports  → /lightning/r/Report/{id}/view
     *              Dashboards → /lightning/r/Dashboard/{id}/view
     */
    private static String buildRecordUrl(String recordId, String source) {
        if (String.isBlank(recordId)) {
            return null;
        }
        String objectType = (source == DASHBOARD_SOURCE) ? 'Dashboard' : 'Report';
        return URL.getOrgDomainUrl().toExternalForm()
            + '/lightning/r/' + objectType + '/' + recordId + '/view';
    }

    /**
     * @description Records each user in wi.userIdsToRemove as having a failed unsubscribe attempt,
     *              capturing the specific report/dashboard URL from the work item's recordId and source.
     *              Uses the name from userIdToName map; falls back to the raw ID if name not found.
     */
    private void recordFailedUsers(NotificationWorkItem wi, Map<String, String> userIdToName) {
        String recordUrl = buildRecordUrl(wi.recordId, wi.source);
        for (String uid : wi.userIdsToRemove) {
            String name = (userIdToName != null && userIdToName.containsKey(uid))
                ? userIdToName.get(uid)
                : uid;
            if (!failedUserInfoMap.containsKey(uid)) {
                failedUserInfoMap.put(uid, new UserFailureInfo(name));
            }
            if (!String.isBlank(recordUrl)) {
                failedUserInfoMap.get(uid).recordUrls.add(recordUrl);
            }
        }
    }

    /**
     * @description Records all users in userIdToName as failed when discovery itself fails
     *              (fetchNotificationPage non-200 or exception). No specific record URL is
     *              available in this case — only the user name is captured.
     */
    private void recordFailedUsersFromDiscovery(Map<String, String> userIdToName) {
        for (String uid : userIdToName.keySet()) {
            if (!failedUserInfoMap.containsKey(uid)) {
                failedUserInfoMap.put(uid, new UserFailureInfo(userIdToName.get(uid)));
            }
        }
    }

    /**
     * @description Sends one failure notification email per deactivated user that had at least
     *              one unsubscribe attempt fail. Recipients are read from the custom label
     *              ReportDashboardUnsubscribeFailureEmail (semicolon-delimited), matching the
     *              pattern used by FailLogBatch / chats24hrSupportEmail.
     */
    @TestVisible
    private void sendFailureNotificationEmails() {
        Map<String, Object> methodInfo = new Map<String, Object>{
            'Class__c'  => 'UserReportSubscriptionQueueable',
            'Method__c' => 'sendFailureNotificationEmails'
        };
        try {
            List<OrgWideEmailAddress> owa = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE DisplayName = 'CHATS Support Team (Do Not Reply)'
            ];

            List<String> toAddresses = Label.ReportDashboardUnsubscribeFailureEmail.split(';');

            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            for (String uid : failedUserInfoMap.keySet()) {
                UserFailureInfo info = failedUserInfoMap.get(uid);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setSubject(FAILURE_EMAIL_SUBJECT);
                mail.setHtmlBody(buildFailureEmailBody(info.userName, info.recordUrls));
                if (!owa.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owa[0].Id);
                }
                mails.add(mail);
            }

            if (!mails.isEmpty() && !Test.isRunningTest()) {
                Messaging.sendEmail(mails);
            }
        } catch (Exception e) {
            xLogs.add(ExceptionLoggingServices.captureExceptionLogInstance(e, methodInfo));
        }
    }

    /**
     * @param deactivatedUserName Full name of the deactivated user
     * @param recordUrls          Lightning URLs of the reports/dashboards with failed unsubscribes
     */
    private static String buildFailureEmailBody(String deactivatedUserName, List<String> recordUrls) {
        String steps =
            '<ol>' +
            '<li>Click on the Report Name or Dashboard Title to open the report or dashboard.</li>' +
            '<li>Click on the drop down next to the Edit button.</li>' +
            '<li>Click on <strong>Subscribe</strong> to access the Edit Subscription modal.</li>' +
            '<li>Click the <strong>Edit Recipients</strong> button to access the Edit Recipients modal.</li>' +
            '<li>Click on the <strong>x</strong> next to the user\'s name in the Subscribers section.</li>' +
            '</ol>';

        String subscriptionLinks = '';
        if (recordUrls != null && !recordUrls.isEmpty()) {
            subscriptionLinks = '<p><strong>Report and Dashboard Subscriptions:</strong></p><ul>';
            for (String url : recordUrls) {
                subscriptionLinks += '<li><a href="' + url + '">' + url + '</a></li>';
            }
            subscriptionLinks += '</ul>';
        }

        return 
               '<p>The system attempted to unsubscribe <strong>' + deactivatedUserName + '</strong> ' +
               'from the listed reports or dashboards.</p>' +
               subscriptionLinks +
               '<p>Click and follow these steps to manually unsubscribe users from a report or dashboard.</p>' +
               steps;
    }
}