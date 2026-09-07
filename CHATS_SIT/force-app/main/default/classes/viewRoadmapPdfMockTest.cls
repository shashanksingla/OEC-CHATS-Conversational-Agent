/*
	Title: Mock Roadmap PDF Service Response 
	Description: Mock Service
	Author: Balamurugan Chinnaiah
	Comments: CCCAP-3117 09/10/2021
*/

@isTest
global class viewRoadmapPdfMockTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-type', 'application/xml');
        response.setStatusCode(200);
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        return response;
    }
}