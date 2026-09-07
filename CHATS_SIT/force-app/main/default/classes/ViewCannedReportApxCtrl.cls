public class ViewCannedReportApxCtrl {
    public static String reportStrConvertedBlob {get; set;}
    public Blob blobResponse {get; set;}
    public static Integer noOfRetryAttempts = 0;
    public static Integer totalRetryAttemptsAllowed = 20;
    public ViewCannedReportApxCtrl(){
        if(String.isNotEmpty(Label.Total_Retry_Attempts_Allowed)){
            try{
                ViewCannedReportApxCtrl.totalRetryAttemptsAllowed = Integer.valueOf(Label.Total_Retry_Attempts_Allowed);
            }catch(Exception ex){
                
            }
        }
        ViewCannedReportApxCtrl.geReportFromAWS();
    }
    public static void geReportFromAWS(){
        if(noOfRetryAttempts<totalRetryAttemptsAllowed){
            try{
                Blob blobResponse;
                string responseString;
                String fileName = System.currentPageReference().getParameters().get('fileName');
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                String url = Label.correspondenceTargetPdfServlet + 'pathInAws=Reports/Canned/output'+'&fileName=' + fileName;
                
                String myBase64String = EncodingUtil.base64Encode(Blob.valueOf(Label.AEMAuthenticationCredentials));
                request.setHeader('Authorization', 'Basic '+ myBase64String);
                request.setEndpoint(url);
                Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
                request.setTimeout(timeOutVal);
                HttpResponse response = http.send(request);
                
                if (response <> null && response.getStatusCode() == 200 && response.getBody()!=null) {
                    blobResponse = response.getBodyAsBlob();
                    reportStrConvertedBlob = EncodingUtil.base64Encode(blobResponse);
                    
                    noOfRetryAttempts = 0;
                }else{
                    noOfRetryAttempts++;
                    geReportFromAWS();
                }
            } catch (exception e){
                
                noOfRetryAttempts++;
                geReportFromAWS();
            }
        }else{
            reportStrConvertedBlob = 'File does not exist.';
        }
        
    }
    
}