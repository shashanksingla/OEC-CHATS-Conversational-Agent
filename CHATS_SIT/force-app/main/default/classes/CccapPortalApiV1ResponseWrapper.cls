/************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           08/10/2026
*  @description    Response envelope wrapper for CccapPortalApiV1 REST resource.
*                  All method payloads are returned as raw SObject / external
*                  object records serialised directly into the data field.
*
*  Modification Log:
*  * Version: 1.0
*  * Date: 10-Aug-2026
*  * Description: Initial version
************************************************************/
public with sharing class CccapPortalApiV1ResponseWrapper {

    // ─────────────────────────────────────────────────────────────────────────
    // Envelope — every method response is wrapped in this outer shell.
    // The 'data' field holds whatever raw Map / List of SObjects the method
    // produced so the caller receives the native Salesforce field names.
    // ─────────────────────────────────────────────────────────────────────────
    public class ApiResponse {
        public Boolean isSuccess    { get; set; }
        public String  errorMessage { get; set; }
        public Object  data         { get; set; }

        public ApiResponse(Boolean isSuccess, Object data) {
            this.isSuccess = isSuccess;
            this.data      = data;
        }

        public ApiResponse(String errorMessage) {
            this.isSuccess    = false;
            this.errorMessage = errorMessage;
        }
    }
}