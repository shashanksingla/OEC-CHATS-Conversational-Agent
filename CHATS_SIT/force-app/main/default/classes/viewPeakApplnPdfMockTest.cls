@isTest
global class viewPeakApplnPdfMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/xml');
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        return response;
    }
}