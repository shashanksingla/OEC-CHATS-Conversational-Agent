public class viewCorrespondencePdfController {
    public static String strConvertedBlob {get; set;}
    public Blob blobResponse {get; set;}
    public static Integer noOfRetryAttempts = 0;
    public static Integer totalRetryAttemptsAllowed = 20;
    public viewCorrespondencePdfController(){
        if(String.isNotEmpty(Label.Total_Retry_Attempts_Allowed)){
            try{
	            viewCorrespondencePdfController.totalRetryAttemptsAllowed = Integer.valueOf(Label.Total_Retry_Attempts_Allowed);
            }catch(Exception ex){
                System.debug('Label.Total_Retry_Attempts_Allowed should be a number');
            }
        }
        viewCorrespondencePdfController.getFileString();
    }
    
    public static void getFileString(){
        
        if(noOfRetryAttempts<totalRetryAttemptsAllowed){
            try{
                Blob blobResponse;
                string responseString;
                String fileName = System.currentPageReference().getParameters().get('fileName');
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                String url = Label.correspondenceTargetPdfServlet + 'pathInAws=correspondence/request'+'&fileName=' + fileName;
                system.debug('The url for servlet server--'+url);
                String myBase64String = EncodingUtil.base64Encode(Blob.valueOf(Label.AEMAuthenticationCredentials));
                request.setHeader('Authorization', 'Basic '+ myBase64String);
                request.setEndpoint(url);
                HttpResponse response = http.send(request);
                System.debug(response.getStatusCode()+':'+response.getBody());
                if (response <> null && response.getStatusCode() == 200 && response.getBody()!=null) {
                    blobResponse = response.getBodyAsBlob();
                    strConvertedBlob = EncodingUtil.base64Encode(blobResponse);
                    system.debug('The stringResponse from File'+strConvertedBlob);
                    noOfRetryAttempts = 0;
                }else {
                    noOfRetryAttempts++;
                    getFileString();
                }
            } catch (exception e){
                noOfRetryAttempts++;
                getFileString();
            }
        }else{
            strConvertedBlob = 'File does not exist.';
        }
        System.debug('total callout used:'+Limits.getCallouts());
    }
}