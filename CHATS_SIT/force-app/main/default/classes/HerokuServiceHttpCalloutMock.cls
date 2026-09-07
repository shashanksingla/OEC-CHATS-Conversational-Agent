@isTest
global class HerokuServiceHttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().contains('AuthEncumbr/UpdateRecord')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('AuthEncumbr/CreateRecord')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('CaseCopay/CreateRecord')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('CaseCopay/UpdateRecord')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('parentfee/update')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('AuthStatus/CreateRecord')){
            response.setBody('[{"success":"Success","errorMessage":"null","cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('AuthStatus/UpdateRecord')){
            response.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('farates/fetch')){
            response.setBody('[{"name": "1121","cde_Age_Group": "1","cde_Care_Unit": "2","amt_Cty": "0.00","amt_Fa": "0.00","amt_Provr": "0.00","rate_Schedule": "1","cde_Rate_Type": "1","idn_Fiscal_Sch": "1","idn_Fiscal_Rate": "1","lastmodifiedbyid": "test","lastmodifieddate": "2018-10-10 10:10:10.0","createdbyid": "test","createddate": "2018-10-10 10:10:10.0","errorMessage": null, "dte_Begin_Effv":"2018-08-01", "dte_End_Effv":"2018-12-10", "dte_Begin_Agrmt":"2018-08-01","dte_End_Agrmt":"2021-08-09"},{"name": "1231","cde_Age_Group": "2","cde_Care_Unit": "3","amt_Cty": "0.00","amt_Fa": "0.00","amt_Provr": "0.00","rate_Schedule": "1","cde_Rate_Type": "1","idn_Fiscal_Sch": "1","idn_Fiscal_Rate": "2","lastmodifiedbyid": "test2","lastmodifieddate": "2018-10-10 10:10:10.0","createdbyid": "test2","createddate": "2018-10-10 10:10:10.0","errorMessage": null ,"dte_Begin_Effv":"2018-08-01", "dte_End_Effv":"2018-12-10", "dte_Begin_Agrmt":"2018-08-01","dte_End_Agrmt":"2021-08-09"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('farates/create')){
            response.setBody('[{"id": "1121","isSucess": true,"errorMessage": null},{"id": "1231","isSucess": true,"errorMessage": null,"name":"1121"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('farates/delete')){
            response.setBody('[{"id": "a1Xm00000026dIPEAY","isSucess": true,"errorMessage": null}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('CaseReview/GetSubsidyAmount')){
            response.setBody('[{"caseReviewSubsidyDetail":[{"authId":"111111","clientId":"222222222","providerId":"33333333","amountPaid":"100","existingAdj":"Y","subPaymentdetailsId":"44444444"}],"errorMessage":null,"success":"Success"}]');  
            response.setStatusCode(200);
        } else if(request.getEndpoint().contains('AuthEncumbr/BulkTransfer')){
            response.setBody('{"a0s2M00000cvEVFQA2":[{"idn_Encmbr_Auth":"271442589","cde_Level_Care":"8","cde_Status_Encmbr":"4","cde_Type_Unit_Care":"1","errorMessage":null,"cnt_Hour_Attnd_Actual":"0.00","cnt_Hour_Care":"0.00","dte_Care":"2022-03-14","idn_Auth":"a0s2M00000cvEVFQA2","nbr_Seq_Hist":"3","createdbyid":"0052M00000AqWC4QAN","createddate":"2022-03-14 10:14:42+00","lastmodifiedbyid":"CFMS006-BATCH","lastmodifieddate":"2022-03-31 08:52:09.01658+00","attendedFlag":null,"ind_0_36_months":null}]}');
            response.setStatusCode(200);
        }else {
            response.setBody('[ {"cde_Level_Care" : "1" ,"cde_Status_Encmbr" : "12" ,"cde_Type_Unit_Care" : "44" ,"cnt_Hour_Attnd_Actual" : "44" ,"cnt_Hour_Care" : "44" ,"idn_Auth" : "444" ,"createdbyid" : "a1fg0000001kMgQAAU" ,"lastmodifiedbyid" : "a1fg0000001kMgQAAU" ,"idn_Encmbr_Auth" : "test","dte_Care" : "test" ,"dte_Care" : "2013-01-01" }]');  
            response.setStatusCode(200);
        }
        system.assert(string.valueof(response).contains('200'),'Should return 200 status code');
        return response;  
    }
}