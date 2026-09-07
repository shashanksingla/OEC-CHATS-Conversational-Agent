@isTest
global class getOverrideClientClearanceMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        String mockBody = '{"persons":[{"stateId":"K901092","modifiedBy":"test","modifiedDate":"2024-02-10T05:57:50","createdBy":"test","createdDate":"2024-02-10T05:57:50","demographics":{"ssn":"675654387","alienNumber":null,"sex":"F","personStatus":"A","dateOfBirth":"2010-01-01","dobVerified":null,"lastName":"XYZ","firstName":"ABCDEFGH","middleName":"M","suffixName":null,"dateOfDeath":null,"contactDetails":null,"address":null,"ssnVerified":null,"title":null},"matchRate":"100"}],"errorMessage":null,"statusCode":"202","recordsReturned":"1","httpResponseCode":"OK","errorMsg":null}';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/json');
        response.setBody(mockBody);
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        
        return response;
    }
}