@isTest
global class HttpMockCallOutUpdateParentFee implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{}]');  
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        return response; 
    }
}