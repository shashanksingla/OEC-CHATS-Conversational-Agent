@IsTest
private class ChildCareChatProxyTest {
    private class AscendMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        HttpRequest request;

        AscendMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            this.request = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            return response;
        }
    }

    @IsTest
    static void createRunUsesExecutorContract() {
        AscendMock mock = new AscendMock(201, '{"id":"run-1"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String response = ChildCareChatProxy.createRun('', '', 'Hello', '');
        Test.stopTest();

        System.assertEquals('{"id":"run-1"}', response);
        System.assertEquals('POST', mock.request.getMethod());
        System.assertEquals(
            'https://d3thytbs9a5a1.cloudfront.net/executor/api/runs?async_run=true',
            mock.request.getEndpoint()
        );
        System.assert(mock.request.getBody().contains('"process_ref":"ccare_provider_agent_process"'));
        System.assert(mock.request.getBody().contains('"persona_ref":"CCARE Provider Agent"'));
        System.assert(mock.request.getBody().contains('"input":"Hello"'));
    }

    @IsTest
    static void streamRunEventsUseRunId() {
        AscendMock streamMock = new AscendMock(200, 'event: message\\ndata: {"text":"Hello"}\\n\\n');
        Test.setMock(HttpCalloutMock.class, streamMock);

        Test.startTest();
        String events = ChildCareChatProxy.streamRunEvents('run/1');
        Test.stopTest();

        System.assertEquals('event: message\\ndata: {"text":"Hello"}\\n\\n', events);
        System.assertEquals(
            'https://d3thytbs9a5a1.cloudfront.net/executor/api/runs/run%2F1/events',
            streamMock.request.getEndpoint()
        );
    }

    @IsTest
    static void createConversationRunUsesResumableContract() {
        AscendMock mock = new AscendMock(201, '{"id":"run-1","status":"pending"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String response = ChildCareChatProxy.createConversationRun('', '', '');
        Test.stopTest();

        System.assertEquals('{"id":"run-1","status":"pending"}', response);
        System.assertEquals('POST', mock.request.getMethod());
        System.assertEquals(
            'https://d3thytbs9a5a1.cloudfront.net/executor/api/runs?async_run=false',
            mock.request.getEndpoint()
        );
        System.assert(mock.request.getBody().contains('"process_ref":"ccare_provider_agent_process"'));
        System.assert(mock.request.getBody().contains('"persona_ref":"CCARE Provider Agent"'));
        System.assert(!mock.request.getBody().contains('"input"'));
    }

    @IsTest
    static void getRunUsesRunId() {
        AscendMock runMock = new AscendMock(200, '{"id":"run-1","final_response":"Done"}');
        Test.setMock(HttpCalloutMock.class, runMock);

        Test.startTest();
        String run = ChildCareChatProxy.getRun('run-1');
        Test.stopTest();

        System.assertEquals('{"id":"run-1","final_response":"Done"}', run);
        System.assertEquals(
            'https://d3thytbs9a5a1.cloudfront.net/executor/api/runs/run-1',
            runMock.request.getEndpoint()
        );
    }

    @IsTest
    static void submitRunDecisionUsesExistingRunId() {
        AscendMock decisionMock = new AscendMock(200, '{"id":"run-1","status":"running"}');
        Test.setMock(HttpCalloutMock.class, decisionMock);

        Test.startTest();
        String response = ChildCareChatProxy.submitRunDecision('run-1', 'Continue this chat');
        Test.stopTest();

        System.assertEquals('{"id":"run-1","status":"running"}', response);
        System.assertEquals('POST', decisionMock.request.getMethod());
        System.assertEquals(
            'https://d3thytbs9a5a1.cloudfront.net/executor/api/runs/run-1/decision?async_run=true',
            decisionMock.request.getEndpoint()
        );
        System.assert(decisionMock.request.getBody().contains('"decision":"edit"'));
        System.assert(decisionMock.request.getBody().contains('"free_text":"Continue this chat"'));
    }

    @IsTest
    static void nonSuccessResponseIsHandled() {
        Test.setMock(HttpCalloutMock.class, new AscendMock(422, '{"detail":"invalid process"}'));

        Test.startTest();
        try {
            ChildCareChatProxy.createRun('missing-process', '', 'Hello', 'Test');
            System.assert(false, 'Expected an AuraHandledException.');
        } catch (AuraHandledException caughtError) {
            System.assert(caughtError.getMessage().contains('422'));
        }
        Test.stopTest();
    }
}