@isTest
global class getATSResponseMockup implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        String mockBody = '';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/json');
        response.setBody('[{"success":true,"errors":[]}]');
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        
        return response;
    }
}