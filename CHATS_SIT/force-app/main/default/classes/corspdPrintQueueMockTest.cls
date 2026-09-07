@isTest
global class corspdPrintQueueMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        if(viewCorrespondencePdfController.noOfRetryAttempts==0){
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-type', 'application/xml');
            response.setStatusCode(503);
            return response;
        }else{
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-type', 'application/xml');
            response.setStatusCode(200);
            response.setBody('some text');
            return response;
        }
    }
}