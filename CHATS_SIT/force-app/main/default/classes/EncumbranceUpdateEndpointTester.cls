/*
Apex class to test the EncumbranceUpdate endpoint 100 times
*/
public class EncumbranceUpdateEndpointTester {

    // Test configuration
    private static final String ENDPOINT_URL = System.Label.IndividualCareLevelUpdate;
    private static final Integer DEFAULT_TOTAL_REQUESTS = 100;
    private static final Integer DEFAULT_DELAY_MS = 100;

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
                System.debug('Error ' + errorMsg);
            }
        }
 
        
        System.debug('Successful: ' + result.successCount);
        System.debug('Failed: ' + result.errorCount);
        return result;
    }

    // Make a single HTTP request to the endpoint @param requestId Unique identifier for this request  @return Boolean indicating success
     
    private static Boolean makeRequest(Integer requestId) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(ENDPOINT_URL);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');

            // Create sample payload based on HerokuService.authEncubUpdateCareLevel method
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

    // Create sample JSON payload for the request Based on the HerokuService.authEncubUpdateCareLevel method @param requestId Unique identifier for this request @return JSON string payload
    private static String createSamplePayload(Integer requestId) {
        String paddedId = String.valueOf(requestId).leftPad(3, '0');
        String currentDateTime = DateTime.now().format('yyyy-MM-dd HH:mm:ss');

        // Create payload based on HerokuService.authEncumbranceUpdate method structure
        // The method expects an array of encumbrance records
        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();

        Map<String, Object> encumbranceRecord = new Map<String, Object>{
            'cde_Status_Encmbr' => '8', // Status code from the example in HerokuService
            'idn_Auth' => 'a0sPg0000069V2jIAE', // Test authorization ID
            'idn_Encmbr_Auth' => '307181531', // Test encumbrance ID
            'lastmodifieddate' => currentDateTime,
            'lastmodifiedbyid' => UserInfo.getUserId()
        };

        payloadList.add(encumbranceRecord);

        return JSON.serialize(payloadList);
    }
    
 
}