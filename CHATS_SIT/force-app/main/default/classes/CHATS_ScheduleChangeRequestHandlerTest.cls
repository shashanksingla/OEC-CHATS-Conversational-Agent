/****
* Tests for CHATS_ScheduleChangeRequestHandler.
* One @testSetup + one @IsTest method exercising every meaningful branch of
* handleCreate (wrapped + bare payload, blank body / blank auth name,
* malformed JSON, auth-not-found exception path, email-template branch) and
* the sanitize() helper (null / blank / HTML-escape / length-cap).
*/
@IsTest(SeeAllData=true)
private class CHATS_ScheduleChangeRequestHandlerTest {
    
    @IsTest
    static void handleCreate_coversAllPaths() {
        // SeeAllData=true is required so the handler can find the org's
        // 'Task_Assignment_Custom_Template' EmailTemplate; that flag also
        // disallows @TestSetup, so the data is built inline here.
        T_COUNTY__c county = TestClassUtility.createCounty('Denver', 'test', 1, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 2');
        
        T_SBSD_CASE__c caseRec = new T_SBSD_CASE__c();
        insert caseRec;
        
        T_AUTH__c authInsert = TestClassUtility.createAuthorization(
            false,
            System.today().addDays(30),
            System.today(),
            county.Id,
            provider.Id
        );
        authInsert.IDN_CASE__c = caseRec.Id;
        insert authInsert;
        
        T_AUTH__c auth = [SELECT Id, Name FROM T_AUTH__c WHERE Id = :authInsert.Id LIMIT 1];
        
        Test.startTest();
        // 1. Auth not found — list index out of bounds is caught by the outer try/catch.
        CHATS_ScheduleChangeRequestHandler.handleCreate(JSON.serialize(new Map<String, Object>{
            'CCCAP_Authorization'      => 'DOES-NOT-EXIST-XYZ',
                'Stack_CCCAP_UPK_Response' => 'No'
                }));
        
        // 2. Blank body — early-exit error path.
        CHATS_ScheduleChangeRequestHandler.handleCreate('   ');
        
        // 3. Blank auth name — early-exit error path.
        CHATS_ScheduleChangeRequestHandler.handleCreate(JSON.serialize(new Map<String, Object>{
            'CCCAP_Authorization'      => '   ',
                'Stack_CCCAP_UPK_Response' => 'Yes'
                }));
        
        // 4. Malformed JSON — caught by the outer try/catch.
        CHATS_ScheduleChangeRequestHandler.handleCreate('{not-json');
        
        // 5. sanitize() helper — null / blank / HTML-escape / length-cap.
        CHATS_ScheduleChangeRequestHandler.sanitize(null, 50);
        CHATS_ScheduleChangeRequestHandler.sanitize('   ', 50);
        CHATS_ScheduleChangeRequestHandler.sanitize('  <script>x</script>  ', 100);
        CHATS_ScheduleChangeRequestHandler.sanitize('abcdefghij', 4);
        
        // 6. REST entry-point — covers CHATS_ScheduleChangeRequest.createScheduleChangeTask.
        //    Once with a populated request body, once with a null request to hit both
        //    branches of the body-extraction ternary.
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CCCAP/ScheduleChangeRequest/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'CCCAP_Authorization'       => auth.Name,
                'Requested_Schedule_Change' => 'via REST',
                'Stack_CCCAP_UPK_Response'  => 'Yes'
                }));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        CHATS_ScheduleChangeRequest.createScheduleChangeTask();
        
        RestContext.request = null;
        CHATS_ScheduleChangeRequest.createScheduleChangeTask();
        
        Test.stopTest();
        
        // Both success paths should have created a Task tied to the new Authorization.
        // Filter by WhatId because SeeAllData=true exposes pre-existing org Tasks.
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :auth.Id],
                            '1 Task should have been created for the test Authorization');
    }
}