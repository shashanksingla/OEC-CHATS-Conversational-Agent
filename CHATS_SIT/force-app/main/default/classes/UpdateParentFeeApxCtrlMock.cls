@isTest
global class UpdateParentFeeApxCtrlMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"caseCopayid":"860983","successInd":"Y","errMessage":""}');
        response.setStatusCode(500);
        return response; 
    }
    
}