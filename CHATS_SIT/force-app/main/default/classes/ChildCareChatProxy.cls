public with sharing class ChildCareChatProxy {
    private static final String ASCEND_BASE_URL = 'https://d3thytbs9a5a1.cloudfront.net';
    private static final String DEFAULT_PROCESS_REF = 'ccare_provider_agent_process';
    private static final String DEFAULT_PERSONA_REF = 'CCARE Provider Agent';
    private static final String DEFAULT_RUN_LABEL = 'Salesforce child care chat';

    @AuraEnabled
    public static String createRun(String processRef, String personaRef, String input, String runLabel) {
        Map<String, Object> body = new Map<String, Object>();
        body.put('process_ref', valueOrDefault(processRef, DEFAULT_PROCESS_REF));
        body.put('persona_ref', valueOrDefault(personaRef, DEFAULT_PERSONA_REF));
        body.put('input', input == null ? '' : input);
        body.put('run_label', valueOrDefault(runLabel, DEFAULT_RUN_LABEL));

        HttpResponse response = send(
            'POST',
            '/executor/api/runs?async_run=true',
            JSON.serialize(body)
        );
        return response.getBody();
    }

    @AuraEnabled
    public static String createConversationRun(String processRef, String personaRef, String runLabel) {
        Map<String, Object> body = new Map<String, Object>();
        body.put('process_ref', valueOrDefault(processRef, DEFAULT_PROCESS_REF));
        body.put('persona_ref', valueOrDefault(personaRef, DEFAULT_PERSONA_REF));
        body.put('run_label', valueOrDefault(runLabel, DEFAULT_RUN_LABEL));

        HttpResponse response = send(
            'POST',
            '/executor/api/runs?async_run=false',
            JSON.serialize(body)
        );
        return response.getBody();
    }

    @AuraEnabled
    public static String streamRunEvents(String runId) {
        return send(
            'GET',
            '/executor/api/runs/' + encodePath(runId) + '/events',
            null
        ).getBody();
    }

    @AuraEnabled
    public static String getRun(String runId) {
        return send(
            'GET',
            '/executor/api/runs/' + encodePath(runId),
            null
        ).getBody();
    }

    @AuraEnabled
    public static String submitRunDecision(String runId, String input) {
        Map<String, Object> body = new Map<String, Object>();
        body.put('decision', 'edit');
        body.put('free_text', input == null ? '' : input);

        return send(
            'POST',
            '/executor/api/runs/' + encodePath(runId) + '/decision?async_run=true',
            JSON.serialize(body)
        ).getBody();
    }

    private static String valueOrDefault(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }

    private static String encodePath(String value) {
        if (String.isBlank(value)) {
            throw new AuraHandledException('Ascend returned an empty run id.');
        }
        return EncodingUtil.urlEncode(value, 'UTF-8');
    }

    private static HttpResponse send(String method, String path, String body) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ASCEND_BASE_URL + path);
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Accept', 'application/json, text/event-stream, */*');

        if (body != null) {
            request.setHeader('Content-Type', 'application/json');
            request.setBody(body);
        }

        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch (Exception caughtError) {
            throwHandledError('Ascend callout failed: ' + caughtError.getMessage());
        }

        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throwHandledError(
                'Ascend request failed with HTTP ' + response.getStatusCode() + '.'
            );
        }

        return response;
    }

    private static void throwHandledError(String message) {
        AuraHandledException handledError = new AuraHandledException(message);
        handledError.setMessage(message);
        throw handledError;
    }
}