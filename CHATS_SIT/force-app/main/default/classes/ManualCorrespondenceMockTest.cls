@isTest
global class ManualCorrespondenceMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/xml');
        response.setStatusCode(200);
        response.setBody('{"status" :"SUCCESS", "bucket" :"dev.chats", "dataXml" :" "}');  
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        return response;
    }
}