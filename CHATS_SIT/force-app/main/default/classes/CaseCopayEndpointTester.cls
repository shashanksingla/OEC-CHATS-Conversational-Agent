/*
Apex class to test the Case_Copay_Web_Service_Update endpoint 100 times
*/
public class CaseCopayEndpointTester {
/*
    // Test configuration
    private static final String ENDPOINT_URL = System.Label.Case_Copay_Web_Service_Update;
    private static final Integer DEFAULT_TOTAL_REQUESTS = 100;
    private static final Integer DEFAULT_DELAY_MS = 0;

    // Test results tracking
    public class TestResult {
        public Integer totalRequests;
        public Integer successCount;
        public Integer errorCount;
        public Decimal successRate;
        public Long totalTimeMs;
        public List<String> errorMessages;
        public List<Decimal> responseTimes;
        public DateTime startTime;
        public DateTime endTime;

        public TestResult() {
            this.errorMessages = new List<String>();
            this.responseTimes = new List<Decimal>();
            this.successCount = 0;
            this.errorCount = 0;
        }
    }

    public static TestResult runCustomTest(Integer totalRequests, Integer delayMs) {
        TestResult result = new TestResult();

        for (Integer i = 1; i <= totalRequests; i++) {
            try {
                Boolean success = makeRequest(i);              
                if (success) {
                    result.successCount++;
                } else {
                    result.errorCount++;
                }
 
                
            } catch (Exception e) {
                result.errorCount++;
                String errorMsg = 'Request ' + i + ': ' + e.getMessage();
                System.debug('error:'+errorMsg);
            }
        }

        System.debug('Successful: ' + result.successCount);
        System.debug('Failed: ' + result.errorCount);

        return result;
    }

    private static Boolean makeRequest(Integer requestId) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(ENDPOINT_URL);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('User-Agent', 'CHATS-Apex-Test-Script/1.0');

            // Create sample payload based on HerokuService.caseCopyUpdate method
            String payload = createSamplePayload(requestId);
            request.setBody(payload);

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                return true;
            } else {
                System.debug('HTTP Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
                System.debug('Response Body: ' + response.getBody().left(200));
                return false;
            }

        } catch (Exception e) {
            System.debug('Exception in makeRequest: ' + e.getMessage());
            return false;
        }
    }
    private static String createSamplePayload(Integer requestId) {
        String paddedId = String.valueOf(requestId).leftPad(3, '0');
        String currentDateTime = DateTime.now().format('yyyy-MM-dd HH:mm:ss');

        Map<String, Object> payload = new Map<String, Object>{
            'amt_Copay_Case_Assesd' => '10.00',
            'amt_Copay_Case_Ft' => '5.00',
            'amt_Copay_Case_Pt' => '3.00',
            'cde_Reason_Ovrd' => 'R',
            'cde_Rec_Copay' => 'R',
            'dte_Begin_Effv' => '2026-01-01',
            'dte_End_Effv' => '2026-12-31',
            'idn_Case' => 'a1mPg000001oae1IAA',
            'nbr_Seq_Hist' => '1',
            'lastmodifiedbyid' => UserInfo.getUserId(),
            'lastmodifieddate' => currentDateTime,
            'createdbyid' => UserInfo.getUserId(),
            'createddate' => currentDateTime,
            'amt_Copay_Case_Ft_Qlty' => '5.00',
            'amt_Copay_Case_Pt_Qlty' => '3.00',
            'ind_Qlty' => 'Y',
            'idn_Sbsd_Case_Copay' => '611476'
        };

        return JSON.serialize(payload);
    }*/
}