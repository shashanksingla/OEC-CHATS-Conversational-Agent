@isTest
global class HerokuServiceUnSuccessfullCalloutMock implements HttpCalloutMock {
    // Implement this interface method authEncumbrancefetch
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"isSucess": true,"errorMessage": "Unexpected Exception"}');  
    	return response;
    }
}