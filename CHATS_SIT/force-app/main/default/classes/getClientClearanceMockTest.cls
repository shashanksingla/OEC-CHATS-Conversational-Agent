@isTest
global class getClientClearanceMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        String mockBody = '{ "httpResponseCode": "OK", "responseObjectList": [ { "firstName": "AZHARUDDIN", "middleName": "H", "lastName": "MOHAMMAD", "gender": "M", "dateOfBirth": "20011105", "ssn": "345572321", "stateId": "P004030", "alienRegNumber": "", "title": "", "score": "100" } ], "sidmodPersonOut": null, "errorMsg": null }';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/xml');
        response.setBody(mockBody);
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        
        return response;
    }
}