@IsTest
private class CccapPortalApiV1Test {
    @IsTest
    static void buildsQuotedSalesforceProviderIdClause() {
        String clause = CccapPortalApiV1.buildInClause(
            new List<String>{ 'a0w41000005hmAnAAI', 'a0w41000005hqtrAAA' }
        );

        System.assertEquals(
            '\'a0w41000005hmAnAAI\',\'a0w41000005hqtrAAA\'',
            clause
        );
    }

    @IsTest
    static void buildsUnquotedNumericProviderNameClause() {
        String clause = CccapPortalApiV1.buildNumericInClause(
            new List<String>{ '20260722', '1709824' }
        );

        System.assertEquals('20260722,1709824', clause);
    }

    @IsTest
    static void normalizesDocumentedAttendanceTransactionFields() {
        Map<String, Object> normalized = CccapPortalApiV1.normalizeAttendanceTransaction(
            new Map<String, Object>{
                'CI_Transaction_ID__c' => 'transaction-1',
                'Schedule__c' => 'schedule-1',
                'CI_Attendance_Date__c' => '2026-09-05',
                'CI_Attendance_Hours__c' => 8,
                'CI_Transaction_Type__c' => 1,
                'CI_Transaction_Result__c' => 1,
                'Status__c' => 'PARENT_APPROVED',
                'Sub_Type__c' => 'CCCAP',
                'Previous_Transaction__c' => false
            }
        );

        System.assertEquals('transaction-1', normalized.get('transaction_id'));
        System.assertEquals('schedule-1', normalized.get('schedule_id'));
        System.assertEquals(8, normalized.get('attended_hours'));
        System.assertEquals('PARENT_APPROVED', normalized.get('status'));
    }
}