@isTest
public class CallSearchParentFeeWSMockup implements HttpCalloutMock {
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getEndpoint().contains('searchparentfee/search')){
            if(req.getBody().contains('"effectiveMonth":"abc"')){
                res.setBody('{"errorMessage":"some error"}');
                res.setStatusCode(200);
            }else if(req.getBody().contains('"effectiveMonth":"error"')){
                res.setBody('{"errorMessage":"some error"}');
                res.setStatusCode(201);
            }else if(req.getBody().contains('"effectiveMonth":"parsingerror"')){
                res.setBody('unparseable json');
                res.setStatusCode(200);
            }else if(req.getBody().contains('"effectiveMonth":"02"')){
                res.setBody('{"caseCopayId":"87675654","isDeletable":true,"parentFee":"153.0","effectiveBeginDate":"2018-11-01","effectiveEndDate":"2018-11-30","overrideReason":"OC","fullTimeFee":"200.11","partTimeFee":"100.32","qualityRatingDiscountedPartTimeFee":"80.12","qualityRatingDiscountedFullTimeFee":"180.12"}');
                res.setStatusCode(200);
            }
            else{
                res.setBody('{"caseCopayId":"87675654","isDeletable":true,"parentFee":"153.0","effectiveBeginDate":"2018-11-01","effectiveEndDate":"2018-11-30","overrideReason":"OC","fullTimeFee":"200.11","partTimeFee":"100.32","qualityRatingDiscountedPartTimeFee":"80.12","qualityRatingDiscountedFullTimeFee":"180.12","listGridDataModel":[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthorizationAmount":"0.0","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"},{"childName":"John Doe","authorizationId":"1556","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-28","authorizationEndDate":"2020-08-31","allocatedAuthorizationAmount":"0.0","authCopayId":null,"authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tUOEAY"}]}');
                res.setStatusCode(200);
            }
        }else if(req.getEndpoint().contains('AuthCopay/UpdateRecords')){
            if(req.getBody().contains('"amt_copay_auth":"null"')){
                res.setBody('[{"errMessage":"some error","successInd":"N"}]');
                res.setStatusCode(200);
            }else if(req.getBody().contains('"amt_copay_auth":"123"')){
                res.setStatusCode(201);
            }else{
                res.setBody('[{"successInd":"Y"}]');
                res.setStatusCode(200);
            }
        }else if(req.getEndpoint().contains('AuthCopay/CreateRecords')){
            if(req.getBody().contains('"amt_copay_auth":"null"')){
                res.setBody('[{"errMessage":"some error","successInd":"N"}]');
                res.setStatusCode(200);
            }else if(req.getBody().contains('"amt_copay_auth":"123"')){
                res.setStatusCode(201);
            }else{
                res.setBody('[{"successInd":"Y"}]');
                res.setStatusCode(200);
            }
        }else if(req.getEndpoint().contains('parentfee/deleteCaseParentFee')){
            if(req.getBody().contains('"caseCopayId":999')){
                res.setStatusCode(201);
            }else if(req.getBody().contains('"caseCopayId":123')){
                res.setBody('{"errorMessage":"some error"}');
                res.setStatusCode(200);
            }else{
                res.setBody('[{"errorMessage":"some error"}]');
                res.setStatusCode(200);
            }
        }else{
            //res.setBody('{"errorMessage":"some error"}');
            res.setStatusCode(201);
        }
        System.debug('res:'+res);
        System.debug('req:'+req);
        System.debug('req getBody:'+req.getBody());
        return res;
    }
}