public class ParentFeeFlowIntegrator {
    
    public static Map<String,Object> getCaseParentFeeDetails(String body){
        Map<String,Object> caseParentFeeDetails = new Map<String,Object>();
        Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(body);
        System.debug('data:'+data);
        if(data!=null && !data.isEmpty()){
            if(data.containsKey('errorMessage') && data.get('errorMessage')!=null){
                caseParentFeeDetails.put('errorMessage',(String)data.get('errorMessage'));
            }
            if(data.containsKey('parentFee') && data.get('parentFee')!=null){
                caseParentFeeDetails.put('parentFee',(String)data.get('parentFee'));
            }
            if(data.containsKey('effectiveBeginDate') && data.get('effectiveBeginDate')!=null){
                caseParentFeeDetails.put('effectiveBeginDate',data.get('effectiveBeginDate'));
            }
            if(data.containsKey('effectiveEndDate') && data.get('effectiveEndDate')!=null){
                caseParentFeeDetails.put('effectiveEndDate',data.get('effectiveEndDate'));
            }
            if(data.containsKey('overrideReason') && data.get('overrideReason')!=null){
                caseParentFeeDetails.put('overrideReason',data.get('overrideReason'));
            }
            if(data.containsKey('fullTimeFee') && data.get('fullTimeFee')!=null){
                caseParentFeeDetails.put('ftFee',(String)data.get('fullTimeFee'));
            }
            if(data.containsKey('indQlty') && data.get('indQlty')!=null){
                caseParentFeeDetails.put('indQlty',(String)data.get('indQlty'));
            }
            if(data.containsKey('partTimeFee') && data.get('partTimeFee')!=null){
                caseParentFeeDetails.put('ptFee',(String)data.get('partTimeFee'));
            }
            if(data.containsKey('qualityRatingDiscountedPartTimeFee') && data.get('qualityRatingDiscountedPartTimeFee')!=null){
                caseParentFeeDetails.put('qualityRatingPTFee',(String)data.get('qualityRatingDiscountedPartTimeFee'));
            }
            if(data.containsKey('qualityRatingDiscountedFullTimeFee') && data.get('qualityRatingDiscountedFullTimeFee')!=null){
                caseParentFeeDetails.put('qualityRatingFTFee',(String)data.get('qualityRatingDiscountedFullTimeFee'));
            }
            if(data.containsKey('caseCopayId') && data.get('caseCopayId')!=null){
                caseParentFeeDetails.put('caseCopayId',(String)data.get('caseCopayId'));
            }
            if(data.containsKey('isDeletable') && data.get('isDeletable')!=null){
                caseParentFeeDetails.put('isDeletable',(Boolean)data.get('isDeletable'));
            }
        }
        return caseParentFeeDetails;
    }
    
    public static List<ParentFeeAllocationWrapper> getCaseParentFeeAllocations(String body){
        List<ParentFeeAllocationWrapper> caseParentFeeAllocations = new List<ParentFeeAllocationWrapper>();
        
        Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(body);
        System.debug('data:'+data);
        if(data!=null && !data.isEmpty() && data.containskey('listGridDataModel') && data.get('listGridDataModel')!=null){
            List<Object> listGridDataModel = (List<Object>)data.get('listGridDataModel');
            for(Object parentFeeAllocationDataObj:listGridDataModel){
                Map<String,Object> parentFeeAllocationData = (Map<String,Object>)parentFeeAllocationDataObj;
                ParentFeeAllocationWrapper caseParentFeeAllocation = new ParentFeeAllocationWrapper();
                if(parentFeeAllocationData.containskey('childName') && parentFeeAllocationData.get('childName')!=null){
                    caseParentFeeAllocation.childName = (String)parentFeeAllocationData.get('childName');
                }
                if(parentFeeAllocationData.containskey('authorizationId') && parentFeeAllocationData.get('authorizationId')!=null){
                    caseParentFeeAllocation.authName = (String)parentFeeAllocationData.get('authorizationId');
                }
                if(parentFeeAllocationData.containskey('dateofBirth') && parentFeeAllocationData.get('dateofBirth')!=null){
                    caseParentFeeAllocation.childDOB = convertDateJSONToDate((String)parentFeeAllocationData.get('dateofBirth'));
                }
                if(parentFeeAllocationData.containskey('providerId') && parentFeeAllocationData.get('providerId')!=null){
                    caseParentFeeAllocation.providerExternalId = (String)parentFeeAllocationData.get('providerId');
                }
                if(parentFeeAllocationData.containskey('providerName') && parentFeeAllocationData.get('providerName')!=null){
                    caseParentFeeAllocation.providerName = (String)parentFeeAllocationData.get('providerName');
                }
                if(parentFeeAllocationData.containskey('authorizationBeginDate') && parentFeeAllocationData.get('authorizationBeginDate')!=null){
                    caseParentFeeAllocation.authBeginDate = convertDateJSONToDate((String)parentFeeAllocationData.get('authorizationBeginDate'));
                }
                if(parentFeeAllocationData.containskey('authorizationEndDate') && parentFeeAllocationData.get('authorizationEndDate')!=null){
                    caseParentFeeAllocation.authEndDate = convertDateJSONToDate((String)parentFeeAllocationData.get('authorizationEndDate'));
                }
                if(parentFeeAllocationData.containskey('allocatedAuthorizationAmount') && parentFeeAllocationData.get('allocatedAuthorizationAmount')!=null){
                    caseParentFeeAllocation.allocatedAuthAmount = Integer.valueOf(Decimal.valueOf((String)parentFeeAllocationData.get('allocatedAuthorizationAmount')).round(System.RoundingMode.DOWN));
                    caseParentFeeAllocation.allocatedAuthAmountDecimal = Decimal.valueOf((String)parentFeeAllocationData.get('allocatedAuthorizationAmount'));
                }
                if(parentFeeAllocationData.containskey('authCopayId') && parentFeeAllocationData.get('authCopayId')!=null){
                    caseParentFeeAllocation.authCopayExternalId = (String)parentFeeAllocationData.get('authCopayId');
                }
                if(parentFeeAllocationData.containskey('authExternalId') && parentFeeAllocationData.get('authExternalId')!=null){
                    caseParentFeeAllocation.authExternalId = (String)parentFeeAllocationData.get('authExternalId');
                }
                if(parentFeeAllocationData.containskey('editable') && parentFeeAllocationData.get('editable')!=null){
                    caseParentFeeAllocation.isEditable = (Boolean)parentFeeAllocationData.get('editable');
                }
                if(parentFeeAllocationData.containskey('authCopayBeginDate') && parentFeeAllocationData.get('authCopayBeginDate')!=null){
                    caseParentFeeAllocation.authCopayEffecBeginDate = (convertDateJSONToDate((String)parentFeeAllocationData.get('authCopayBeginDate')));
                }
                if(parentFeeAllocationData.containskey('authCopayEndDate') && parentFeeAllocationData.get('authCopayEndDate')!=null){
                    caseParentFeeAllocation.authCopayEndDate = convertDateJSONToDate((String)parentFeeAllocationData.get('authCopayEndDate'));
                }
                 if(parentFeeAllocationData.containskey('authorizedDays') && parentFeeAllocationData.get('authorizedDays')!=null){
                    caseParentFeeAllocation.authorizedDays = Integer.valueOf(Decimal.valueOf((Integer)parentFeeAllocationData.get('authorizedDays')).round(System.RoundingMode.DOWN));
                }
                if(parentFeeAllocationData.containskey('childExternalId') && parentFeeAllocationData.get('childExternalId')!=null){
                    caseParentFeeAllocation.childExternalId = (String)parentFeeAllocationData.get('childExternalId');
                }
                if(parentFeeAllocationData.containskey('majorityCareUnit') && parentFeeAllocationData.get('majorityCareUnit')!=null){
                    caseParentFeeAllocation.majorityCareUnit = (String)parentFeeAllocationData.get('majorityCareUnit');
                }
                
                caseParentFeeAllocations.add(caseParentFeeAllocation);
            }
        }        
        return caseParentFeeAllocations;
    }
    
    public static String getBodyForUpdateParentFeeWS(Date effectiveDate,List<ParentFeeAllocationWrapper> caseParentFeeAllocationsToBeEndDated){
        String bodyText = '[';
        for(ParentFeeAllocationWrapper wrapRec: caseParentFeeAllocationsToBeEndDated){
            bodyText+='{';
            bodyText+='"idn_copay_auth":"'+wrapRec.authCopayExternalId+'",';
            bodyText+='"dte_end_effv":"'+effectiveDate.addDays(-1)+'",';
            bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"lastmodifieddate":"'+system.now()+'"';
            bodyText+='},';
        }
        bodyText = bodyText.substring(0, bodyText.length()-1);
        bodyText+=']';
        system.debug('########bodyText: '+bodyText);
        return bodyText;
    }
    
    public static String getBodyForAuthAmountUpdateParentFeeWS(Date effectiveDate,List<ParentFeeAllocationWrapper> caseParentFeeAllocations){
        String bodyText = '[';
        for(ParentFeeAllocationWrapper wrapRec: caseParentFeeAllocations){
            bodyText+='{';
            if(String.isNotBlank(wrapRec.authCopayExternalId)){
                bodyText+='"idn_copay_auth":"'+wrapRec.authCopayExternalId+'",';
                bodyText+='"dte_begin_effv":"'+wrapRec.authCopayEffecBeginDate+'",';
            }else{
                bodyText+='"nbr_seq_hist":"2",';
                 bodyText+='"isCreate":"Y",';
                 bodyText+='"dte_begin_effv":"'+effectiveDate+'",';
            }
           // bodyText+='"idn_copay_auth":"'+wrapRec.authCopayExternalId+'",';
            bodyText+='"amt_copay_auth":"'+wrapRec.allocatedAuthAmount+'",';
            
            bodyText+='"idn_auth":"'+wrapRec.authExternalId+'",';
            bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"lastmodifieddate":"'+system.now()+'"';
            bodyText+='},';
        }
        bodyText = bodyText.substring(0, bodyText.length()-1);
        bodyText+=']';
        System.debug('bodyText:'+bodyText);
        return bodyText;
    }
    
    public static String getBodyForCreateParentFeeWS(Date effectiveDate, List<ParentFeeAllocationWrapper> caseParentFeeAllocationsToBeCreated, String viewFlowIndicator , String currentMonthIndicator ,String month, String year ){
        String bodyText = '[';
        for(ParentFeeAllocationWrapper wrapRec: caseParentFeeAllocationsToBeCreated){
            bodyText+='{';
            bodyText+='"amt_copay_auth":"'+wrapRec.allocatedAuthAmount+'",';
            bodyText+='"dte_begin_effv":"'+effectiveDate+'",';
            bodyText+='"idn_auth":"'+wrapRec.authExternalId+'",';
            bodyText+='"createdbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"createddate":"'+system.now()+'",';
            bodyText+='"nbr_seq_hist":"2",';
            bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"lastmodifieddate":"'+system.now()+'",';
            if(wrapRec.authEndDate != null){
                String authDate = String.valueOf(wrapRec.authEndDate).split(' ')[0];
                bodyText+='"authEndDate":"'+authDate+'",';
                }
            bodyText+='"viewFlowIndicator":"'+viewFlowIndicator+'",';
            bodyText+='"currentMonthIndicator":"'+currentMonthIndicator+'",';
            bodyText+='"month":"'+month+'",';
            if(viewFlowIndicator == 'Y'){
                if(String.isNotEmpty(wrapRec.authCopayExternalId)){
                bodyText+='"idn_copay_auth":"'+wrapRec.authCopayExternalId+'",';
                }
                if(wrapRec.authCopayEndDate != null){
                    bodyText+='"dte_end_effv":"'+wrapRec.authCopayEndDate+'",';
                }
                
            }
             bodyText+='"year":"'+year+'"';
            bodyText+='},';
        }
        bodyText = bodyText.substring(0, bodyText.length()-1);
        bodyText+=']';
        return bodyText;
    }
    
    public static Date convertDateJSONToDate(String dateJSON){
        Date convertedDate;
        try{
            if(String.isNotEmpty(dateJSON)){
                String[] dateComponents = dateJSON.split('-');
                convertedDate = Date.newInstance(Integer.valueOf(dateComponents[0]), Integer.valueOf(dateComponents[1]), Integer.valueOf(dateComponents[2]));
            }
        }catch(Exception ex){
            System.debug(ex.getLineNumber()+':'+ex.getMessage());
        }
        return convertedDate;
    }
}