public class ParentFeeFlowWSCaller {
    public static HttpResponse callSearchParentFeeWS(String caseExternalId,String month, Integer year, String effectiveBeginDate, String caseParentFeeAmt){
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(Label.searchParentFee);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            if(month.length()==1){
                month = '0'+month;
            }
            String body;
            if(String.isNotBlank(effectiveBeginDate)){
                if(caseParentFeeAmt != null){
                    body = '{"caseId":"'+caseExternalId+'","effectiveMonth":"'+month+'","caseParentFeeAmt":"'+caseParentFeeAmt+'","effectiveYear":"'+year+'","effectiveBeginDate":"'+effectiveBeginDate+'"}';
                }else{
                    body = '{"caseId":"'+caseExternalId+'","effectiveMonth":"'+month+'","effectiveYear":"'+year+'","effectiveBeginDate":"'+effectiveBeginDate+'"}';
                }
            }else{
                if(caseParentFeeAmt != null){
                    body = '{"caseId":"'+caseExternalId+'","effectiveMonth":"'+month+'","caseParentFeeAmt":"'+caseParentFeeAmt+'","effectiveYear":"'+year+'"}';
                }else{
                    body = '{"caseId":"'+caseExternalId+'","effectiveMonth":"'+month+'","effectiveYear":"'+year+'"}';
                }
            }
            system.debug('body---'+body);
            req.setBody(body);
            HttpResponse response = http.send(req);
            return response;
        } catch(Exception ex) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
    }
    
    public static HttpResponse callUpdateParentFeeWS(String body){
        try {
            System.debug('Inside callUpdateParentFeeWS:'+body);
            String method = 'POST';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Label.AuthCopayUpdate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setBody(body);
            system.debug('*********request: '+request);
            HttpResponse response = http.send(request);
            return response;
        } catch(Exception ex) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
    }
    
    public static HttpResponse callDeleteParentFeeWS(String body){
        try {
            System.debug('Inside callDeleteParentFeeWS:'+body);
            String method = 'POST';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Label.DeleteParentFee);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setBody(body);
            system.debug('*********request: '+request);
            HttpResponse response = http.send(request);
            return response;
        } catch(Exception ex) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
    }
    
    public static HttpResponse callCreateParentFeeWS(String body){
        System.debug('Inside callCreateParentFeeWS:'+body);
        try {
            String method = 'POST';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Label.AuthCopayCreate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setBody(body);
            system.debug('*********request: '+request);
            HttpResponse response = http.send(request);
            return response;
        } catch(Exception ex) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody(ex.getMessage());
            return response;
        }
    }
    
}