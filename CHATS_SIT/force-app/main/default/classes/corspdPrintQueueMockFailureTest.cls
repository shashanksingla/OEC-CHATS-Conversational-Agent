@isTest
global class corspdPrintQueueMockFailureTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/xml');
        response.setStatusCode(400);
        system.assert(string.valueof(response).contains('400'),'Should return 400 status code');
        return response;
    }
}