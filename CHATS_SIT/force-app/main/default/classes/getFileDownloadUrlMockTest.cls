@isTest
global class getFileDownloadUrlMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/json');
        
        // Create proper JSON response with fileUrl key as expected by the method
        Map<String, Object> mockResponseBody = new Map<String, Object>();
        mockResponseBody.put('fileUrl', 'https://login.salesforce.com/test-file-download-url');
        mockResponseBody.put('status', 'success');
        
        response.setBody(JSON.serialize(mockResponseBody));
        response.setStatusCode(200);
        
        return response;
    }
}