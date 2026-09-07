@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        if(req.getEndpoint().contains('AuthEncumbr/FetchCounty')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": "successfull","count": "758","errorMessage": null}');
            res.setStatusCode(200);
            system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
            return res;
        }else{
            return getBREResponse200();    
        }
        
    }

    global HTTPResponse getBREResponse200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "CaseID": 71048657, "CaseMode": "ONG", "CaseStatus": "OPN", "ConfirmEligibilityCode": "INP", "DateLastUpdated": "/Date(-62135596800000+0000)/", "ErrorValue": [], "ProgramChange": false, "ProgramName": "LI", "RunID": 10109091, "UserLastUpdated": "t-test21" }');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }

    global HTTPResponse getBREResponse200WithError() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "CaseID": 71048657, "CaseMode": "ONG", "CaseStatus": "OPN", "ConfirmEligibilityCode": "INP", "DateLastUpdated": "/Date(-62135596800000+0000)/", "ErrorValue": ["Some Error"], "ProgramChange": false, "ProgramName": "LI", "RunID": 10109091, "UserLastUpdated": "t-test21" }');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }
    
    global HTTPResponse getBREResponseGreaterThan2000() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "CaseID": 71048657, "CaseMode": "ONG", "CaseStatus": "OPN", "ConfirmEligibilityCode": "INP", "DateLastUpdated": "/Date(-62135596800000+0000)/", "ErrorValue": [], "ProgramChange": false, "ProgramName": "LI", "RunID": 10109091, "UserLastUpdated": "t-test21" }');
        res.setStatusCode(2400);
        system.assert(string.valueof(res).contains('2400'),'Should return 2400 status code');
        return res;
    }
    
    global HTTPResponse getBREResponseNot200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('<p xmlns="">The server encountered an error processing the request. Please see the <a rel="help-page" href="http://dev-corticon1.colorado-cdhs-chats.com/eligibilityEngineSITSIT/DetermineEligibilityService.svc/help">service help page</a> for constructing valid requests to the service. The exception message is The specified Program Code is not valid. See server logs for more details. The exception stack trace is: </p>');
        res.setStatusCode(210);
        return res;
    }
    
    global HTTPResponse getBREConfirmEligibilityResponse200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"ErrorValue": null,"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }

    global HTTPResponse getBREConfirmEligibilityResponseGreaterThan200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"ErrorValue": null,"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(2400);
        system.assert(string.valueof(res).contains('2400'),'Should return 2400 status code');
        return res;
    }

    global HTTPResponse getBREConfirmEligibilityResponseNot200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"ErrorValue": null,"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(400);
        system.assert(string.valueof(res).contains('400'),'Should return 400 status code');

        return res;
    }    
    
    global HTTPResponse getBREConfirmEligibilityResponse200WithError() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"ErrorValue": ["some error"],"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }

    global HTTPResponse getBRESaveIneligibilityReasonse200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }

    global HTTPResponse getBRESaveIneligibilityReasonse200WithError() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"CaseID": 71112636,"CaseMode": null,"CaseStatus": null,"ConfirmEligibilityCode": null,"DateLastUpdated": "/Date(-62135596800000+0000)/","DocumentId": null,"ErrorValue": ["some error"],"FCEligibilityID": 0,"FCIndividualID": 0,"FailureCodes": null,"ProgramChange": false,"ProgramName": null,"RunID": 10109087,"UserLastUpdated": "t-test21"}');
        res.setStatusCode(200);
        system.assert(string.valueof(res).contains('200'),'Should return 200 status code');
        return res;
    }

    global HTTPResponse getResponseGreaterThan2400() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(2400);
        system.assert(string.valueof(res).contains('2400'),'Should return 2400 status code');
        return res;
    }

    global HTTPResponse getResponseNot200() {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(400);
        res.setBody('The exception message is test class execution.See server logs for more details');
        system.assert(string.valueof(res).contains('400'),'Should return 400 status code');
        return res;
    }    

    
}